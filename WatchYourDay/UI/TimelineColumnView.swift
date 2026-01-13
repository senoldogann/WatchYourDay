import SwiftUI
import SwiftData

struct TimelineColumnView: View {
    @Binding var selectedDate: Date
    @Binding var selectedSnapshot: Snapshot?
    var onGroupTap: ((SnapshotGroup) -> Void)?
    
    @State private var selectedFilter: ActivityCategory? = nil
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            DateNavigationView(selectedDate: $selectedDate)
            CategoryFilterBar(selectedFilter: $selectedFilter)
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            DailyActivityList(
                date: selectedDate,
                filter: selectedFilter,
                selectedSnapshot: $selectedSnapshot,
                onGroupTap: onGroupTap
            )
        }
        .background(Color.claudeBackground)
    }
}

// MARK: - Activity Block Model
struct ActivityBlock: Identifiable {
    let id = UUID()
    let key: String
    let appName: String
    let windowTitle: String
    let category: ActivityCategory
    var snapshots: [Snapshot]
    
    var startTime: Date { snapshots.first?.timestamp ?? Date() }
    var endTime: Date { snapshots.last?.timestamp ?? Date() }
    
    var displayTitle: String {
        if !windowTitle.isEmpty {
            // Extract meaningful title
            let title = windowTitle
                .replacingOccurrences(of: " - Google Chrome", with: "")
                .replacingOccurrences(of: " - Safari", with: "")
                .replacingOccurrences(of: " - Firefox", with: "")
                .replacingOccurrences(of: " — ", with: " - ")
            return title
        }
        return appName
    }
}

// MARK: - Activity Row (DayFlow Style)
struct ActivityRow: View {
    let block: ActivityBlock
    let isSelected: Bool
    let onTap: () -> Void
    
    private var categoryColor: Color {
        switch block.category {
        case .core: return Color.categoryCore
        case .personal: return Color.categoryPersonal
        case .distraction: return Color.categoryDistraction
        case .idle: return Color.categoryIdle
        }
    }
    
    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: block.startTime)
    }
    
    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return "\(formatter.string(from: block.startTime).lowercased()) to \(formatter.string(from: block.endTime).lowercased())"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column with dot
            VStack(spacing: 4) {
                Text(timeLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.gray)
                
                Circle()
                    .fill(block.category == .distraction ? Color.red : Color.claudeAccent)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 60)
            
            // Activity block
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // App icon
                    Image(systemName: AppIcons.icon(for: block.appName, windowTitle: block.windowTitle))
                        .font(.system(size: 16))
                        .foregroundStyle(categoryColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(block.displayTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.claudeTextPrimary)
                            .lineLimit(1)
                        
                        Text(timeRange)
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                    
                    Spacer()
                    
                    Text("\(block.snapshots.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.claudeAccent)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(categoryColor.opacity(isSelected ? 0.25 : 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Filter Bar
struct CategoryFilterBar: View {
    @Binding var selectedFilter: ActivityCategory?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", icon: "square.grid.2x2", color: Color.claudeAccent, isSelected: selectedFilter == nil) {
                    withAnimation { selectedFilter = nil }
                }
                
                ForEach(ActivityCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        color: categoryColor(for: category),
                        isSelected: selectedFilter == category
                    ) {
                        withAnimation { selectedFilter = category }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.claudeSurface.opacity(0.5))
    }
    
    private func categoryColor(for category: ActivityCategory) -> Color {
        switch category {
        case .core: return Color.categoryCore
        case .personal: return Color.categoryPersonal
        case .distraction: return Color.categoryDistraction
        case .idle: return Color.categoryIdle
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.3) : Color.claudeSurface)
            .foregroundStyle(isSelected ? color : Color.gray)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? color : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
    }
}

#Preview {
    @Previewable @State var date = Date()
    @Previewable @State var snapshot: Snapshot? = nil
    TimelineColumnView(selectedDate: $date, selectedSnapshot: $snapshot, onGroupTap: { _ in })
}
