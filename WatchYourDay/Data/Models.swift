import Foundation
import SwiftData

@Model
final class Snapshot {
    @Attribute(.unique) var id: UUID
    @Attribute(.spotlight) var timestamp: Date
    var imagePath: String
    var ocrText: String
    var appName: String
    var windowTitle: String
    var category: String  // core, personal, distraction, idle
    var displayID: Int = 0 // 0 = Main, others = secondary
    
    // AI Analysis
    var aiSummary: String?
    
    init(timestamp: Date, imagePath: String, ocrText: String = "", appName: String = "Unknown", windowTitle: String = "", category: String = "personal", displayID: Int = 0) {
        self.id = UUID()
        self.timestamp = timestamp
        self.imagePath = imagePath
        self.ocrText = ocrText
        self.appName = appName
        self.windowTitle = windowTitle
        self.category = category
        self.displayID = displayID
    }
}

// MARK: - Daily Report Model
@Model
final class DailyReport {
    @Attribute(.unique) var id: UUID
    var date: Date              // The day this report covers
    var summary: String         // AI-generated summary
    var focusPercentage: Double // Overall focus score
    var totalMinutes: Int       // Total tracked time
    
    // Core Data doesn't like generic collections implies via Transformable sometimes.
    // We store as JSON Data to be 100% safe.
    var topAppsData: Data?
    var categoryCountsData: Data?
    
    var createdAt: Date
    
    // Computed Wrappers
    var topApps: [String] {
        get {
            guard let data = topAppsData, !data.isEmpty else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            topAppsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    var categoryCounts: [String: Int] {
        get {
            guard let data = categoryCountsData, !data.isEmpty else { return [:] }
            return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
        }
        set {
            categoryCountsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    init(date: Date, summary: String, focusPercentage: Double = 0, totalMinutes: Int = 0, topApps: [String] = [], categoryCounts: [String: Int] = [:]) {
        self.id = UUID()
        self.date = date
        self.summary = summary
        self.focusPercentage = focusPercentage
        self.totalMinutes = totalMinutes
        
        // Encode immediately
        self.topAppsData = (try? JSONEncoder().encode(topApps)) ?? Data()
        self.categoryCountsData = (try? JSONEncoder().encode(categoryCounts)) ?? Data()
        
        self.createdAt = Date()
    }
}
