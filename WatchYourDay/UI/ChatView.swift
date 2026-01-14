//
//  ChatView.swift
//  WatchYourDay
//
//  Phase 2: RAG - Chat with your history
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var embeddingCount: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            ModernMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            LoadingBubble()
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input
            inputSection
        }
        .background(Color.claudeBackground)
        .onAppear {
            Task { await loadEmbeddingCount() }
            addWelcomeMessage()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundStyle(Color.claudeAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Chat with History")
                    .font(.headline)
                    .foregroundStyle(Color.claudeTextPrimary)
                
                Text("\(embeddingCount) memories indexed")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            
            Spacer()
            
            Button(action: clearChat) {
                Image(systemName: "trash")
                    .foregroundStyle(Color.gray)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Input
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Ask about your activity...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color.claudeSurface)
                .cornerRadius(8)
                .onSubmit { sendMessage() }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(inputText.isEmpty ? Color.gray : Color.claudeAccent)
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding()
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: inputText)
        messages.append(userMessage)
        
        let query = inputText
        inputText = ""
        isLoading = true
        
        Task {
            do {
                let response = try await RAGService.shared.query(query, modelContext: modelContext)
                // Note: True streaming would be better, but simulated typewriter is okay for now.
                let assistantMessage = ChatMessage(role: .assistant, content: response)
                
                await MainActor.run {
                    messages.append(assistantMessage)
                    isLoading = false
                }
            } catch {
                let errorMessage = ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
                await MainActor.run {
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    private func clearChat() {
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
    
    private func loadEmbeddingCount() async {
        embeddingCount = await VectorStore.shared.getEmbeddingCount()
    }
}

// MARK: - Message Model
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

// MARK: - Message Bubble
// MARK: - Legacy Bubble Removed (See ChatComponents.swift)

// MARK: - Loading Bubble
struct LoadingBubble: View {
    @State private var dots = ""
    
    var body: some View {
        HStack {
            Text("Thinking\(dots)")
                .padding(12)
                .background(Color.claudeSurface)
                .foregroundStyle(Color.gray)
                .cornerRadius(16)
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }
}

#Preview {
    ChatView()
}
