import SwiftUI
import SwiftData
import Combine
import Charts

struct ContentView: View {
    @State private var service = ScreenCaptureService.shared
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Navigation State
    @State private var selectedTab: SidebarTab = .timeline
    @State private var selectedDate: Date = Date()
    @State private var selectedSnapshot: Snapshot? = nil
    
    // Delete Confirmation
    @State private var showDeleteConfirmation = false
    
    // Resizable Panel
    @State private var detailPanelWidth: CGFloat = 450
    private let minPanelWidth: CGFloat = 300
    private let maxPanelWidth: CGFloat = 700
    
    // Group Modal
    @State private var expandedGroup: SnapshotGroup? = nil
    
    // Image Preview Modal
    @State private var previewImage: NSImage? = nil
    
    var body: some View {
        ZStack {
            Group {
                if service.hasPermission {
                    mainLayout
                } else {
                    PermissionView()
                }
            }
            .onAppear {
                service.checkPermission()
                performDataRetention()
            }
            .alert("Clear All Data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    performDelete()
                }
            } message: {
                Text("This will permanently delete all recordings and cannot be undone.")
            }
            
            // Custom Overlay: Group Snapshots Modal
            if let group = expandedGroup {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedGroup = nil
                        }
                    }
                    .transition(.opacity)
                
                GroupDetailSheet(
                    group: group,
                    selectedSnapshot: $selectedSnapshot,
                    onDismiss: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedGroup = nil 
                        }
                    }
                )
                .background(Color.claudeBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 20)
                .padding(40)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .id(group.id) // Force redraw if group changes
            }
            
            // Custom Overlay: Image Preview Modal
            if let image = previewImage {
                ImagePreviewModal(image: image) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        previewImage = nil
                    }
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
    
    // MARK: - Main 3-Column Layout
    private var mainLayout: some View {
        HStack(spacing: 0) {
            // Left: Icon Sidebar
            IconSidebarView(selectedTab: $selectedTab, onClearData: {
                showDeleteConfirmation = true
            })
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Center: Content based on selected tab
            centerContent
            
            // Right: Detail Panel (ALWAYS visible)
            resizeHandle
            
            DetailPanelView(
                snapshot: selectedSnapshot,
                onImageTap: { image in
                    previewImage = image
                }
            )
            .frame(width: detailPanelWidth)
        }
        .background(Color.claudeBackground)
        .preferredColorScheme(ThemeManager.shared.currentTheme.colorScheme)
    }
    
    // MARK: - Resize Handle
    private var resizeHandle: some View {
        Rectangle()
            .fill(Color.claudeSurface)
            .frame(width: 6)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newWidth = detailPanelWidth - value.translation.width
                        detailPanelWidth = min(max(newWidth, minPanelWidth), maxPanelWidth)
                    }
            )
            .onHover { isHovering in
                if isHovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
    
    // MARK: - Center Content
    @ViewBuilder
    private var centerContent: some View {
        switch selectedTab {

        case .timeline:
            TimelineColumnView(
                selectedDate: $selectedDate,
                selectedSnapshot: $selectedSnapshot,
                onGroupTap: { group in
                    expandedGroup = group
                }
            )
            
        case .chat:
            ChatView()
            
        case .stats:
            StatsView()
            
        case .settings:
            SettingsView()
        }
    }
    
    // MARK: - Actions
    private func performDelete() {
        Task {
            do {
                try modelContext.delete(model: Snapshot.self)
                selectedSnapshot = nil
            } catch {
                WDLogger.error("Failed to clear data: \(error)", category: .persistence)
            }
        }
    }
    
    private func performDataRetention() {
        Task {
            do {
                // Keep last 30 days
                let deletedCount = try await ImageStorageManager.shared.cleanupOldSnapshots(olderThanDays: 30)
                if deletedCount > 0 {
                    WDLogger.info("Data retention: Cleaned up \(deletedCount) old snapshot folders", category: .persistence)
                }
            } catch {
                WDLogger.error("Data retention failed: \(error)", category: .persistence)
            }
        }
    }
}

// MARK: - Snapshot Group Model
struct SnapshotGroup: Identifiable {
    let id = UUID()
    let appName: String
    let hour: Int
    let snapshots: [Snapshot]
}

// MARK: - Group Detail Sheet
struct GroupDetailSheet: View {
    let group: SnapshotGroup
    @Binding var selectedSnapshot: Snapshot?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(group.appName)
                        .font(.headline)
                        .foregroundStyle(Color.claudeTextPrimary)
                    
                    Text("\(group.snapshots.count) snapshots")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.claudeSurface)
            
            Divider()
            
            // Snapshots Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 12)
                ], spacing: 12) {
                    ForEach(group.snapshots, id: \.id) { snapshot in
                        SnapshotThumbnail(snapshot: snapshot) {
                            selectedSnapshot = snapshot
                            onDismiss()
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color.claudeBackground)
    }
}

// MARK: - Snapshot Thumbnail
struct SnapshotThumbnail: View {
    let snapshot: Snapshot
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail
                if let nsImage = NSImage(contentsOf: URL(fileURLWithPath: snapshot.imagePath)) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.claudeSurface)
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(Color.gray)
                        )
                }
                
                // Info
                Text(snapshot.windowTitle.isEmpty ? snapshot.appName : snapshot.windowTitle)
                    .font(.caption)
                    .foregroundStyle(Color.claudeTextPrimary)
                    .lineLimit(1)
                
                Text(snapshot.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
            }
            .padding(8)
            .background(Color.claudeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Image Preview Modal
struct ImagePreviewModal: View {
    let image: NSImage
    let onDismiss: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var backgroundColor: Color {
        switch themeManager.currentTheme {
        case .light: return Color(hex: "F2F0E9").opacity(0.95)
        case .dark, .system: return Color.black.opacity(0.9)
        }
    }
    
    private var closeButtonColor: Color {
        switch themeManager.currentTheme {
        case .light: return Color.gray
        case .dark, .system: return Color.white
        }
    }
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(closeButtonColor)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                
                Spacer()
                
                GeometryReader { geometry in
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.3), radius: 20)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 5)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1 {
                                        withAnimation { scale = 1.0 }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .padding()
                
                Spacer()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Snapshot.self, inMemory: true)
}


