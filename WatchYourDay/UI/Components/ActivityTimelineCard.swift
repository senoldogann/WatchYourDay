import SwiftUI

struct ActivityTimelineCard: View {
    let snapshots: [Snapshot]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("HOURLY ACTIVITY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
                
                Spacer()
                
                Text("\(snapshots.count) snapshots")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            
            let hourlyData = calculateHourlyActivity()
            let maxCount = hourlyData.map { $0.count }.max() ?? 1
            
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(hourlyData, id: \.hour) { data in
                    VStack(spacing: 6) {
                        // Bar with gradient
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                data.count > 0 ?
                                LinearGradient(
                                    colors: [Color.claudeAccent, Color.claudeSecondaryAccent],
                                    startPoint: .bottom,
                                    endPoint: .top
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.15)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(4, CGFloat(data.count) / CGFloat(max(maxCount, 1)) * 60))
                        
                        // Hour label (show every 2 hours)
                        if data.hour % 2 == 0 {
                            Text("\(data.hour)")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.gray)
                        } else {
                            Text("")
                                .font(.system(size: 9))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 85)
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func calculateHourlyActivity() -> [(hour: Int, count: Int)] {
        var hourly: [Int: Int] = [:]
        for i in 6..<24 { hourly[i] = 0 }
        
        for snapshot in snapshots {
            let hour = Calendar.current.component(.hour, from: snapshot.timestamp)
            hourly[hour, default: 0] += 1
        }
        
        return hourly.sorted { $0.key < $1.key }.map { (hour: $0.key, count: min($0.value, 30)) }
    }
}
