import Foundation
import SwiftData
import PDFKit
import SwiftUI

/// Handles exporting data to professional formats (PDF, CSV)
@MainActor
class ExportService {
    static let shared = ExportService()
    
    // MARK: - CSV Export
    
    func generateCSV(for snapshots: [Snapshot]) throws -> URL {
        var csvString = "Timestamp,App Name,Window Title,Category\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for snapshot in snapshots {
            let line = [
                dateFormatter.string(from: snapshot.timestamp),
                cleanCSV(snapshot.appName),
                cleanCSV(snapshot.windowTitle),
                snapshot.category
            ].joined(separator: ",")
            
            csvString.append(line + "\n")
        }
        
        let fileName = "WatchYourDay_Export_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
    
    private func cleanCSV(_ text: String) -> String {
        var cleaned = text.replacingOccurrences(of: "\"", with: "\"\"")
        if cleaned.contains(",") || cleaned.contains("\n") {
            cleaned = "\"\(cleaned)\""
        }
        return cleaned
    }
    
    // MARK: - PDF Export (Simple Report)
    
    func generatePDF(from report: DailyReport) -> URL? {
        let fileName = "WatchYourDay_Report_\(Date().timeIntervalSince1970).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Standard A4: 595 x 842 points
        var mediaBox = CGRect(x: 0, y: 0, width: 595, height: 842)
        
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            WDLogger.error("Failed to create PDF context", category: .general)
            return nil
        }
        
        context.beginPDFPage(nil)
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        
        // --- Fonts ---
        // Use Standard PDF Fonts to avoid encoding issues (The "!" artifact)
        let fontTitle = NSFont(name: "Helvetica-Bold", size: 24) ?? NSFont.boldSystemFont(ofSize: 24)
        let fontHeader = NSFont(name: "Helvetica-Bold", size: 14) ?? NSFont.boldSystemFont(ofSize: 14)
        let fontBody = NSFont(name: "Helvetica", size: 12) ?? NSFont.systemFont(ofSize: 12)
        let fontSmall = NSFont(name: "Helvetica", size: 10) ?? NSFont.systemFont(ofSize: 10)
        
        // --- Layout Constants ---
        let margin: CGFloat = 50
        let contentWidth = mediaBox.width - (margin * 2)
        var cursorY: CGFloat = mediaBox.height - margin - 40 // Start from top
        
        // Helper to draw text and advance cursor
        func drawText(_ text: String, font: NSFont, color: NSColor = .black, align: NSTextAlignment = .left, addY: CGFloat = 0) {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = align
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            
            let string = text as NSString
            let size = string.boundingRect(with: CGSize(width: contentWidth, height: .infinity), options: .usesLineFragmentOrigin, attributes: attrs).size
            
            let x = align == .center ? (mediaBox.width - size.width) / 2 : margin
            let rect = CGRect(x: x, y: cursorY - size.height, width: contentWidth, height: size.height)
            
            string.draw(in: rect, withAttributes: attrs)
            cursorY -= (size.height + 5 + addY)
        }
        
        // --- Drawing ---
        
        // 1. Header Line
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: margin, y: cursorY + 20))
        context.addLine(to: CGPoint(x: mediaBox.width - margin, y: cursorY + 20))
        context.strokePath()
        
        // 2. Title
        drawText("Daily Activity Report", font: fontTitle, align: .center, addY: 10)
        
        // 3. Date
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        drawText(formatter.string(from: report.date), font: fontBody, color: .darkGray, align: .center, addY: 30)
        
        // 4. Statistics Section
        drawText("Overview", font: fontHeader, addY: 5)
        drawText("Total Tracked Time: \(report.totalMinutes) minutes", font: fontBody)
        drawText("Focus Score: \(Int(report.focusPercentage))%", font: fontBody, addY: 20)
        
        // 5. AI Summary Section
        if !report.summary.isEmpty {
            drawText("AI Analysis", font: fontHeader, addY: 5)
            // Handle multi-line summary
            let summaryRect = CGRect(x: margin, y: cursorY - 150, width: contentWidth, height: 150)
            // For simple text wrapping in CoreGraphics/NSString, draw(in:) works best if rect is tall enough.
            // But we need to calculate height dynamically to be "perfect".
            // For MVP, let's just dump it in a box.
            
            let pStyle = NSMutableParagraphStyle()
            pStyle.alignment = .justified
            let summaryAttrs: [NSAttributedString.Key: Any] = [
                .font: fontBody,
                .foregroundColor: NSColor.black,
                .paragraphStyle: pStyle
            ]
            
            let summaryHeight = (report.summary as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: 300),
                options: .usesLineFragmentOrigin,
                attributes: summaryAttrs
            ).height
            
            (report.summary as NSString).draw(in: CGRect(x: margin, y: cursorY - summaryHeight, width: contentWidth, height: summaryHeight), withAttributes: summaryAttrs)
            cursorY -= (summaryHeight + 30)
        }
        
        // 6. Top Apps
        drawText("Top Applications", font: fontHeader, addY: 5)
        
        for (index, app) in report.topApps.prefix(10).enumerated() {
            drawText("\(index + 1). \(app)", font: fontBody)
        }
        
        // Footer line
        context.setStrokeColor(NSColor.lightGray.cgColor)
        context.move(to: CGPoint(x: margin, y: 50))
        context.addLine(to: CGPoint(x: mediaBox.width - margin, y: 50))
        context.strokePath()
        
        drawText("Generated by WatchYourDay", font: fontSmall, color: .gray, align: .center)
        
        // --- End ---
        
        NSGraphicsContext.restoreGraphicsState()
        context.endPDFPage()
        context.closePDF()
        
        return url
    }
    // MARK: - Markdown Export (Developer/GitHub Friendly)
    
    func generateMarkdown(from report: DailyReport) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        let dateString = dateFormatter.string(from: report.date)
        
        var md = """
        # Daily Activity Report
        **Date**: \(dateString)
        
        ## Overview
        - **Total Tracked Time**: \(report.totalMinutes) minutes
        - **Focus Score**: \(Int(report.focusPercentage))%
        
        ## AI Analysis
        > \(report.summary.replacingOccurrences(of: "\n", with: "\n> "))
        
        ## Top Applications
        """
        
        for (index, app) in report.topApps.prefix(10).enumerated() {
            md.append("\n\(index + 1). **\(app)**")
        }
        
        md.append("\n\n---\n*Generated by WatchYourDay*")
        
        let fileName = "WatchYourDay_Report_\(Date().timeIntervalSince1970).md"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try md.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            WDLogger.error("Failed to write Markdown file: \(error)", category: .general)
            return nil
        }
    }
}

// Minimal Helper extension for Zip in Swift 5 (if needed, but zip calls above were pseudo-code)
extension Sequence {
    func zip<Other: Sequence>(_ other: Other) -> Zip2Sequence<Self, Other> {
        return Swift.zip(self, other)
    }
}
