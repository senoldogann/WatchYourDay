import Foundation
import SwiftUI
import SwiftData

@MainActor
class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var embeddingCount: Int = 0
    
    private init() {
        addWelcomeMessage()
        Task { await loadEmbeddingCount() }
    }
    
    func sendMessage(_ text: String, modelContext: ModelContext) {
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        
        let query = text
        
        Task {
            do {
                // RAG Generation
                let response = try await RAGService.shared.query(query, modelContext: modelContext)
                
                await MainActor.run {
                    let assistantMessage = ChatMessage(role: .assistant, content: response)
                    self.messages.append(assistantMessage)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
                    self.messages.append(errorMessage)
                    self.isLoading = false
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let welcome = ChatMessage(
            role: .assistant,
            content: "👋 Hi! I can help you understand your activity history. Try asking:\n\n• \"What did I work on today?\"\n• \"How much time did I spend in Xcode?\"\n• \"What was I doing this morning?\""
        )
        messages.append(welcome)
    }
    
    func loadEmbeddingCount() async {
        embeddingCount = await VectorStore.shared.getEmbeddingCount()
    }
}

// MARK: - Message Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}

enum MessageRole {
    case user
    case assistant
}
