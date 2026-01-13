import SwiftUI

struct TopAppsCard: View {
    let stats: [AppUsageStat]
    
    // Helper needed because categoryColor logic was private in main view
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "core": return .categoryCore
        case "distraction": return .categoryDistraction
        default: return .categoryPersonal
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOP APPS")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.claudeSecondaryAccent)
            
            ForEach(Array(stats.prefix(5).enumerated()), id: \.element.id) { index, stat in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.gray)
                        .frame(width: 20)
                    
                    Image(systemName: AppIcons.icon(for: stat.appName, windowTitle: ""))
                        .font(.body)
                        .foregroundStyle(categoryColor(for: stat.category))
                        .frame(width: 24)
                    
                    Text(stat.appName)
                        .font(.subheadline)
                        .foregroundStyle(Color.claudeTextPrimary)
                    
                    Spacer()
                    
                    Text(stat.formattedDuration)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.claudeAccent)
                }
                .padding(.vertical, 8)
                
                if index < 4 && index < stats.count - 1 {
                    Divider().background(Color.white.opacity(0.1))
                }
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
