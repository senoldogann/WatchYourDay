import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var stats: [AppUsageStat] = []
    @State private var isLoading = false
    @State private var aiSummary: String = ""
    @State private var isGeneratingSummary = false
    @State private var showDebugSheet = false
    @State private var lastDebugPrompt: String = ""
    
    private var todaySnapshots: [Snapshot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = #Predicate<Snapshot> { $0.timestamp >= startOfDay }
        let descriptor = FetchDescriptor<Snapshot>(predicate: predicate)
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // Helper to get today's report for persistence
    private var todayReport: DailyReport? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        // Predicate to find report for today
        // Note: We use date comparison range to be safe
        let predicate = #Predicate<DailyReport> {
            $0.date >= startOfDay && $0.date < endOfDay
        }
        let descriptor = FetchDescriptor<DailyReport>(predicate: predicate)
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    private var focusMetrics: FocusMetrics {
        CategoryService.shared.calculateMetrics(for: todaySnapshots)
    }
    
    private var totalTime: TimeInterval {
        // Calculate unique active minutes (wall-clock time)
        // Groups snapshots by minute to prevent double-counting multiple monitors
        let uniqueMinutes = Set(todaySnapshots.map {
            Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0.timestamp)
        })
        return TimeInterval(uniqueMinutes.count * 60)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                if isLoading {
                    loadingState
                } else if stats.isEmpty {
                    EmptyStateView()
                } else {
                    // AI Summary Card
                    AISummaryCard(
                        summary: aiSummary,
                        isGenerating: isGeneratingSummary,
                        onRefresh: { Task { await generateAISummary() } },
                        onDebug: { showDebugSheet = true },
                        showDebugSheet: $showDebugSheet,
                        debugPrompt: lastDebugPrompt,
                        debugResponse: aiSummary
                    )
                    
                    // Focus Overview
                    FocusOverviewCard(
                        focusMetrics: focusMetrics,
                        totalTimeFormatted: formatDuration(totalTime)
                    )
                    
                    // Category Breakdown Chart
                    CategoryBreakdownCard(
                        focusMetrics: focusMetrics,
                        totalSnapshots: todaySnapshots.count
                    )
                    
                    // Top Apps
                    TopAppsCard(stats: stats)
                    
                    // Activity Timeline Mini
                    ActivityTimelineCard(snapshots: todaySnapshots)
                }
            }
            .padding()
        }
        .background(Color.claudeBackground)
        .onAppear { Task { await loadStats() } }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Header Icon
            Image(systemName: "chart.bar.doc.horizontal.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.claudeAccent, Color.claudeSecondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Day Summary")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.claudeTextPrimary)
            
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - States
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading stats...")
                .font(.caption)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Helpers
    private func loadStats() async {
        isLoading = true
        defer { isLoading = false }
        
        // Calculate app usage based on unique active minutes
        // This prevents double-counting if an app appears on multiple screens or multiple times in a minute
        let snapshots = todaySnapshots
        var appMinutes: [String: Set<DateComponents>] = [:]
        var appCategories: [String: String] = [:]
        
        // Group timestamps by app (minute precision)
        for s in snapshots {
            let minute = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: s.timestamp)
            
            if appMinutes[s.appName] == nil {
                appMinutes[s.appName] = []
                appCategories[s.appName] = s.category
            }
            appMinutes[s.appName]?.insert(minute)
        }
        
        // Calculate duration based on unique minutes
        stats = appMinutes.map { (appName, minutes) in
            AppUsageStat(
                appName: appName,
                durationSeconds: Double(minutes.count * 60),
                category: appCategories[appName] ?? "personal"
            )
        }
        .sorted { $0.durationSeconds > $1.durationSeconds }
        
        // Load persisted AI Summary if available
        if let report = todayReport, !report.summary.isEmpty {
            self.aiSummary = report.summary
        }
    }
    
    private func generateAISummary() async {
        guard !stats.isEmpty else { return }
        isGeneratingSummary = true
        defer { isGeneratingSummary = false }
        
        do {
            // Use the new centralized AIService
            let response = try await AIService.shared.generateDailyReport(for: todaySnapshots)
            
            // Update UI
            self.aiSummary = response
            
            // Persist to SwiftData
            await saveSummary(response)
            
        } catch {
            aiSummary = "Unable to generate AI insights. Ensure Ollama is running (localhost:11434)."
            lastDebugPrompt = "Error: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func saveSummary(_ summary: String) {
        let report = todayReport ?? DailyReport(
            date: Calendar.current.startOfDay(for: Date()),
            summary: summary,
            focusPercentage: focusMetrics.focusPercentage,
            totalMinutes: Int(totalTime / 60),
            topApps: stats.prefix(5).map { $0.appName },
            categoryCounts: ["core": focusMetrics.coreCount, "personal": focusMetrics.personalCount, "distraction": focusMetrics.distractionCount]
        )
        
        report.summary = summary
        // Update other metrics to keep them fresh
        report.focusPercentage = focusMetrics.focusPercentage
        report.totalMinutes = Int(totalTime / 60)
        report.topApps = stats.prefix(5).map { $0.appName }
        report.categoryCounts = ["core": focusMetrics.coreCount, "personal": focusMetrics.personalCount, "distraction": focusMetrics.distractionCount]
        
        if report.modelContext == nil {
            modelContext.insert(report)
        }
        
        try? modelContext.save()
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
