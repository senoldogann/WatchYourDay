import SwiftUI

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.claudeTextPrimary)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
