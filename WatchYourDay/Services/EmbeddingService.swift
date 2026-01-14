import Foundation
import NaturalLanguage

/// Provides on-device text embeddings using Apple's NaturalLanguage framework
actor EmbeddingService {
    static let shared = EmbeddingService()
    
    private var embeddingModel: NLEmbedding?
    
    private init() {
        // Initialize the model for English Sentence Embeddings (Best for RAG)
        self.embeddingModel = NLEmbedding.sentenceEmbedding(for: .english)
    }
    
    /// Generates a vector embedding for the given text.
    func embed(text: String) async throws -> [Float] {
        guard let model = self.embeddingModel else {
            // Attempt valid fallback if init failed (unlikely for built-in)
            if let fallback = NLEmbedding.sentenceEmbedding(for: .english) {
                print("EmbeddingService: Using fallback model")
                 // We don't save to self.embeddingModel because we are in an actor (immutable state safety check might be needed if var is not isolated properly, but actor var is safe. However, simpler to just use local if self is nil)
                 guard let vector = fallback.vector(for: text) else {
                     throw EmbeddingError.vectorGenerationFailed
                 }
                 return vector.map { Float($0) }
            }
            throw EmbeddingError.modelUnavailable
        }
        
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
