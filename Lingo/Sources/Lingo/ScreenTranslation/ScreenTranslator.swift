import Foundation
import AppKit

enum ScreenTranslationState {
    case idle
    case capturing
    case detecting
    case translating(progress: Double)
    case showing
    case error(String)
}

/// Orchestrates: screen capture → OCR → translation → overlay display.
@MainActor
final class ScreenTranslator: ObservableObject {

    @Published var state: ScreenTranslationState = .idle
    @Published var regionCount: Int = 0

    private let captureManager = ScreenCaptureManager()
    private let detector = TextRegionDetector()
    private let overlayRenderer = TextOverlayRenderer()
    private var translationEngine: any TranslationEngine

    init(engine: any TranslationEngine) {
        self.translationEngine = engine
    }

    var isActive: Bool {
        if case .showing = state { return true }
        return false
    }

    // MARK: - Public

    func toggle(targetLanguage: Locale.Language) async {
        if isActive {
            stop()
        } else {
            await start(targetLanguage: targetLanguage)
        }
    }

    func stop() {
        overlayRenderer.dismissOverlays()
        state = .idle
        regionCount = 0
    }

    // MARK: - Private

    private func start(targetLanguage: Locale.Language) async {
        guard await ScreenCaptureManager.hasPermission() else {
            state = .error(ScreenCaptureManager.CaptureError.permissionDenied.localizedDescription)
            showPermissionAlert()
            return
        }

        do {
            state = .capturing
            let image = try await captureManager.captureMainDisplay()

            state = .detecting
            let imageSize = CGSize(width: image.width, height: image.height)
            let regions = try await detector.detectText(in: image, imageSize: imageSize)

            guard !regions.isEmpty else {
                state = .idle
                return
            }

            state = .translating(progress: 0)
            var translated: [(region: TextRegion, translation: String)] = []

            for (index, region) in regions.enumerated() {
                let progress = Double(index) / Double(regions.count)
                state = .translating(progress: progress)

                do {
                    // Auto-detect source — translate to target
                    let result = try await translationEngine.translate(
                        region.text,
                        from: .init(identifier: ""),  // empty = auto-detect
                        to: targetLanguage
                    )
                    translated.append((region: region, translation: result))
                } catch {
                    // Skip regions that fail to translate
                }
            }

            overlayRenderer.showOverlays(translated)
            regionCount = translated.count
            state = .showing

            // Auto-dismiss after 8 seconds
            Task {
                try? await Task.sleep(for: .seconds(8))
                if case .showing = state {
                    stop()
                }
            }

        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Lingo needs Screen Recording permission to translate on-screen text.\n\nOpen System Settings → Privacy & Security → Screen Recording and enable Lingo."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
