import AppKit
import SwiftUI

/// A single translated text overlay floating above the screen.
final class TextOverlayWindow: NSPanel {

    private let label: NSTextField

    init(translatedText: String, screenRect: CGRect) {
        label = NSTextField(labelWithString: translatedText)

        super.init(
            contentRect: screenRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        backgroundColor = NSColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.85)
        isOpaque = false
        hasShadow = true
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 4
        container.layer?.masksToBounds = true
        contentView = container

        label.font = .systemFont(ofSize: max(11, screenRect.height * 0.35), weight: .medium)
        label.textColor = .white
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = screenRect.width - 8
        label.maximumNumberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
        ])
    }
}

/// Manages a set of overlay windows for one screen translation session.
@MainActor
final class TextOverlayRenderer {

    private var overlayWindows: [TextOverlayWindow] = []

    /// Shows translated overlays on `screen` for each region.
    /// Caller is responsible for calling `dismissOverlays()` before this when replacing overlays.
    func showOverlays(_ translatedRegions: [(region: TextRegion, translation: String)], on screen: NSScreen) {
        for (region, translation) in translatedRegions {
            guard !translation.isEmpty else { continue }

            let screenRect = regionToScreenRect(region.screenRect, on: screen)
            let window = TextOverlayWindow(translatedText: translation, screenRect: screenRect)
            window.orderFront(nil)
            overlayWindows.append(window)
        }
    }

    func dismissOverlays() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
    }

    // MARK: - Coordinate helpers

    private func regionToScreenRect(_ imageRect: CGRect, on screen: NSScreen) -> CGRect {
        // Image coordinates: origin top-left, pixel space.
        // AppKit screen coordinates: origin bottom-left of global screen space.
        let scale = screen.backingScaleFactor
        let frame = screen.frame

        let x = frame.minX + imageRect.minX / scale
        let y = frame.minY + frame.height - imageRect.maxY / scale  // flip Y within screen
        let w = imageRect.width / scale
        let h = imageRect.height / scale

        return CGRect(x: x, y: y, width: w, height: h)
    }
}
