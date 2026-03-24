import Foundation
import Vision
import AppKit

/// Detected text region on screen with bounding box and recognized text.
struct TextRegion {
    let text: String
    let boundingBox: CGRect  // Normalized coordinates (0–1, origin bottom-left from Vision)
    let screenRect: CGRect   // Pixel coordinates in screen space (origin top-left)
    let confidence: Float
}

/// Uses Vision framework to detect and recognize text in a CGImage.
final class TextRegionDetector {

    /// Detects all text regions in `image` (screen pixels).
    /// `imageSize` is the pixel size of the image for coordinate conversion.
    func detectText(in image: CGImage, imageSize: CGSize) async throws -> [TextRegion] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let regions = observations.compactMap { obs -> TextRegion? in
                    guard let candidate = obs.topCandidates(1).first,
                          candidate.confidence > 0.3,
                          !candidate.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    else { return nil }

                    // Vision uses normalized coords with origin at bottom-left.
                    // Convert to screen coords with origin at top-left.
                    let normBox = obs.boundingBox
                    let screenRect = CGRect(
                        x: normBox.minX * imageSize.width,
                        y: (1.0 - normBox.maxY) * imageSize.height,
                        width: normBox.width * imageSize.width,
                        height: normBox.height * imageSize.height
                    )

                    return TextRegion(
                        text: candidate.string,
                        boundingBox: normBox,
                        screenRect: screenRect,
                        confidence: candidate.confidence
                    )
                }
                continuation.resume(returning: regions)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en", "es", "fr", "de", "pt", "it", "zh-Hans", "zh-Hant", "ja", "ko", "ru", "ar"]
            request.revision = VNRecognizeTextRequestRevision3

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
