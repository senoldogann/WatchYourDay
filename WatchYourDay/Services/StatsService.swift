import Foundation
import SwiftData

/// Application usage statistics with formatted duration
struct AppUsageStat: Identifiable, Hashable {
    let id = UUID()
    let appName: String
    let durationSeconds: TimeInterval
    let category: String
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter.string(from: durationSeconds) ?? "0s"
    }
}


/// Data structure for periodic reports
struct ReportingData: Sendable {
    let focusScore: Double
    let totalMinutes: Int
    let topApps: [String]
    let categoryCounts: [String: Int]
    let textSegments: [String]
}

/// Statistics service for calculating app usage metrics
/// Uses ModelActor for thread-safe SwiftData access
@ModelActor
actor StatsService {
    
    /// Calculate daily usage statistics grouped by app
    /// Calculate daily usage statistics grouped by app
    func calculateDailyStats(for date: Date) -> [AppUsageStat] {
        let snapshots = fetchSnapshots(for: date)
        guard !snapshots.isEmpty else { return [] }
        
        var appDurations: [String: TimeInterval] = [:]
        var appCategories: [String: String] = [:]
        
        // Calculate durations based on time gaps between snapshots
        // Cap gap at 60 seconds (user idle/afk assumption)
        let maxGap: TimeInterval = 60
        
        for i in 0..<snapshots.count - 1 {
            let current = snapshots[i]
            let next = snapshots[i+1]
            
            let gap = next.timestamp.timeIntervalSince(current.timestamp)
            let duration = min(gap, maxGap)
            
            appDurations[current.appName, default: 0] += duration
            // Keep last known category
            appCategories[current.appName] = current.category
        }
        
        // Add last snapshot (assume minimal duration, e.g., 5s)
        if let last = snapshots.last {
            appDurations[last.appName, default: 0] += 5
            appCategories[last.appName] = last.category
        }
        
        return appDurations.map { (appName, duration) in
            AppUsageStat(
                appName: appName,
                durationSeconds: duration,
                category: appCategories[appName] ?? "Uncategorized"
            )
        }.sorted { $0.durationSeconds > $1.durationSeconds }
    }
    
    func getTotalRecordedTime(for date: Date) -> TimeInterval {
        let stats = calculateDailyStats(for: date)
        return stats.reduce(0) { $0 + $1.durationSeconds }
    }
    
    func calculateCategoryBreakdown(for date: Date) -> [String: Double] {
        let stats = calculateDailyStats(for: date)
        var breakdown: [String: Double] = [:]
        
        for stat in stats {
            breakdown[stat.category, default: 0] += stat.durationSeconds
        }
        
        // Convert seconds to minutes for easier reading? Or keep as seconds.
        // Let's keep as seconds for consistency with type Double
        return breakdown
    }
    
    func calculateHourlyFocus(for date: Date) -> [(Int, Double)] {
        let snapshots = fetchSnapshots(for: date)
        guard !snapshots.isEmpty else { return [] }
        
        var hourlyScores: [Int: (totalPoints: Double, count: Int)] = [:]
        
        // Initialize 24 hours
        for h in 0..<24 { hourlyScores[h] = (0, 0) }
        
        for snapshot in snapshots {
            let hour = Calendar.current.component(.hour, from: snapshot.timestamp)
            let isProd = isProductiveApp(snapshot.appName) || snapshot.category == "Productive" || snapshot.category == "Developer"
            
            let points = isProd ? 100.0 : 0.0
            
            if let existing = hourlyScores[hour] {
                hourlyScores[hour] = (existing.totalPoints + points, existing.count + 1)
            }
        }
        
        // Average
        return hourlyScores.sorted { $0.key < $1.key }.map { (hour, data) in
            let score = data.count > 0 ? data.totalPoints / Double(data.count) : 0.0
            return (hour, score)
        }
    }
    
    func calculateReportingData(for date: Date) -> ReportingData? {
        let stats = calculateDailyStats(for: date)
        guard !stats.isEmpty else { return nil }
        
        let totalTime = stats.reduce(0) { $0 + $1.durationSeconds }
        let totalMinutes = Int(totalTime / 60)
        
        // Focus Score (Weighted Average)
        // Assume categories "Productive", "Developer", "Work" are 100%
        // "Communication" is 50%
        // "Entertainment" is 0%
        
        var weightedSum: Double = 0
        
        for stat in stats {
            var weight = 0.0
            switch stat.category.lowercased() {
            case "productive", "developer", "work", "coding", "design": weight = 1.0
            case "communication", "email", "messaging": weight = 0.5
            default: weight = 0.0 // Entertainment, Social etc.
            }
            weightedSum += stat.durationSeconds * weight
        }
        
        let focusScore = totalTime > 0 ? (weightedSum / totalTime) * 100 : 0
        
        let topApps = stats.prefix(5).map { $0.appName }
        
        // Convert category breakdown to [String: Int] (minutes)
        let catBreakdown = calculateCategoryBreakdown(for: date).mapValues { Int($0 / 60) }
        
        return ReportingData(
            focusScore: focusScore,
            totalMinutes: totalMinutes,
            topApps: topApps,
            categoryCounts: catBreakdown,
            textSegments: [] // OCR Text aggregation is heavy, skipping for now
        )
    }
    
    // MARK: - Private Helpers
    private func fetchSnapshots(for date: Date) -> [Snapshot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        // Use ModelContext directly from the actor
        let predicate = #Predicate<Snapshot> { snap in
            snap.timestamp >= startOfDay && snap.timestamp < endOfDay
        }
        let descriptor = FetchDescriptor<Snapshot>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("StatsService Fetch Error: \(error)")
            return []
        }
    }

    // MARK: - Helpers (TODO: Move to a Configuration Service)
    private func isProductiveApp(_ appName: String) -> Bool {
        let productiveApps = ["Xcode", "VS Code", "Terminal", "Cursor", "Slack", "Figma", "Sketch", "Notion", "Obsidian"]
        return productiveApps.contains(where: { appName.localizedCaseInsensitiveContains($0) })
    }
    
    private func classifyCategory(app: String, rawCategory: String) -> String {
        if isProductiveApp(app) { return "Productive" }
        // Fallback to existing logic or raw category
        return rawCategory.capitalized
    }
}
