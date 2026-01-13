import Foundation
import os

/// Centralized logging system with category-based filtering
/// Uses Apple's unified logging system (os_log) for production-grade logging
enum LogCategory: String {
    case general = "General"
    case screenCapture = "ScreenCapture"
    case ocr = "OCR"
    case ai = "AI"
    case persistence = "Persistence"
    case security = "Security"
    case performance = "Performance"
}

struct WDLogger {
    private static let subsystem = "com.senoldogan.WatchYourDay"
    
    // MARK: - Nonisolated Methods (can be called from any context)
    
    static func log(_ message: String, category: LogCategory, type: OSLogType = .default) {
        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        logger.log(level: type, "\(message)")
        
        #if DEBUG
        print("[\(category.rawValue)] \(message)")
        #endif
    }
    
    static func debug(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .debug)
    }
    
    static func info(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .info)
    }
    
    static func error(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .error)
    }
    
    static func fault(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .fault)
    }
    
    // MARK: - Performance Measurement
    
    static func measureTime<T>(_ label: String, category: LogCategory = .performance, operation: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        log("\(label): \(String(format: "%.3f", elapsed * 1000))ms", category: category, type: .debug)
        return result
    }
}
