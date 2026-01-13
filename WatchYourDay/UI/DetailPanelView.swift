import SwiftUI
import SwiftData

struct DetailPanelView: View {
    let snapshot: Snapshot?
    var onImageTap: ((NSImage) -> Void)?
    
    @Query private var allSnapshots: [Snapshot]
    
    private var todaySnapshots: [Snapshot] {
        allSnapshots.filter { Calendar.current.isDateInToday($0.timestamp) }
    }
    
    private var focusMetrics: FocusMetrics {
        CategoryService.shared.calculateMetrics(for: todaySnapshots)
    }
    
    private var sessionStats: SessionStats {
        calculateSessionStats()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let snapshot = snapshot {
                    snapshotContent(snapshot)
                } else {
                    emptyState
                }
                
                
            Divider()
                .background(Color.gray.opacity(0.2))
            
            ScrollView {        // Summary Card (DayFlow style)
                summaryCard
                
                // Focus Meters
                focusMetersCard
            }
            }
            .padding()
        }
        .background(Color.claudeBackground)
    }
    
    // MARK: - Snapshot Content
    @ViewBuilder
    private func snapshotContent(_ snapshot: Snapshot) -> some View {
        let category = ActivityCategory(rawValue: snapshot.category) ?? .personal
        
        // Header
        HStack(spacing: 12) {
            Image(systemName: AppIcons.icon(for: snapshot.appName, windowTitle: snapshot.windowTitle))
                .font(.system(size: 20))
                .foregroundStyle(categoryColor(for: category))
                .frame(width: 36, height: 36)
                .background(categoryColor(for: category).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.windowTitle.isEmpty ? snapshot.appName : cleanTitle(snapshot.windowTitle))
                    .font(.headline)
                    .foregroundStyle(Color.claudeTextPrimary)
                    .lineLimit(2)
                
                Text(formatTimeRange(snapshot))
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
        }
        
        // Screenshot
        if let nsImage = NSImage(contentsOf: URL(fileURLWithPath: snapshot.imagePath)) {
            Button(action: { onImageTap?(nsImage) }) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
        }
    }
    
    // MARK: - Summary Card (DayFlow style with highlighted text)
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUMMARY")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.gray)
            
            Text(summaryText)
                .font(.callout)
                .foregroundStyle(Color.claudeTextPrimary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var summaryText: AttributedString {
        var text = AttributedString("Your session started at ")
        text.foregroundColor = Color.gray
        
        var startTime = AttributedString(formatTime(sessionStats.startTime))
        startTime.foregroundColor = Color.claudeAccent
        text += startTime
        
        var endPart = AttributedString(" and ended ")
        endPart.foregroundColor = Color.gray
        text += endPart
        
        var endTime = AttributedString(formatTime(sessionStats.endTime))
        endTime.foregroundColor = Color.claudeAccent
        text += endTime
        
        var totalPart = AttributedString(". The total time spent was ")
        totalPart.foregroundColor = Color.gray
        text += totalPart
        
        var duration = AttributedString(formatDuration(sessionStats.totalMinutes))
        duration.foregroundColor = Color.claudeAccent
        text += duration
        
        var focusPart = AttributedString(". Your focus was on the core task for ")
        focusPart.foregroundColor = Color.gray
        text += focusPart
        
        var focusPercent = AttributedString(String(format: "%.1f%%", focusMetrics.focusPercentage))
        focusPercent.foregroundColor = Color.categoryCore
        text += focusPercent
        
        var distractPart = AttributedString(" of the time. You got distracted ")
        distractPart.foregroundColor = Color.gray
        text += distractPart
        
        var distractCount = AttributedString("\(focusMetrics.distractionCount) times")
        distractCount.foregroundColor = Color.categoryDistraction
        text += distractCount
        
        var endText = AttributedString(".")
        endText.foregroundColor = Color.gray
        text += endText
        
        return text
    }
    
    // MARK: - Focus Meters Card
    private var focusMetersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 24) {
                // Focus Meter
                VStack(alignment: .leading, spacing: 6) {
                    Text("FOCUS METER")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.gray)
                    
                    Text("\(Int(focusMetrics.focusPercentage))%")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.claudeAccent)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.claudeAccent.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.claudeAccent)
                                .frame(width: geo.size.width * focusMetrics.focusPercentage / 100)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Distractions
                VStack(alignment: .leading, spacing: 6) {
                    Text("DISTRACTIONS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.gray)
                    
                    Text("\(Int(focusMetrics.distractionPercentage))%")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.categoryDistraction)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.categoryDistraction.opacity(0.2))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.categoryDistraction)
                                .frame(width: geo.size.width * focusMetrics.distractionPercentage / 100)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.gray)
            Text("Select a snapshot")
                .font(.subheadline)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Helpers
    private func cleanTitle(_ title: String) -> String {
        title
            .replacingOccurrences(of: " - Google Chrome", with: "")
            .replacingOccurrences(of: " - Safari", with: "")
            .replacingOccurrences(of: " — ", with: " - ")
    }
    
    private func formatTimeRange(_ snapshot: Snapshot) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: snapshot.timestamp).lowercased()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours) hrs \(mins) mins"
        }
        return "\(mins) mins"
    }
    
    private func categoryColor(for category: ActivityCategory) -> Color {
        switch category {
        case .core: return Color.categoryCore
        case .personal: return Color.categoryPersonal
        case .distraction: return Color.categoryDistraction
        case .idle: return Color.categoryIdle
        }
    }
    
    private func calculateSessionStats() -> SessionStats {
        guard let first = todaySnapshots.first, let last = todaySnapshots.last else {
            return SessionStats(startTime: Date(), endTime: Date(), totalMinutes: 0)
        }
        let minutes = Int(last.timestamp.timeIntervalSince(first.timestamp) / 60)
        return SessionStats(startTime: first.timestamp, endTime: last.timestamp, totalMinutes: max(1, minutes))
    }
}

struct SessionStats {
    let startTime: Date
    let endTime: Date
    let totalMinutes: Int
}

#Preview {
    DetailPanelView(snapshot: nil, onImageTap: { _ in })
        .frame(width: 400, height: 700)
}
