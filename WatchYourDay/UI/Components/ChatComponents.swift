import SwiftUI

// MARK: - Typewriter Text
struct TypewriterText: View {
    let text: String
    @State private var displayedText: String = ""
    @State private var fullText: String = ""
    
    var body: some View {
        Text(LocalizedStringKey(displayedText))
            .textSelection(.enabled)
            .onAppear {
                startTyping(newText: text)
            }
            .onChange(of: text) { newValue in
                startTyping(newText: newValue)
            }
    }
    
    private func startTyping(newText: String) {
        fullText = newText
        displayedText = "" // Reset
        
        // If text is short, show immediately
        // If text is long, animate
        
        var currentIndex = 0
        let chars = Array(newText)
        
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if currentIndex < chars.count {
                displayedText.append(chars[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Modern Bubble
struct ModernMessageBubble: View {
    let message: ChatMessage
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.role == .assistant {
                // AI Avatar
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            } else {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Content
                Group {
                    if message.role == .assistant {
                        Text(LocalizedStringKey(message.content))
                    } else {
                        Text(message.content)
                    }
                }
                .padding(14)
                .background(bubbleBackground)
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(BubbleShape(role: message.role)) // Use Custom Shape
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Timestamp
                if message.role == .assistant {
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            if message.role == .user {
                // User Avatar
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 60)
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
    
    private var bubbleBackground: some View {
        Group {
            if message.role == .user {
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
            } else {
                Color(nsColor: .controlBackgroundColor).opacity(0.8)
            }
        }
    }
}

// MARK: - Bubble Shape (macOS Compatible)
struct BubbleShape: Shape {
    let role: MessageRole
    let radius: CGFloat = 18
    
    func path(in rect: CGRect) -> Path {
        let path = Path { p in
            // Start at top left
            p.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            
            // Top edge
            p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            
            // Top Right Corner
            p.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                     radius: radius,
                     startAngle: Angle(degrees: -90),
                     endAngle: Angle(degrees: 0),
                     clockwise: false)
            
            // Right edge
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            
            // Bottom Right Corner (Sharp for User, Round for AI)
            if role == .user {
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
            } else {
                p.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                         radius: radius,
                         startAngle: Angle(degrees: 0),
                         endAngle: Angle(degrees: 90),
                         clockwise: false)
            }
            
            // Bottom edge
            p.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            
            // Bottom Left Corner (Sharp for AI, Round for User)
            if role == .assistant {
                p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            } else {
                p.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                         radius: radius,
                         startAngle: Angle(degrees: 90),
                         endAngle: Angle(degrees: 180),
                         clockwise: false)
                
                // Left edge
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            }
            
            // Top Left Corner
            p.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                     radius: radius,
                     startAngle: Angle(degrees: 180),
                     endAngle: Angle(degrees: 270),
                     clockwise: false)
            
            p.closeSubpath()
        }
        return path
    }
}
