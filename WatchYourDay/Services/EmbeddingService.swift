//
//  EmbeddingService.swift
//  WatchYourDay
//
//  Phase 2: RAG - Embedding generation using Ollama
//

import Foundation

/// Generates embeddings using Ollama's embedding API
actor EmbeddingService {
    static let shared = EmbeddingService()
    
    private init() {}
    
    /// Embedding model (nomic-embed-text has 768 dimensions, fast and accurate)
    private var modelName: String {
        UserDefaults.standard.string(forKey: "embeddingModelName") ?? "nomic-embed-text"
    }
    
    private var baseURL: String {
        UserDefaults.standard.string(forKey: "localBaseURL") ?? "http://localhost:11434"
    }
    
    // MARK: - Embed Single Text
    func embed(text: String) async throws -> [Float] {
        let url = URL(string: "\(baseURL)/api/embeddings")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let payload: [String: Any] = [
            "model": modelName,
            "prompt": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        WDLogger.debug("EmbeddingService: Embedding text (\(text.prefix(50))...)", category: .ai)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbeddingError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            WDLogger.error("EmbeddingService: HTTP \(httpResponse.statusCode) - \(errorMessage)", category: .ai)
            throw EmbeddingError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        struct EmbeddingResponse: Decodable {
            let embedding: [Float]
        }
        
        let result = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        WDLogger.debug("EmbeddingService: Got embedding with \(result.embedding.count) dimensions", category: .ai)
        
        return result.embedding
    }
    
    // MARK: - Embed Batch
    func embedBatch(texts: [String]) async throws -> [[Float]] {
        // Ollama doesn't support batch embedding natively, so we do it sequentially
        // with a small delay to avoid overwhelming the API
        var results: [[Float]] = []
        
        for (index, text) in texts.enumerated() {
            if index > 0 {
                // Small delay between requests
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            
            let embedding = try await embed(text: text)
            results.append(embedding)
        }
        
        return results
    }
    
    // MARK: - Check Model Availability
    func isModelAvailable() async -> Bool {
        do {
            // Try a simple embedding to check if model is available
            let _ = try await embed(text: "test")
            return true
        } catch {
            WDLogger.error("EmbeddingService: Model not available - \(error.localizedDescription)", category: .ai)
            return false
        }
    }
}

// MARK: - Errors
enum EmbeddingError: Error, LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from embedding service"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .modelNotFound:
            return "Embedding model not found. Run: ollama pull nomic-embed-text"
        }
    }
}
