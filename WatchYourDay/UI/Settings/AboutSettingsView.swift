import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.claudeAccent)
            
            Text("WatchYourDay")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.claudeTextPrimary)
            
            Text("v1.0.0 (Build 1)")
                .font(.caption)
                .foregroundStyle(Color.gray)
            
            Text("© 2026 AntiGravity")
                .font(.caption2)
                .foregroundStyle(Color.gray.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
