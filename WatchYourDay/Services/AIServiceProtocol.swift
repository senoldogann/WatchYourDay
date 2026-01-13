import Foundation

/// Protocol defining the interface for AI services (Local or Cloud)
/// Allows swapping implementations (Ollama, OpenAI, Mock) easily.
protocol AIServiceProtocol: Actor {
    /// Generate a summary for the given text segments
    func summarize(segments: [String]) async throws -> String
    
    /// Classify the activity based on context
    func classifyActivity(text: String, appName: String) async throws -> String
}
