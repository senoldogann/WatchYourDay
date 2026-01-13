import Foundation
import CoreGraphics
import AppKit
import Combine

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var hasScreenRecordingPermission: Bool = false
    
    init() {
        checkPermission()
    }
    
    @MainActor
    func checkPermission() {
        // CGPreflightScreenCaptureAccess returns true if we have permission
        // On macOS 10.15+, it reliably tells us if we can capture.
        let hasPermission = CGPreflightScreenCaptureAccess()
        
        // Only update if changed to avoid unnecessary UI refreshes
        if hasScreenRecordingPermission != hasPermission {
            hasScreenRecordingPermission = hasPermission
        }
    }
    
    /// Weak reference to the polling timer to allow proper cleanup
    private var permissionCheckTimer: Timer?
    
    /// Maximum number of permission check attempts (10 seconds total)
    private let maxRetryCount = 10
    
    func requestPermission() {
        // This API call triggers the system prompt if not yet granted.
        CGRequestScreenCaptureAccess()
        
        // Cancel any existing timer to prevent duplicates
        permissionCheckTimer?.invalidate()
        
        var retryCount = 0
        
        // Re-check after a delay (since user action is async)
        // Timer is now properly managed with a retry limit
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            retryCount += 1
            
            // Check permission status
            let hasPermission = CGPreflightScreenCaptureAccess()
            
            if hasPermission {
                DispatchQueue.main.async {
                    self.hasScreenRecordingPermission = true
                }
                timer.invalidate()
                self.permissionCheckTimer = nil
                WDLogger.info("Screen Recording permission granted.", category: .general)
                return
            }
            
            // Prevent infinite loop: stop after maxRetryCount attempts
            if retryCount >= self.maxRetryCount {
                timer.invalidate()
                self.permissionCheckTimer = nil
                WDLogger.info("Permission check timed out after \(retryCount) attempts.", category: .general)
            }
        }
    }
    
    /// Call this when the view disappears to prevent leaks
    func stopPermissionPolling() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
    
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
