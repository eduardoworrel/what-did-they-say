import AppKit
import SwiftUI

/// A floating overlay window that appears briefly to show a text translation result.
/// Used when the user triggers translation via keyboard shortcut on selected text.
final class TranslationResultOverlay {

    private var window: NSPanel?
    private var dismissTimer: Timer?

    func show(originalText: String, translatedText: String, near point: NSPoint) {
        dismiss()

        let view = ResultView(original: originalText, translated: translatedText) { [weak self] in
            self?.dismiss()
        }
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(origin: .zero, size: hosting.fittingSize)

        let panel = NSPanel(
            contentRect: NSRect(origin: point, size: hosting.frame.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.contentView = hosting

        // Position near cursor, keep on screen
        if let screen = NSScreen.main {
            var origin = point
            origin.x = min(origin.x, screen.visibleFrame.maxX - hosting.frame.width - 8)
            origin.y = max(origin.y - hosting.frame.height - 8, screen.visibleFrame.minY + 8)
            panel.setFrameOrigin(origin)
        }

        panel.orderFront(nil)
        window = panel

        // Auto-dismiss after 5 seconds
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        window?.orderOut(nil)
        window = nil
    }
}

// MARK: - SwiftUI Result Card

private struct ResultView: View {
    let original: String
    let translated: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(translated)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .textSelection(.enabled)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            Text(original)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 320, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .darkGray).opacity(0.95))
                .shadow(radius: 8)
        )
        .padding(4)
    }
}
