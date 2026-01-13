import SwiftUI

struct CategoryBreakdownCard: View {
    let focusMetrics: FocusMetrics
    let totalSnapshots: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CATEGORY BREAKDOWN")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.claudeSecondaryAccent)
            
            HStack(spacing: 24) {
                // Ring Chart
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    // Category segments
                    CategoryRingSegment(
                        progress: focusMetrics.focusPercentage / 100,
                        color: .categoryCore
                    )
                    .frame(width: 100, height: 100)
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(focusMetrics.focusPercentage))%")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.claudeAccent)
                        Text("Focus")
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
                
                // Legend
                VStack(alignment: .leading, spacing: 12) {
                    CategoryLegendRow(label: "Core Tasks", color: .categoryCore, count: focusMetrics.coreCount, total: totalSnapshots)
                    CategoryLegendRow(label: "Personal", color: .categoryPersonal, count: focusMetrics.personalCount, total: totalSnapshots)
                    CategoryLegendRow(label: "Distractions", color: .categoryDistraction, count: focusMetrics.distractionCount, total: totalSnapshots)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Ring segment for category breakdown
struct CategoryRingSegment: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        Circle()
            .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
            .stroke(
                color,
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }
}

// Legend row with progress bar
struct CategoryLegendRow: View {
    let label: String
    let color: Color
    let count: Int
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) * 100 : 0
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Color.claudeTextPrimary)
                    Spacer()
                    Text("\(Int(percentage))%")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.claudeAccent)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(percentage) / 100)
                    }
                }
                .frame(height: 4)
            }
        }
    }
}
