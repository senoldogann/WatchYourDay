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
                    VStack(spacing: 8) {
                        Text("New Version Available: \(release.tagName)")
                            .font(.headline)
                            .foregroundStyle(.green)
                        
                        if let error = updateService.errorMessage {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            Task {
                                await updateService.downloadAndInstallUpdate()
                            }
                        }) {
                            HStack {
                                if updateService.isDownloading {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                }
                                Text(updateService.isDownloading ? "Installing..." : "Update & Restart")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(updateService.isDownloading)
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

