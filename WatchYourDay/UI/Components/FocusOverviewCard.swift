import SwiftUI

struct FocusOverviewCard: View {
    let focusMetrics: FocusMetrics
    let totalTimeFormatted: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Total Time
            StatBox(
                title: "TOTAL TIME",
                value: totalTimeFormatted,
                icon: "clock.fill",
                color: Color.claudeAccent
            )
            
            // Focus Rate
            StatBox(
                title: "FOCUS RATE",
                value: "\(Int(focusMetrics.focusPercentage))%",
                icon: "target",
                color: Color.categoryCore
            )
            
            // Distractions
            StatBox(
                title: "DISTRACTIONS",
                value: "\(focusMetrics.distractionCount)",
                icon: "exclamationmark.triangle.fill",
                color: Color.categoryDistraction
            )
        }
    }
}
