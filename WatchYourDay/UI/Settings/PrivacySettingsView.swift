import SwiftUI

struct PrivacySettingsView: View {
    @ObservedObject var blacklistManager = BlacklistManager.shared
    @State private var newBlacklistApp: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(Color.red.opacity(0.8))
                Text("PRIVACY & BLACKLIST")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            Text("Prevent these apps from being recorded or analyzed.")
                .font(.caption)
                .foregroundStyle(Color.gray)
            
            HStack {
                TextField("App Name (e.g. Chrome)", text: $newBlacklistApp)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: addBlacklistApp) {
                    Image(systemName: "plus")
                }
                .disabled(newBlacklistApp.isEmpty)
            }
            
            if blacklistManager.blockedApps.isEmpty {
                Text("No blacklisted apps.")
                    .italic()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(blacklistManager.blockedApps), id: \.self) { app in
                    HStack {
                        Text(app)
                            .foregroundStyle(Color.claudeTextPrimary)
                        Spacer()
                        Button(action: { blacklistManager.removeApp(app) }) {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.claudeBackground.opacity(0.5))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func addBlacklistApp() {
        guard !newBlacklistApp.isEmpty else { return }
        blacklistManager.addApp(newBlacklistApp)
        newBlacklistApp = ""
    }
}
