import SwiftUI

struct SystemSettingsView: View {
    @ObservedObject var launchManager = LaunchManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "macwindow")
                    .foregroundStyle(Color.claudeAccent)
                Text("SYSTEM")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            Toggle(isOn: Binding(
                get: { launchManager.isEnabled },
                set: { try? launchManager.configureLaunchAtLogin(enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Launch at Login")
                        .font(.subheadline)
                        .foregroundStyle(Color.claudeTextPrimary)
                    Text("Automatically start WatchYourDay when you log in.")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
            }
            .toggleStyle(.switch)
            .tint(Color.claudeAccent)
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
