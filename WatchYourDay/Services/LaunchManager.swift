import Foundation
import ServiceManagement
import SwiftUI
import Combine

/// Manages "Launch at Login" functionality using modern SMAppService (macOS 13+)
class LaunchManager: ObservableObject {
    static let shared = LaunchManager()
    
    @Published var isEnabled: Bool = false
    
    private init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    var isLaunchAtLoginEnabled: Bool { isEnabled }
    
    func configureLaunchAtLogin(enabled: Bool) throws {
        // Throwing version allows caller to handle errors if needed
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notFound { return }
                try SMAppService.mainApp.unregister()
            }
            
            DispatchQueue.main.async {
                self.isEnabled = enabled
            }
        } catch {
            WDLogger.error("Failed to toggle Launch at Login: \(error)", category: .general)
            DispatchQueue.main.async {
                self.isEnabled = SMAppService.mainApp.status == .enabled
            }
            throw error
        }
    }
}
