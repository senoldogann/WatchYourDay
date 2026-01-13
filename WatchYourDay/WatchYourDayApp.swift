//
//  WatchYourDayApp.swift
//  WatchYourDay
//
//  Created by dogan on 12.1.2026.
//
//

import SwiftUI
import SwiftData

@main
struct WatchYourDayApp: App {
    private let windowManager = WindowManager.shared
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        // Initialize Services on App Launch
        setupServices()
    }
    
    var body: some Scene {
        // Stealth Mode: Menu Bar Extra instead of WindowGroup
        MenuBarExtra("WatchYourDay", systemImage: "eye") {
            Button("Open Dashboard") {
                windowManager.openDashboard()
            }
            .keyboardShortcut("o")
            
            Divider()
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
    
    private func setupServices() {
        // Initialize Logger (Safe to run always)
        _ = WDLogger.info("App Started (Stealth Mode)", category: .general)
        
        // Ensure Storage Directory Exists
        Task {
            await ImageStorageManager.shared.ensureDirectoryExists()
        }
        
        // Decide flow
        if hasCompletedOnboarding {
            startBackgroundServices()
        } else {
            // First Run: Open Onboarding Warning
            // Must run on MainActor after app launch
            Task { @MainActor in
                // Small delay to ensure NSApp is ready
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                windowManager.openOnboarding {
                    // On Finish:
                    self.hasCompletedOnboarding = true
                    self.startBackgroundServices()
                    
                    // Optional: Open Dashboard immediately after onboarding
                    self.windowManager.openDashboard()
                }
            }
        }
    }
    
    private func startBackgroundServices() {
        WDLogger.info("Starting Background Services...", category: .general)
        
        // Start Retention Policy
        Task {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            await RetentionManager.shared.performCleanup()
        }
        
        // Auto-Start Screen Capture (if permission exists)
        Task {
            // Small delay to let system settle
            try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            
            // Start recording automatically
            await ScreenCaptureService.shared.startCapture()
            WDLogger.info("Auto-started screen recording", category: .screenCapture)
        }
    }
}
