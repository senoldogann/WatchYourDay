import SwiftUI
import Combine

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var currentPage = 0
    // Use an environment value or callback to close the window
    var onFinish: () -> Void
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                WelcomePage()
                    .tag(0)
                
                // Page 2: Permissions
                PermissionsPage(permissionManager: permissionManager)
                    .tag(1)
                
                // Page 3: Configuration (Auto-Start)
                ConfigurationPage()
                    .tag(2)
                
                // Page 4: Finish
                FinishPage(onFinish: {
                    hasCompletedOnboarding = true
                    onFinish()
                })
                .tag(3)
            }
            // Note: .tabViewStyle(.page) is iOS-only. macOS uses default tab styling.
            
            // Navigation Controls
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }
                
                Spacer()
                
                if currentPage < 3 {
                    Button("Next") {
                        withAnimation { currentPage += 1 }
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    // Permission is now optional during onboarding
                    // It will be requested when user tries to record
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Subviews

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("Welcome to WatchYourDay")
                .font(.largeTitle)
                .bold()
            
            Text("Your personal, private time machine.\nWe capture your work, index your screen text,\nand give you insights.")
                .multilineTextAlignment(.center)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

struct PermissionsPage: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("We Need Access")
                .font(.title)
                .bold()
            
            Text("To capture your activity, WatchYourDay needs\nScreen Recording permission. You can grant it now or later.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 15) {
                if permissionManager.hasScreenRecordingPermission {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Permission Granted")
                            .bold()
                    }
                    .font(.title2)
                } else {
                    Button("Grant Access") {
                        permissionManager.requestPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Text("If a system prompt appears, click 'Allow'.\nIf not, click below to open Settings.")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    Button("Open System Settings") {
                        permissionManager.openSystemSettings()
                    }
                    .buttonStyle(.link)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            Task { @MainActor in
                permissionManager.checkPermission()
            }
        }
    }
}

struct ConfigurationPage: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    
    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "gear")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            Text("Setup")
                .font(.title)
                .bold()
            
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.large)
                .onChange(of: launchAtLogin) { newValue in
                    Task {
                        try? LaunchManager.shared.configureLaunchAtLogin(enabled: newValue)
                    }
                }
            
            Text("We recommend keeping this ON so you never forget to track your day.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            // Sync toggle with actual system state
            launchAtLogin = LaunchManager.shared.isLaunchAtLoginEnabled
        }
    }
}

struct FinishPage: View {
    var onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .bold()
            
            Text("WatchYourDay lives in your menu bar.\nClick the Eye icon to see your dashboard.")
                .multilineTextAlignment(.center)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Button("Start Tracking") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
    }
}
