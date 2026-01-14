import SwiftUI

struct AboutSettingsView: View {
    @StateObject private var updateService = UpdateService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.claudeAccent)
            
            Text("WatchYourDay")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.claudeTextPrimary)
            
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.caption)
                .foregroundStyle(Color.gray)
            
            if updateService.isUpdateAvailable, let release = updateService.latestRelease {
                VStack(spacing: 6) {
                    Text("New Version Available: \(release.tagName)")
                        .font(.headline)
                        .foregroundStyle(.green)
                    
                    Link(destination: URL(string: release.htmlUrl)!) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download Update")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 8)
            } else {
                Button("Check for Updates") {
                    Task {
                        await updateService.checkForUpdates()
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.top, 4)
            }
            
            Text("© 2026 Senol Dogan")
                .font(.caption2)
                .foregroundStyle(Color.gray.opacity(0.6))
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

