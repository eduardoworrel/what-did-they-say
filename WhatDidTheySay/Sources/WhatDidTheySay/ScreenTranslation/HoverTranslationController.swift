import WhatDidTheySayCore
import Foundation
import AppKit

/// Monitors cursor position globally. When the cursor dwells for ~500ms, captures a small
/// region around it, runs OCR, translates the detected text, and shows a `TextOverlayWindow`
/// placed directly over the original text — not a floating popup card.
@MainActor
final class HoverTranslationController {

    private var mouseMonitor: Any?
    private var dwellTimer: Timer?
    private var overlayWindow: TextOverlayWindow?
    private var isTranslating = false

    private let captureManager = ScreenCaptureManager()
    private let detector = TextRegionDetector()

    // MARK: - Public

    var isActive: Bool { mouseMonitor != nil }

    func start() {
        guard mouseMonitor == nil else { return }

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            // NSEvent global monitors are called on the main thread.
            self.onMouseMoved(to: NSEvent.mouseLocation)
        }
    }

    func stop() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        cancelDwell()
        dismissOverlay()
    }

    func toggle() {
        if isActive { stop() } else { start() }
    }

    // MARK: - Dwell detection

    private func onMouseMoved(to position: NSPoint) {
        // Reset dwell on every move — translation fires 500ms after cursor stops.
        cancelDwell()
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.performHoverTranslation(at: position)
            }
        }
    }

    private func cancelDwell() {
        dwellTimer?.invalidate()
        dwellTimer = nil
    }

    // MARK: - Translation

    private func performHoverTranslation(at cursorPoint: NSPoint) async {
        // Skip if a translation is already in-flight (keeps latency predictable).
        guard !isTranslating else { return }
        isTranslating = true
        defer { isTranslating = false }

        // Identify the screen that contains the cursor.
        let screen = NSScreen.screens.first(where: { NSMouseInRect(cursorPoint, $0.frame, false) })
                     ?? NSScreen.main!

        do {
            let fullImage = try await captureManager.captureScreen(screen)
            let scale = screen.backingScaleFactor
            let frame  = screen.frame   // AppKit coords: origin bottom-left

            // Convert cursor (AppKit: y-up) → image pixel coords (y-down).
            let localX = (cursorPoint.x - frame.minX) * scale
            let localY = (frame.maxY    - cursorPoint.y) * scale

            // Crop ~300×80 pt around the cursor (in pixels).
            let halfW = 150.0 * scale
            let halfH =  40.0 * scale
            let cropX = max(0, localX - halfW)
            let cropY = max(0, localY - halfH)
            let cropW = min(300.0 * scale, CGFloat(fullImage.width)  - cropX)
            let cropH = min( 80.0 * scale, CGFloat(fullImage.height) - cropY)
            let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)

            guard let cropped = fullImage.cropping(to: cropRect) else { return }

            // OCR the cropped region.
            let imageSize = CGSize(width: cropped.width, height: cropped.height)
            let regions = try await detector.detectText(in: cropped, imageSize: imageSize)
            guard !regions.isEmpty else { return }

            // Pick the text region whose midpoint is closest to the cursor.
            let cursorInCrop = CGPoint(x: localX - cropRect.minX, y: localY - cropRect.minY)
            let best = regions.min(by: {
                midpointDistance(cursorInCrop, $0.screenRect) < midpointDistance(cursorInCrop, $1.screenRect)
            })!

            // Translate.
            let lang   = Preferences.shared.targetLanguageId
            let locale = Locale.Language(identifier: lang.isEmpty ? "en" : lang)
            let translation = try await TranslationEngineProvider.shared.engine.translate(
                best.text,
                from: .init(identifier: ""),   // empty = auto-detect
                to: locale
            )

            // Convert detected region (crop-image pixel space, y-down) back to AppKit screen coords.
            let absPixelX    = best.screenRect.minX + cropRect.minX
            let absPixelMaxY = best.screenRect.maxY + cropRect.minY  // px from image top

            let overlayRect = CGRect(
                x: frame.minX + absPixelX    / scale,
                y: frame.minY + CGFloat(fullImage.height) / scale - absPixelMaxY / scale,
                width:  best.screenRect.width  / scale,
                height: best.screenRect.height / scale
            )

            showOverlay(translation: translation, screenRect: overlayRect)

        } catch {
            // Silently drop hover translation errors — don't disrupt the user.
        }
    }

    private func midpointDistance(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
        let dx = point.x - rect.midX
        let dy = point.y - rect.midY
        return sqrt(dx * dx + dy * dy)
    }

    // MARK: - Overlay

    private func showOverlay(translation: String, screenRect: CGRect) {
        dismissOverlay()
        let window = TextOverlayWindow(translatedText: translation, screenRect: screenRect)
        window.orderFront(nil)
        overlayWindow = window

        // Auto-dismiss after 3 seconds.
        Task {
            try? await Task.sleep(for: .seconds(3))
            if self.overlayWindow === window {
                self.dismissOverlay()
            }
        }
    }

    private func dismissOverlay() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}
