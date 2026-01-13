import Foundation
import ScreenCaptureKit
import CoreGraphics
import VideoToolbox
import Vision
import AppKit
import SwiftData

@Observable
class ScreenCaptureService: NSObject {
    static let shared = ScreenCaptureService()
    
    var isRecording = false
    var hasPermission = false
    
    // Store active streams
    private var streams: [StreamContext] = []
    
    // Global Config
    private let frameInterval: CMTime = CMTime(value: 1, timescale: 1)
    private let videoSampleBufferQueue = DispatchQueue(label: "com.watchyourday.ScreenCaptureService.VideoQueue")
    
    override init() {
        super.init()
        Task { @MainActor in checkPermission() }
    }
    
    // MARK: - Permission Check
    @MainActor
    func checkPermission() {
        self.hasPermission = CGPreflightScreenCaptureAccess()
        WDLogger.info("Screen Capture Permission: \(self.hasPermission)", category: .screenCapture)
    }
    
    @MainActor
    func requestPermission() {
        let stream = CGRequestScreenCaptureAccess()
        if stream {
            self.hasPermission = true
            WDLogger.info("Permission granted", category: .screenCapture)
        } else {
             WDLogger.info("Permission denied", category: .screenCapture)
        }
    }
    
    // MARK: - Start/Stop
    func startCapture() async {
        guard !isRecording else { return }
        
        do {
            let content = try await SCShareableContent.current
            let displays = content.displays
            
            guard !displays.isEmpty else {
                WDLogger.error("No displays found", category: .screenCapture)
                return
            }
            
            WDLogger.info("Found \(displays.count) displays", category: .screenCapture)
            
            // Clear old streams
            streams.removeAll()
            
            for (index, display) in displays.enumerated() {
                do {
                    let filter = SCContentFilter(display: display, excludingWindows: [])
                    
                    let config = SCStreamConfiguration()
                    config.width = display.width
                    config.height = display.height
                    config.minimumFrameInterval = frameInterval
                    config.showsCursor = true
                    config.queueDepth = 5
                    
                    // Create context for this display
                    let stream = SCStream(filter: filter, configuration: config, delegate: nil)
                    let context = StreamContext(
                        stream: stream,
                        displayID: index,
                        queue: videoSampleBufferQueue
                    )
                    
                    // Set delegate to the CONTEXT, not self
                    try stream.addStreamOutput(context, type: .screen, sampleHandlerQueue: videoSampleBufferQueue)
                    
                    try await stream.startCapture()
                    streams.append(context)
                    
                    WDLogger.info("Started capture for Display \(index)", category: .screenCapture)
                } catch {
                    WDLogger.error("Failed to start display \(index): \(error)", category: .screenCapture)
                }
            }
            
            guard !streams.isEmpty else {
                WDLogger.error("Failed to start any streams", category: .screenCapture)
                return
            }
            
            await MainActor.run { isRecording = true }
            ReportManager.shared.startReporting()
            
        } catch {
            WDLogger.error("Failed to get content: \(error.localizedDescription)", category: .screenCapture)
        }
    }
    
    func stopCapture() async {
        guard isRecording else { return }
        
        for context in streams {
            do {
                try await context.stream.stopCapture()
            } catch {
                WDLogger.error("Error stopping stream \(context.displayID): \(error)", category: .screenCapture)
            }
        }
        
        streams.removeAll()
        
        await MainActor.run { isRecording = false }
        WDLogger.info("All screens capture stopped", category: .screenCapture)
        
        ReportManager.shared.stopReporting()
    }
}

// MARK: - Stream Context (Per Display Handler)
class StreamContext: NSObject, SCStreamOutput {
    let stream: SCStream
    let displayID: Int
    private let queue: DispatchQueue
    
    // Deduplication state
    private var lastFeaturePrint: VNFeaturePrintObservation?
    private var lastCaptureTime: Date?
    private var lastOCRTime: Date?
    
    private let similarityThreshold: Float = 0.1
    // OCR Optimization: Only run expensive OCR every 10 seconds unless a major screen change occurs
    private let ocrInterval: TimeInterval = 10.0
    private let forceOCRThreshold: Float = 0.5
    
    init(stream: SCStream, displayID: Int, queue: DispatchQueue) {
        self.stream = stream
        self.displayID = displayID
        self.queue = queue
        super.init()
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        let now = Date()
        // Software throttle (1 FPS per screen)
        if let last = lastCaptureTime, now.timeIntervalSince(last) < 1.0 {
            return
        }
        lastCaptureTime = now
        
        processFrame(sampleBuffer)
    }
    
    private func processFrame(_ buffer: CMSampleBuffer) {
        guard let cvPixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
            guard let result = request.results?.first as? VNFeaturePrintObservation else { return }
            
            var shouldSave = false
            var shouldRunOCR = false
            
            if let last = lastFeaturePrint {
                var distance: Float = 0
                try result.computeDistance(&distance, to: last)
                
                if distance > similarityThreshold {
                    WDLogger.debug("Display \(displayID) Changed (Distance: \(distance))", category: .screenCapture)
                    shouldSave = true
                    
                    // Smart OCR Trigger
                    let timeSinceLastOCR = Date().timeIntervalSince(lastOCRTime ?? Date.distantPast)
                    if distance > forceOCRThreshold {
                        shouldRunOCR = true // Major context switch, force OCR
                    } else if timeSinceLastOCR >= ocrInterval {
                        shouldRunOCR = true // Time to re-scan text
                    }
                }
            } else {
                shouldSave = true
                shouldRunOCR = true
            }
            
            if shouldSave {
                lastFeaturePrint = result
                if shouldRunOCR {
                     lastOCRTime = Date()
                }
                saveFrame(cvPixelBuffer, runOCR: shouldRunOCR)
            }
            
        } catch {
            WDLogger.error("Vision error: \(error)", category: .screenCapture)
        }
    }
    
    private func saveFrame(_ buffer: CVPixelBuffer, runOCR: Bool) {
        // 1. Identify App Early (Optimization: Don't process blacklisted apps)
        // Note: This relies on Global Frontmost App. Per-screen window detection is more complex.
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let appName = frontmostApp?.localizedName ?? "Unknown"
        
        if BlacklistManager.shared.isBlacklisted(appName: appName) {
            WDLogger.debug("Privacy: Skipping capture for blacklisted app '\(appName)'", category: .screenCapture)
            return
        }
        
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(buffer, options: nil, imageOut: &cgImage)
        
        guard let originalImage = cgImage else { return }
        
        Task {
            do {
                // Privacy: Redact sensitive content (PII) before saving
                let redactedImage = try await Redactor.redactSensitiveContent(in: originalImage)
                
                let now = Date()
                let path = try await ImageStorageManager.shared.saveImage(redactedImage, timestamp: now)
                
                var ocrText = ""
                if runOCR {
                    // Use redacted image for OCR too, to avoid storing sensitive text in DB
                    ocrText = try await OCRService.shared.performOCR(on: redactedImage)
                }
                
                // Heavy lifting (CGWindowList) runs in background now
                let windowTitle = WindowHelper.getFrontmostWindowTitle(for: frontmostApp) ?? ""
                
                // Categorize is pure logic, safe to run here
                let categoryObj = CategoryService.shared.categorize(appName: appName, windowTitle: windowTitle)
                let category = categoryObj.rawValue
                
                await MainActor.run {
                    let container = PersistenceController.shared.container
                    let context = container.mainContext
                    // Save with DisplayID
                    let snapshot = Snapshot(
                        timestamp: now,
                        imagePath: path,
                        ocrText: ocrText,
                        appName: appName,
                        windowTitle: windowTitle,
                        category: category,
                        displayID: self.displayID
                    )
                    context.insert(snapshot)
                }
            } catch {
                WDLogger.error("Failed to save snapshot for display \(self.displayID): \(error)", category: .persistence)
            }
        }
    }
}

// MARK: - Privacy Redaction
struct Redactor {
    static func redactSensitiveContent(in cgImage: CGImage) async throws -> CGImage {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results else { return cgImage }
        
        // Define Sensitive Patterns
        // 1. Credit Card (Luhn-like 16 digits) -> Simple regex for now: \b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b
        // 2. IBAN (TR starting) -> \bTR\d{2}[ ]\d{4}\b
        // 3. Keywords: "Password", "Parola", "Şifre"
        
        let sensitivePatterns = [
            #"\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b"#, // Credit Card formatting
            #"\bTR\d{2}[ ]?\d{4}[ ]?\d{4}[ ]?\d{4}[ ]?\d{2}\b"#, // TR IBAN
            #"(?i)password"#,
            #"(?i)parola"#,
            #"(?i)şifre"#,
            #"(?i)api key"#,
            #"(?i)bearer"#,
            #"(?i)secret"#,
            #"(?i)private key"#
        ]
        
        var rectsToRedact: [CGRect] = []
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string
            
            for pattern in sensitivePatterns {
                if text.range(of: pattern, options: .regularExpression) != nil {
                    // Found PII! Convert normalized Vision coords to Image coords
                    // Vision origin is Bottom-Left, CGImage/UIKit is usually Top-Left, but CoreGraphics extraction depends.
                    // Improving robustness: Blur the whole bounding box of the line.
                    
                    do {
                        if let box = try candidate.boundingBox(for: text.startIndex..<text.endIndex) {
                            let rect = box.boundingBox
                            // Convert normalized
                            let pixelRect = CGRect(
                                x: rect.origin.x * width,
                                y: rect.origin.y * height,
                                width: rect.width * width,
                                height: rect.height * height
                            )
                            rectsToRedact.append(pixelRect)
                        }
                    } catch {
                        WDLogger.error("Failed to calculate bounding box for sensitive content: \(error)", category: .ocr)
                    }
                }
            }
        }
        
        guard !rectsToRedact.isEmpty else { return cgImage }
        
        // Draw Redaction (Blur/Black box)
        let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        
        guard let ctx = context else { return cgImage }
        
        // Draw original
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Draw Redactions
        // Using CIAccumulator or just drawing black boxes for speed/safety.
        // Blurring requires CoreImage context switch. For MVP, Black/Pixelated Box is safer and clearly indicates "Redacted".
        
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)) // Black
        
        for rect in rectsToRedact {
            // Inflate rect slightly to cover edges
            let inflated = rect.insetBy(dx: -4, dy: -4)
            ctx.fill(inflated)
        }
        
        guard let newImage = ctx.makeImage() else { return cgImage }
        return newImage
    }
}

// MARK: - Window Helper Extraction
struct WindowHelper {
    // Removed @MainActor to allow background execution
    static func getFrontmostWindowTitle(for app: NSRunningApplication?) -> String? {
        guard let app = app else { return nil }
        
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        for window in windowList {
            guard let windowPID = window[kCGWindowOwnerPID as String] as? pid_t,
                  windowPID == app.processIdentifier,
                  let windowName = window[kCGWindowName as String] as? String,
                  !windowName.isEmpty else {
                continue
            }
            return windowName
        }
        return nil
    }
}
