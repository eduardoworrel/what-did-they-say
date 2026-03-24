import Foundation
import AppKit
import ScreenCaptureKit

/// Manages ScreenCaptureKit permission and one-shot screen captures.
@MainActor
final class ScreenCaptureManager {

    enum CaptureError: Error, LocalizedError {
        case permissionDenied
        case noDisplayFound
        case captureFailed(String)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Screen Recording permission is required. Enable it in System Settings → Privacy & Security → Screen Recording."
            case .noDisplayFound:
                return "No display found to capture"
            case .captureFailed(let reason):
                return "Screen capture failed: \(reason)"
            }
        }
    }

    // MARK: - Permission

    static func requestPermission() {
        // Accessing shareable content triggers the permission prompt on first launch.
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            } catch {
                // User may have denied — they'll see a prompt from the system.
            }
        }
    }

    static func hasPermission() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Capture

    /// Captures the entire main display and returns a CGImage.
    func captureMainDisplay() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard let display = content.displays.first else {
            throw CaptureError.noDisplayFound
        }

        return try await captureDisplay(display)
    }

    /// Captures all connected displays, returning (image, screen) pairs.
    func captureAllDisplays() async throws -> [(CGImage, NSScreen)] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

        guard !content.displays.isEmpty else {
            throw CaptureError.noDisplayFound
        }

        var results: [(CGImage, NSScreen)] = []
        for display in content.displays {
            let nsScreen = NSScreen.screens.first(where: {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID) == display.displayID
            }) ?? NSScreen.main ?? NSScreen.screens[0]

            let image = try await captureDisplay(display)
            results.append((image, nsScreen))
        }
        return results
    }

    // MARK: - Private

    private func captureDisplay(_ display: SCDisplay) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.captureResolution = .best
        config.showsCursor = false

        return try await withCheckedThrowingContinuation { continuation in
            let stream = SCStream(filter: filter, configuration: config, delegate: nil)
            let output = SingleFrameOutput { result in
                switch result {
                case .success(let image):
                    continuation.resume(returning: image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            do {
                try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .global())
                Task {
                    do {
                        try await stream.startCapture()
                        // Give it a moment to capture a frame
                        try await Task.sleep(for: .milliseconds(100))
                        try await stream.stopCapture()
                    } catch {
                        continuation.resume(throwing: CaptureError.captureFailed(error.localizedDescription))
                    }
                }
            } catch {
                continuation.resume(throwing: CaptureError.captureFailed(error.localizedDescription))
            }
        }
    }
}

// MARK: - SCStreamOutput helper

private final class SingleFrameOutput: NSObject, SCStreamOutput {
    private let completion: (Result<CGImage, Error>) -> Void
    private var captured = false

    init(completion: @escaping (Result<CGImage, Error>) -> Void) {
        self.completion = completion
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, !captured else { return }
        captured = true

        guard
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            completion(.failure(ScreenCaptureManager.CaptureError.captureFailed("No image buffer")))
            return
        }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            completion(.failure(ScreenCaptureManager.CaptureError.captureFailed("Could not create CGImage")))
            return
        }
        completion(.success(cgImage))
    }
}
