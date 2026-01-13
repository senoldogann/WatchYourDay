import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 56))
                .foregroundStyle(Color.gray.opacity(0.5))
            
            Text("No Activity Today")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.claudeTextPrimary)
            
            Text("Start recording to see your productivity insights")
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
