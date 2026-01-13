import SwiftUI

struct PermissionView: View {
    @State private var service = ScreenCaptureService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "macwindow.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Screen Recording Permission Needed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Dayflow needs to see your screen to generate your timeline. Your data stays on your device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Grant Permission") {
                 service.requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if service.hasPermission {
                Text("Permission Granted! You can restart the app if it doesn't proceed.")
                    .foregroundStyle(.green)
            }
            
            Text("System Settings > Privacy & Security > Screen Recording")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    PermissionView()
}
