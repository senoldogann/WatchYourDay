import Foundation
import SwiftUI

/// Unified AI Service supporting both local (Ollama) and cloud providers
/// Thread-safe actor with proper error handling
actor OllamaService: AIServiceProtocol {
    
    // MARK: - Configuration (Read from UserDefaults)
    
    private var isCloud: Bool {
        let provider = UserDefaults.standard.string(forKey: "aiProvider") ?? "Local (Ollama)"
        return provider == "Cloud (OpenAI, Ollama)"
    }
    
    private var baseURLString: String {
        if isCloud {
            return UserDefaults.standard.string(forKey: "cloudBaseURL") ?? "https://api.openai.com"
        } else {
            return UserDefaults.standard.string(forKey: "localBaseURL") ?? "http://localhost:11434"
        }
    }
    
    private var modelName: String {
        if isCloud {
            return UserDefaults.standard.string(forKey: "cloudModelName") ?? "gpt-4o-mini"
        } else {
            return UserDefaults.standard.string(forKey: "localModelName") ?? "llama3"
        }
    }
    
    private let requestTimeout: TimeInterval = 30
    
    init() {}
    
    // MARK: - Public API
    
    /// Generate activity summary from screen content
    func summarize(segments: [String]) async throws -> String {
        let joinedText = segments.joined(separator: "\n---\n")
        let prompt = """
        You are an intelligent activity tracker. Below are text segments extracted from a user's screen over a few minutes.
        Summarize what the user is working on in 1 concise sentence.
        
        Screen Content:
        \(joinedText)
        
        Summary:
        """
        
        return try await generate(prompt: prompt)
    }
    
    /// Classify activity category
    func classifyActivity(text: String, appName: String) async throws -> String {
        let prompt = """
        Classify the user's activity based on the app name and screen text.
        Return ONLY one of these categories: [Coding, Browsing, Meeting, Design, Chat, Idle, Unknown].
        
        App: \(appName)
        Context: \(text.prefix(500))
        
        Category:
        """
        return try await generate(prompt: prompt)
    }
    
    // MARK: - Private Methods
    
    /// Generic generation method
    /// Generic generation method
    func generate(prompt: String) async throws -> String {
        let endpoint = isCloud ? "/v1/chat/completions" : "/api/generate"
        guard let url = URL(string: "\(baseURLString)\(endpoint)") else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = requestTimeout
        
        // Auth Injection for Cloud mode
        if isCloud {
            let apiKey = KeychainManager.loadString(key: "cloudAPIKey")
            if let key = apiKey {
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            } else {
                WDLogger.error("[AI] Cloud mode active but no API key found", category: .ai)
            }
        }
        
        let body: [String: Any]
        if isCloud {
            // OpenAI Format
            body = [
                "model": modelName,
                "messages": [
                    ["role": "user", "content": prompt]
                ],
                "max_tokens": 500 // Reasonable limit for summary
            ]
        } else {
            // Ollama Format
            body = [
                "model": modelName,
                "prompt": prompt,
                "stream": false
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            WDLogger.error("[AI] AI request failed: HTTP \(httpResponse.statusCode)", category: .ai)
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                 WDLogger.error("[AI] Error details: \(errorJson)", category: .ai)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }
        
        if isCloud {
            let result = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            return result.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } else {
            let result = try JSONDecoder().decode(OllamaResponse.self, from: data)
            return result.response.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

// MARK: - Response Models

private struct OllamaResponse: Decodable, Sendable {
    let response: String
}

private struct OpenAIChatResponse: Decodable, Sendable {
    let choices: [Choice]
    
    struct Choice: Decodable, Sendable {
        let message: Message
    }
    
    struct Message: Decodable, Sendable {
        let content: String
    }
}

// MARK: - Error Types

enum AIServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serviceUnavailable
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid AI service URL"
        case .invalidResponse: return "Invalid response from AI service"
        case .httpError(let code): return "AI service error: HTTP \(code)"
        case .serviceUnavailable: return "AI service is unavailable"
        case .decodingError: return "Failed to decode AI response"
        }
    }
}
