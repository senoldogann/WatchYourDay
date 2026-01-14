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
    @ObservedObject private var chatManager = ChatManager.shared
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chatManager.messages) { message in
                            ModernMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if chatManager.isLoading {
                            LoadingBubble()
                        }
                    }
                    .padding()
                }
                .onChange(of: chatManager.messages.count) { _, _ in
                    if let lastMessage = chatManager.messages.last {
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
            Task { await chatManager.loadEmbeddingCount() }
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
                
                Text("\(chatManager.embeddingCount) memories indexed")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            
            Spacer()
            
            Button(action: chatManager.clearChat) {
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
            .disabled(inputText.isEmpty || chatManager.isLoading)
        }
        .padding()
    }
    
    // MARK: - Actions
    private func sendMessage() {
        chatManager.sendMessage(inputText, modelContext: modelContext)
        inputText = ""
    }
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
