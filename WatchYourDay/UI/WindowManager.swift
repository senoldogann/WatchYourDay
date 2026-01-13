import SwiftUI
import AppKit
import SwiftData

/// Manages the lifecycle of the main Dashboard window.
/// Essential for "Stealth Mode" where the app has no Dock icon.
@MainActor
class WindowManager {
    static let shared = WindowManager()
    
    // Hold a strong reference to the window controller/window
    var window: NSWindow?
    
    /// Toggles the visibility of the Dashboard window
    func toggleDashboard() {
        if let window = window, window.isVisible {
            closeDashboard()
        } else {
            openDashboard()
        }
    }
    
    /// Opens and focuses the Dashboard window
    func openDashboard() {
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        
        // Bring to front even if app is background/agent
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Closes the Dashboard window
    func closeDashboard() {
        window?.orderOut(nil)
    }
    
    /// Creates the NSWindow programmatically
    private func createWindow() {
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure Window
        newWindow.title = "WatchYourDay Dashboard"
        newWindow.center()
        newWindow.isReleasedWhenClosed = false // Keep it in memory when closed
        newWindow.titlebarAppearsTransparent = true
        // newWindow.titleVisibility = .hidden // Optional: Hide native title bar if we have a custom one
        
        // Set Content View (Hosting Controller)
        // We need to inject the same environment as the WindowGroup had
        let contentView = ContentView()
            .modelContainer(PersistenceController.shared.container)
            .frame(minWidth: 800, minHeight: 600)
        
        newWindow.contentViewController = NSHostingController(rootView: contentView)
        
        self.window = newWindow
    }
    
    // MARK: - Onboarding Window
    
    var onboardingWindow: NSWindow?
    
    func openOnboarding(onFinish: @escaping () -> Void) {
        if onboardingWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .fullSizeContentView], // No closable mask to force completion
                backing: .buffered,
                defer: false
            )
            
            window.title = "Welcome"
            window.center()
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            
            let onboardingView = OnboardingView {
                onFinish()
                self.closeOnboarding()
            }
            
            window.contentViewController = NSHostingController(rootView: onboardingView)
            self.onboardingWindow = window
        }
        
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeOnboarding() {
        onboardingWindow?.orderOut(nil)
        onboardingWindow = nil
    }
}
