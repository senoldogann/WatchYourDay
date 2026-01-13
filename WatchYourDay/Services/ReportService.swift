import Foundation
import SwiftData

@Observable
class ReportManager {
    static let shared = ReportManager()
    
    private var timer: Timer?
    var isRunning = false
    
    func startReporting() {
        guard !isRunning else { return }
        isRunning = true
        
        // 15 Minutes = 900 seconds
        let newTimer = Timer(timeInterval: 900, repeats: true) { [weak self] _ in
            Task {
                await self?.generatePeriodicReport()
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
        
        WDLogger.info("Report timer started (15m interval)", category: .ai)
    }
    
    func stopReporting() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    func generatePeriodicReport(force: Bool = false) async -> DailyReport? {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        // 1. Calculate Statistics (Background - via Actor)
        let statsService = await StatsService(modelContainer: PersistenceController.shared.container)
        guard let data = await statsService.calculateReportingData(for: now) else {
            WDLogger.info("No data for report", category: .ai)
            return nil
        }
        
        // 2. AI Summary (Background)
        var summary = "No summary generated."
        if !data.textSegments.isEmpty {
            do {
                summary = try await OllamaService().summarize(segments: data.textSegments)
            } catch {
                WDLogger.error("AI Generation failed: \(error)", category: .ai)
                summary = "AI Summary unavailable."
            }
        }
        
        // 3. Save Report on MainActor
        return await MainActor.run {
            let context = PersistenceController.shared.container.mainContext
            let existingPredicate = #Predicate<DailyReport> { $0.date >= startOfDay }
            var existingDescriptor = FetchDescriptor<DailyReport>(predicate: existingPredicate)
            existingDescriptor.fetchLimit = 1
            
            let report: DailyReport
            if let existing = try? context.fetch(existingDescriptor).first {
                existing.summary = summary
                existing.focusPercentage = data.focusScore
                existing.totalMinutes = data.totalMinutes
                existing.topApps = data.topApps
                existing.categoryCounts = data.categoryCounts
                report = existing
                WDLogger.info("Updated existing DailyReport", category: .ai)
            } else {
                report = DailyReport(
                    date: startOfDay,
                    summary: summary,
                    focusPercentage: data.focusScore,
                    totalMinutes: data.totalMinutes,
                    topApps: data.topApps,
                    categoryCounts: data.categoryCounts
                )
                context.insert(report)
                WDLogger.info("Created new DailyReport", category: .ai)
            }
            
            do {
                try context.save()
            } catch {
                WDLogger.error("Failed to save DailyReport: \(error)", category: .ai)
            }
            return report
        }
    }
}


