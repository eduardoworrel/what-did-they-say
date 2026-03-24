import WhatDidTheySayCore
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
            let captures = try await captureManager.captureAllDisplays()

            state = .detecting
            var allRegions: [(region: TextRegion, screen: NSScreen)] = []
            for (image, screen) in captures {
                let imageSize = CGSize(width: image.width, height: image.height)
                let regions = try await detector.detectText(in: image, imageSize: imageSize)
                for region in regions {
                    allRegions.append((region: region, screen: screen))
                }
            }

            guard !allRegions.isEmpty else {
                state = .idle
                return
            }

            state = .translating(progress: 0)
            var translated: [(region: TextRegion, translation: String, screen: NSScreen)] = []

            for (index, item) in allRegions.enumerated() {
                let progress = Double(index) / Double(allRegions.count)
                state = .translating(progress: progress)

                do {
                    let result = try await translationEngine.translate(
                        item.region.text,
                        from: .init(identifier: ""),  // empty = auto-detect
                        to: targetLanguage
                    )
                    translated.append((region: item.region, translation: result, screen: item.screen))
                } catch {
                    // Skip regions that fail to translate
                }
            }

            overlayRenderer.dismissOverlays()
            // Group by screen and show overlays on each
            let byScreen = Dictionary(grouping: translated, by: { ObjectIdentifier($0.screen) })
            for (_, items) in byScreen {
                guard let screen = items.first?.screen else { continue }
                let pairs = items.map { (region: $0.region, translation: $0.translation) }
                overlayRenderer.showOverlays(pairs, on: screen)
            }

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
        alert.informativeText = "What Did They Say needs Screen Recording permission to translate on-screen text.\n\nOpen System Settings → Privacy & Security → Screen Recording and enable What Did They Say."
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
