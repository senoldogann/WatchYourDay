import SwiftUI
import SwiftData

struct DailyActivityList: View {
    let selectedDate: Date
    let selectedFilter: ActivityCategory?
    @Binding var selectedSnapshot: Snapshot?
    var onGroupTap: ((SnapshotGroup) -> Void)?
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @Query var snapshots: [Snapshot]
    
    init(date: Date, filter: ActivityCategory?, selectedSnapshot: Binding<Snapshot?>, onGroupTap: ((SnapshotGroup) -> Void)?) {
        self.selectedDate = date
        self.selectedFilter = filter
        self._selectedSnapshot = selectedSnapshot
        self.onGroupTap = onGroupTap
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Predicate to fetch ONLY today's records
        let predicate = #Predicate<Snapshot> { snapshot in
            snapshot.timestamp >= startOfDay && snapshot.timestamp < endOfDay
        }
        
        // Sort by timestamp ascending
        _snapshots = Query(filter: predicate, sort: \.timestamp)
    }
    
    private var filteredSnapshots: [Snapshot] {
        if let filter = selectedFilter {
            return snapshots.filter { $0.category == filter.rawValue }
        }
        return snapshots
    }
    
    private var groupedActivities: [ActivityBlock] {
        var blocks: [ActivityBlock] = []
        var currentBlock: ActivityBlock?
        
        for snapshot in filteredSnapshots {
            let key = snapshot.appName + snapshot.windowTitle
            
            if let block = currentBlock, block.key == key {
                currentBlock?.snapshots.append(snapshot)
            } else {
                if let existing = currentBlock {
                    blocks.append(existing)
                }
                currentBlock = ActivityBlock(
                    key: key,
                    appName: snapshot.appName,
                    windowTitle: snapshot.windowTitle,
                    category: ActivityCategory(rawValue: snapshot.category) ?? .personal,
                    snapshots: [snapshot]
                )
            }
        }
        
        if let last = currentBlock {
            blocks.append(last)
        }
        
        return blocks
    }
    
    var body: some View {
        if snapshots.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedActivities) { block in
                        ActivityRow(
                            block: block,
                            isSelected: selectedSnapshot != nil && block.snapshots.contains { $0.id == selectedSnapshot?.id },
                            onTap: {
                                if block.snapshots.count == 1 {
                                    selectedSnapshot = block.snapshots.first
                                } else {
                                    let group = SnapshotGroup(appName: block.appName, hour: 0, snapshots: block.snapshots)
                                    onGroupTap?(group)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(Color.gray)
            Text("No recordings for this day")
                .font(.headline)
                .foregroundStyle(Color.claudeTextPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
