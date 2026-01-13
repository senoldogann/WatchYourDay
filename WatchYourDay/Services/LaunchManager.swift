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
    
    func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notFound { return }
                try SMAppService.mainApp.unregister()
            }
            // Update state on main thread if needed, or published property handles it
            DispatchQueue.main.async {
                self.isEnabled = enabled
            }
        } catch {
            print("Failed to toggle Launch at Login: \(error)")
            // Revert state if failed
            DispatchQueue.main.async {
                self.isEnabled = SMAppService.mainApp.status == .enabled
            }
        }
    }
}
