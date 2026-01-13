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
        // Initialize Logger
        _ = WDLogger.info("App Started (Stealth Mode)", category: .general)
        
        // Ensure Storage Directory Exists
        Task {
            await ImageStorageManager.shared.ensureDirectoryExists()
        }
        
        // Start Retention Policy in Background Task since we have no Window.task
        Task {
            // Give app a moment to launch
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            await RetentionManager.shared.performCleanup()
        }
        
        // Start Screen Capture if permission exists (or check it)
        // Since we have no window on launch, we need to check if we should start recording.
        // For now, ScreenCaptureService.shared.checkPermission() is called in WindowManager? No.
        // We should trigger a check here.
        Task { @MainActor in
            ScreenCaptureService.shared.checkPermission()
            
            // Auto-start recording logic could go here later?
            // For now, let's open dashboard if first run? No, Stealth mode implies silence.
            // But if user has no idea app is running (since no dock), maybe show Dashboard on first launch?
            // Let's rely on WindowManager logic if we want.
        }
    }
}
