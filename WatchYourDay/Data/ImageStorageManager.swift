import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Thread-safe image storage manager using Actor isolation
/// Handles screenshot persistence with organized folder structure
actor ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let fileManager = FileManager()
    private let compressionQuality: CGFloat = 0.7  // 70% JPEG quality
    
    private var rootDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths.first!.appendingPathComponent("WatchYourDay", isDirectory: true)
        return appSupport.appendingPathComponent("Snapshots", isDirectory: true)
    }
    
    init() {
        // Ensure root directory exists on init
        Task {
            await ensureDirectoryExists()
        }
    }
    
    func ensureDirectoryExists() {
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Public API
    
    /// Save screenshot to disk with organized folder structure
    /// - Returns: Full path to saved image
    func saveImage(_ image: CGImage, timestamp: Date) throws -> String {
        // 1. Create Date Folder (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFolderString = dateFormatter.string(from: timestamp)
        
        let dayFolder = rootDirectory.appendingPathComponent(dateFolderString, isDirectory: true)
        if !fileManager.fileExists(atPath: dayFolder.path) {
            try fileManager.createDirectory(at: dayFolder, withIntermediateDirectories: true)
        }
        
        // 2. Create Filename (HH-mm-ss-SSS.jpg) with milliseconds for uniqueness
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH-mm-ss-SSS"
        let filename = "\(timeFormatter.string(from: timestamp)).jpg"
        let fileURL = dayFolder.appendingPathComponent(filename)
        
        // 3. Write Image as JPEG
        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw StorageError.destinationCreation
        }
        
        let properties: CFDictionary = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ] as CFDictionary
        
        CGImageDestinationAddImage(destination, image, properties)
        
        guard CGImageDestinationFinalize(destination) else {
            throw StorageError.writeFailed
        }
        
        return fileURL.path(percentEncoded: false)
    }
    
    /// Get total size of all stored snapshots
    func getTotalStorageSize() -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: rootDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
    
    /// Delete all snapshots older than specified days
    func cleanupOldSnapshots(olderThanDays days: Int) throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var deletedCount = 0
        
        let contents = try fileManager.contentsOfDirectory(
            at: rootDirectory,
            includingPropertiesForKeys: nil
        )
        
        for folder in contents {
            if let folderDate = dateFormatter.date(from: folder.lastPathComponent),
               folderDate < cutoffDate {
                try fileManager.removeItem(at: folder)
                deletedCount += 1
            }
        }
        
        return deletedCount
    }
    
    // MARK: - Errors
    
    enum StorageError: Error, LocalizedError {
        case destinationCreation
        case writeFailed
        
        var errorDescription: String? {
            switch self {
            case .destinationCreation: return "Failed to create image destination"
            case .writeFailed: return "Failed to write image to disk"
            }
        }
    }
}
