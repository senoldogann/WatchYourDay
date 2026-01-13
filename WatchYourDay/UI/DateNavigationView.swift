import SwiftUI

struct DateNavigationView: View {
    @Binding var selectedDate: Date
    @State private var service = ScreenCaptureService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        HStack {
            // Previous Day
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Color.claudeTextPrimary)
            }
            .buttonStyle(.plain)
            .onHover { isHovering in
                if isHovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
            
            // Date Display
            Text(formattedDate)
                .font(.headline)
                .foregroundStyle(Color.claudeTextPrimary)
                .frame(minWidth: 150)
            
            // Next Day
            Button(action: {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(isToday ? Color.gray.opacity(0.3) : Color.claudeTextPrimary)
            }
            .buttonStyle(.plain)
            .onHover { isHovering in
                if isHovering && !isToday { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
            .disabled(isToday)
            
            Spacer()
            
            // Record Button
            Button(action: {
                Task {
                    if service.isRecording {
                        await service.stopCapture()
                    } else {
                        await service.startCapture()
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(service.isRecording ? Color.red : Color.claudeAccent)
                        .frame(width: 10, height: 10)
                    
                    Text(service.isRecording ? "Stop" : "Record")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.claudeSurface)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .onHover { isHovering in
                if isHovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.claudeBackground)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        if isToday {
            formatter.dateFormat = "'Today,' MMM d"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
        }
        return formatter.string(from: selectedDate)
    }
}

#Preview {
    DateNavigationView(selectedDate: .constant(Date()))
        .background(Color.claudeBackground)
}
