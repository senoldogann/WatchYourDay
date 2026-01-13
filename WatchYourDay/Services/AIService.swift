import Foundation

// MARK: - AI Provider Protocol
protocol AIProvider {
    func generateSummary(context: String) async throws -> String
    var modelName: String { get }
}

// MARK: - Ollama Provider (Local)
class OllamaProvider: AIProvider {
    let baseURL = URL(string: "http://localhost:11434/api/generate")!
    let modelName: String
    
    init(modelName: String = "llama3") {
        self.modelName = modelName
    }
    
    func generateSummary(context: String) async throws -> String {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Context optimizations: Limit length to avoid slow processing
        // Llama3 has 8k context, but let's be safe and concise.
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
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
    
    private var provider: AIProvider
    
    private init() {
        // Default to Ollama for privacy
        self.provider = OllamaProvider(modelName: "llama3")
    }
    
    func setProvider(_ newProvider: AIProvider) {
        self.provider = newProvider
    }
    
    func generateDailyReport(for snapshots: [Snapshot]) async throws -> String {
        guard !snapshots.isEmpty else { return "No data available for analysis." }
        
        // 1. Aggregate Data
        // Map AppName -> Count (representing time). Assuming 1 snapshot = X seconds interval.
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
        // Sample random window titles if too many, to fit context
        for title in windowTitles.prefix(10) {
            context += "- \(title)\n"
        }
        
        // 3. Call Provider
        return try await provider.generateSummary(context: context)
    }
}
