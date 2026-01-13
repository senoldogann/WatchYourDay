import SwiftUI

struct AISummaryCard: View {
    let summary: String
    let isGenerating: Bool
    let onRefresh: () -> Void
    let onDebug: () -> Void
    
    @Binding var showDebugSheet: Bool
    let debugPrompt: String
    let debugResponse: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.claudeAccent)
                Text("AI INSIGHTS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
                
                Spacer()
                
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    HStack(spacing: 12) {
                        if !summary.isEmpty {
                            Button(action: onDebug) {
                                Image(systemName: "ladybug")
                                    .font(.caption)
                                    .foregroundStyle(Color.gray.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            .help("Show Debug Info")
                        }
                        
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                        .buttonStyle(.plain)
                        .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                    }
                }
            }
            .sheet(isPresented: $showDebugSheet) {
                DebugSummaryView(prompt: debugPrompt, response: debugResponse)
            }
            
            if summary.isEmpty {
                Text("Click refresh to generate AI insights about your day...")
                    .font(.callout)
                    .foregroundStyle(Color.gray)
                    .italic()
            } else {
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(Color.claudeTextPrimary)
                    .lineSpacing(4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.claudeAccent.opacity(0.15), Color.claudeSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.claudeAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DebugSummaryView: View {
    let prompt: String
    let response: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Debug Info")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Prompt Sent:")
                        .font(.caption).bold()
                        .foregroundStyle(.gray)
                    ScrollView {
                        Text(prompt)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Response Received:")
                        .font(.caption).bold()
                        .foregroundStyle(.gray)
                    ScrollView {
                        Text(response)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            Button("Close") { dismiss() }
                .keyboardShortcut(.escape, modifiers: [])
        }
        .padding()
        .frame(width: 700, height: 500)
    }
}
