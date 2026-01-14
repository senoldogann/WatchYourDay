import Foundation
import NaturalLanguage

/// Provides on-device text embeddings using Apple's NaturalLanguage framework
actor EmbeddingService {
    static let shared = EmbeddingService()
    
    private var embeddingModel: NLEmbedding?
    
    private init() {
        // Initialize the model for English.
        // Note: NLEmbedding supports multiple languages, but .english is the most robust for general purpose.
        // Ideally, we could check NLEmbedding.embedding(for: .turkish) if supported or fallback.
        // Currently .english vector space is often used for multilingual if the model supports it, 
        // but explicit language support is better.
        
        // Try getting embedding for the current system language, fallback to English.
        if let lang = Locale.current.language.languageCode?.identifier,
           let model = NLEmbedding.wordEmbedding(for: NLLanguage(lang)) {
             self.embeddingModel = model
        } else {
             self.embeddingModel = NLEmbedding.wordEmbedding(for: .english)
        }
    }
    
    /// Generates a vector embedding for the given text.
    /// Uses sentence embedding if available (better for context), otherwise falls back to word embedding aggregation.
    func embed(text: String) async throws -> [Float] {
        guard let model = NLEmbedding.sentenceEmbedding(for: .english) else {
            throw EmbeddingError.modelUnavailable
        }
        
        // NLEmbedding returns [Double], we typically use [Float] for storage/performance
        guard let vector = model.vector(for: text) else {
            throw EmbeddingError.vectorGenerationFailed
        }
        
        return vector.map { Float($0) }
    }
}

enum EmbeddingError: Error {
    case modelUnavailable
    case vectorGenerationFailed
}
