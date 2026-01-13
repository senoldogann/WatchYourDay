import Foundation
import SwiftData

/// Manages data retention policies to save disk space
/// Deletes old image files while preserving Snapshot metadata for reporting
actor RetentionManager {
    static let shared = RetentionManager()
    
    // Default retention: 30 days
    private let defaultRetentionDays = 30
    
    /// Run the cleanup process
    /// - Parameter days: Snapshots older than this will have their images deleted. Defaults to Settings or 30.
    func performCleanup() async {
        let retentionDays = UserDefaults.standard.integer(forKey: "retentionDays")
        let days = retentionDays > 0 ? retentionDays : defaultRetentionDays
        
        WDLogger.info("Starting Retention Cleanup (older than \(days) days)...", category: .general)
        
        // 1. Calculate cutoff date
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return }
        
        // 2. Fetch old snapshots (MainActor for SwiftData)
        let snapshotsToDelete = await MainActor.run {
            let context = PersistenceController.shared.container.mainContext
            let predicate = #Predicate<Snapshot> { snapshot in
                snapshot.timestamp < cutoffDate && snapshot.imagePath.count > 0
            }
            var descriptor = FetchDescriptor<Snapshot>(predicate: predicate)
            // Fetch only necessary data if possible, but we need object for update later
            // To be safe, we fetch IDs and Paths
            
            do {
                let snapshots = try context.fetch(descriptor)
                return snapshots.map { ($0.persistentModelID, $0.imagePath) }
            } catch {
                WDLogger.error("Retention Fetch Failed: \(error)", category: .persistence)
                return []
            }
        }
        
        guard !snapshotsToDelete.isEmpty else {
            WDLogger.info("Retention: No old snapshots to clean.", category: .general)
            return
        }
        
        WDLogger.info("Retention: Found \(snapshotsToDelete.count) snapshots to clean.", category: .general)
        
        // 3. Delete files (Background)
        let result = await Task.detached(priority: .utility) { () -> (deletedCount: Int, regainedSize: Int64, idsOrphaned: [PersistentIdentifier]) in
            var deleted = 0
            var regained: Int64 = 0
            var processedIDs: [PersistentIdentifier] = []
            
            for (id, path) in snapshotsToDelete {
                if path.isEmpty { continue }
                let fileURL = URL(fileURLWithPath: path)
                
                if FileManager.default.fileExists(atPath: path) {
                    do {
                        let resources = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                        if let fileSize = resources.fileSize {
                            regained += Int64(fileSize)
                        }
                        try FileManager.default.removeItem(at: fileURL)
                        deleted += 1
                        processedIDs.append(id)
                    } catch {
                        WDLogger.error("Failed to delete file: \(path)", category: .general)
                    }
                } else {
                     // File missing, still mark as processed to clear path in DB
                     processedIDs.append(id)
                }
            }
            return (deleted, regained, processedIDs)
        }.value
        
        // 4. Update Model (MainActor)
        await MainActor.run {
             let context = PersistenceController.shared.container.mainContext
             do {
                 // Batch update by ID would be ideal, but for now we re-fetch by ID or assume we can't easily batch update specific rows without object.
                 // Actually, we can fetch by IDs.
                 let processedIDSet = Set(result.idsOrphaned)
                 let predicate = #Predicate<Snapshot> { snap in
                     processedIDSet.contains(snap.persistentModelID)
                 }
                 var descriptor = FetchDescriptor<Snapshot>(predicate: predicate)
                 let snapshotsToUpdate = try context.fetch(descriptor)
                 
                 for snap in snapshotsToUpdate {
                     snap.imagePath = "" // Mark as deleted
                 }
                 
                 try context.save()
                 
                 let mbSaved = DriverUtils.formatBytes(result.regainedSize)
                 WDLogger.info("Retention Complete: Deleted \(result.deletedCount) images, saved \(mbSaved).", category: .general)
                 
             } catch {
                  WDLogger.error("Retention Update Failed: \(error)", category: .persistence)
             }
        }
    }
}

// Helper for byte formatting (if not already available)
struct DriverUtils {
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
