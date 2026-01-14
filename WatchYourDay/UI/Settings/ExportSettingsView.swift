import SwiftUI
import SwiftData

struct ExportSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(Color.claudeAccent)
                Text("EXPORT")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.claudeSecondaryAccent)
            }
            
            HStack(spacing: 12) {
                Button(action: exportPDF) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("Export PDF")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.claudeAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                
                Button(action: exportMarkdown) {
                    HStack {
                        Image(systemName: "doc.plaintext")
                        Text("Export MD")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.claudeAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .onHover { h in if h { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
            }
        }
        .padding()
        .background(Color.claudeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func exportPDF() {
        Task {
            if let report = await ReportManager.shared.generatePeriodicReport(force: true) {
                 if let url = ExportService.shared.generatePDF(from: report) {
                     NSWorkspace.shared.open(url)
                 }
            }
        }
    }
    
    private func exportMarkdown() {
        Task {
            if let report = await ReportManager.shared.generatePeriodicReport(force: true) {
                 if let url = ExportService.shared.generateMarkdown(from: report) {
                     NSWorkspace.shared.open(url)
                 }
            }
        }
    }
}
