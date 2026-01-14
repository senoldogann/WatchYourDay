import Foundation
import Vision
import CoreGraphics

actor OCRService {
    static let shared = OCRService()
    
    // Generic cache for the expensive request object
    private lazy var textRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "tr-TR"]
        return request
    }()
    
    func performOCR(on image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                // Use cached request
                 try handler.perform([textRecognitionRequest])
                 let request = textRecognitionRequest
                guard let observations = request.results else {
                    continuation.resume(returning: "")
                    return
                }
                
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
