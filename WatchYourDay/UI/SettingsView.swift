import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var theme = ThemeManager.shared
    // Theme Manager might be used for global theme settings if we add them here, 
    // but sub-views handle their own styling mostly.
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                SystemSettingsView()
                PrivacySettingsView()
                AISettingsView()
                ExportSettingsView()
                StorageSettingsView()
                AboutSettingsView()
            }
            .padding()
        }
        .background(Color.claudeBackground)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.claudeAccent, Color.claudeSecondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Settings")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.claudeTextPrimary)
            
            Text("Configure your WatchYourDay experience")
                .font(.subheadline)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
