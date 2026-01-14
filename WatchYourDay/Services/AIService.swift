import Foundation

// MARK: - AI Provider Protocol
protocol AIProvider {
    func generateResponse(prompt: String) async throws -> String
    var modelName: String { get }
}

// MARK: - Ollama Provider (Local)
struct OllamaProvider: AIProvider {
    let baseURL: URL
    let modelName: String
    
    init(baseURLString: String, modelName: String) {
        // Ensure clean URL
        let cleanURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        // If user provided just base info "http://host:11434", append "/api/generate"
        // But if they provided full path, use it? Standardize on config being base.
        let urlString = cleanURL.hasSuffix("/") ? cleanURL + "api/generate" : cleanURL + "/api/generate"
        self.baseURL = URL(string: urlString)!
        self.modelName = modelName
    }
    
    func generateResponse(prompt: String) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // Generous timeout for local inference
        
        let payload: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown upstream error"
            WDLogger.error("Ollama Error: \(httpResponse.statusCode) - \(errorMessage)", category: .ai)
            throw URLError(.badServerResponse)
        }
        
        struct OllamaResponse: Decodable {
            let response: String
        }
        
        let result = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return result.response
    }
}

// MARK: - OpenAI Provider (Cloud)
struct OpenAIProvider: AIProvider {
    let baseURL: URL
    let modelName: String
    let apiKey: String
    
    init(baseURLString: String, modelName: String, apiKey: String) {
        let cleanURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        // Standardize on /v1/chat/completions for OpenAI compatible
        let urlString = cleanURL.hasSuffix("/") ? cleanURL + "v1/chat/completions" : cleanURL + "/v1/chat/completions"
        self.baseURL = URL(string: urlString)!
        self.modelName = modelName
        self.apiKey = apiKey
    }
    
    func generateResponse(prompt: String) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60
        
        let payload: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000 // Reasonable limit
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown upstream error"
            WDLogger.error("OpenAI Error: \(httpResponse.statusCode) - \(errorMessage)", category: .ai)
            throw URLError(.badServerResponse)
        }
        
        // Parse OpenAI response format
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
}

// MARK: - AI Service Manager
actor AIService {
    static let shared = AIService()
    
    private init() {}
    
    /// Creates a provider based on current UserDefaults settings
    private func createProviderFromSettings() async -> AIProvider {
        let defaults = UserDefaults.standard
        let providerType = defaults.string(forKey: "aiProvider") ?? "Local (Ollama)"
        let isLocal = providerType == "Local (Ollama)"
        
        if isLocal {
            let baseURL = defaults.string(forKey: "localBaseURL") ?? "http://localhost:11434"
            let modelName = defaults.string(forKey: "localModelName") ?? "llama3"
            return OllamaProvider(baseURLString: baseURL, modelName: modelName)
        } else {
            let baseURL = defaults.string(forKey: "cloudBaseURL") ?? "https://api.openai.com"
            let modelName = defaults.string(forKey: "cloudModelName") ?? "gpt-4o-mini"
            let apiKey = KeychainManager.loadString(key: "cloudAPIKey") ?? ""
            return OpenAIProvider(baseURLString: baseURL, modelName: modelName, apiKey: apiKey)
        }
    }
    
    /// Generic generation method (Used by RAG and Reporting)
    func generateResponse(prompt: String) async throws -> String {
        let provider = await createProviderFromSettings()
        
        // PRIVACY GUARD: Scrub prompt if using Cloud Provider
        // Local provider is safer, but scrubbing everywhere is the Architecture Standard for "Privacy-First"
        let scrubbedPrompt = PrivacyGuard.shared.scrub(prompt)
        
        if scrubbedPrompt != prompt {
            WDLogger.info("PrivacyGuard: Sensitive data redacted from AI prompt.", category: .ai)
        }
        
        return try await provider.generateResponse(prompt: scrubbedPrompt)
    }
    
    /// Specialized reporting method (Wrapper around generic generation with specific prompt logic)
    func generateDailyReport(for snapshots: [Snapshot]) async throws -> String {
        guard !snapshots.isEmpty else { return "No data available for analysis." }
        
        // 1. Aggregate Data
        var appCounts: [String: Int] = [:]
        var windowTitles: Set<String> = []
        
        for s in snapshots {
            appCounts[s.appName, default: 0] += 1
            if !s.windowTitle.isEmpty {
                windowTitles.insert("\(s.appName): \(s.windowTitle)")
            }
        }
        
        let topApps = appCounts.sorted { $0.value > $1.value }.prefix(5)
        
        // 2. Build Context String for Prompt
        var context = "Total Snapshots: \(snapshots.count)\n"
        context += "Top Applications:\n"
        for (app, count) in topApps {
            context += "- \(app): \(count) snapshots\n"
        }
        
        context += "\nKey Tasks (Window Titles):\n"
        for title in windowTitles.prefix(10) {
            context += "- \(title)\n"
        }
        
        // 3. Construct Prompt
        let prompt = """
        You are a helpful productivity assistant. Analyze the following screen time data and provide a concise, human-readable summary of what the user worked on today.
        Highlight key activities and duration. Be encouraging but professional.
        
        Data:
        \(context)
        
        Summary:
        """
        
        // 4. Delegate to provider
        return try await generateResponse(prompt: prompt)
    }
}
