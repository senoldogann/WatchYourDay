import Foundation

// MARK: - AI Provider Protocol
protocol AIProvider {
    func generateSummary(context: String) async throws -> String
    var modelName: String { get }
}

// MARK: - Ollama Provider (Local)
class OllamaProvider: AIProvider {
    let baseURL: URL
    let modelName: String
    
    init(baseURL: String = "http://localhost:11434", modelName: String = "llama3") {
        self.baseURL = URL(string: "\(baseURL)/api/generate")!
        self.modelName = modelName
    }
    
    func generateSummary(context: String) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Longer timeout for local models
        
        // Context optimizations: Limit length to avoid slow processing
        let prompt = """
        You are a helpful productivity assistant. Analyze the following screen time data and provide a concise, human-readable summary of what the user worked on today.
        Highlight key activities and duration. Be encouraging but professional.
        
        Data:
        \(context)
        
        Summary:
        """
        
        let payload: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        WDLogger.debug("AIService: Calling \(baseURL) with model \(modelName)", category: .ai)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            WDLogger.error("AIService: HTTP \(httpResponse.statusCode) - \(errorMessage)", category: .ai)
            throw URLError(.badServerResponse)
        }
        
        struct OllamaResponse: Decodable {
            let response: String
        }
        
        let result = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return result.response
    }
}

// MARK: - AI Service Manager
actor AIService {
    static let shared = AIService()
    
    private init() {}
    
    /// Creates a provider based on current UserDefaults settings
    private func createProviderFromSettings() -> AIProvider {
        let defaults = UserDefaults.standard
        
        let isLocal = defaults.string(forKey: "aiProvider") ?? "Local (Ollama)" == "Local (Ollama)"
        let baseURL = isLocal 
            ? (defaults.string(forKey: "localBaseURL") ?? "http://localhost:11434")
            : (defaults.string(forKey: "cloudBaseURL") ?? "http://localhost:11434")
        let modelName = isLocal
            ? (defaults.string(forKey: "localModelName") ?? "llama3")
            : (defaults.string(forKey: "cloudModelName") ?? "gpt-4")
        
        WDLogger.info("AIService: Using \(isLocal ? "Local" : "Cloud") provider - \(modelName) @ \(baseURL)", category: .ai)
        
        return OllamaProvider(baseURL: baseURL, modelName: modelName)
    }
    
    func generateDailyReport(for snapshots: [Snapshot]) async throws -> String {
        guard !snapshots.isEmpty else { return "No data available for analysis." }
        
        // Get fresh provider from settings each time
        let provider = createProviderFromSettings()
        
        // 1. Aggregate Data
        var appCounts: [String: Int] = [:]
        var windowTitles: Set<String> = []
        
        for s in snapshots {
            appCounts[s.appName, default: 0] += 1
            if !s.windowTitle.isEmpty {
                windowTitles.insert("\(s.appName): \(s.windowTitle)")
            }
        }
        
        // Sort by usage
        let topApps = appCounts.sorted { $0.value > $1.value }.prefix(5)
        
        // 2. Build Context String
        var context = "Total Snapshots: \(snapshots.count)\n"
        context += "Top Applications:\n"
        for (app, count) in topApps {
            context += "- \(app): \(count) snapshots\n"
        }
        
        context += "\nKey Tasks (Window Titles):\n"
        for title in windowTitles.prefix(10) {
            context += "- \(title)\n"
        }
        
        // 3. Call Provider
        return try await provider.generateSummary(context: context)
    }
}
