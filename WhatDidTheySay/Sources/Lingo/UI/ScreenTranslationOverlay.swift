import AppKit
import SwiftUI

/// A translucent status badge shown during screen translation.
/// Sits in the top-right corner of the screen to indicate translation progress/state.
final class ScreenTranslationStatusBadge {

    private var window: NSPanel?

    @MainActor
    func show(state: ScreenTranslationState) {
        let view = StatusBadgeView(state: state)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(origin: .zero, size: CGSize(width: 200, height: 44))

        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: hosting.frame.size),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = hosting
            window = panel
        } else {
            window?.contentView = hosting
        }

        positionBadge()
        window?.orderFront(nil)

        // Auto-hide after idle
        if case .idle = state { hide() }
        if case .error = state {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.hide()
            }
        }
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
    }

    private func positionBadge() {
        guard let screen = NSScreen.main, let w = window else { return }
        let margin: CGFloat = 16
        let x = screen.visibleFrame.maxX - w.frame.width - margin
        let y = screen.visibleFrame.maxY - w.frame.height - margin
        w.setFrameOrigin(CGPoint(x: x, y: y))
    }
}

// MARK: - SwiftUI badge view

private struct StatusBadgeView: View {
    let state: ScreenTranslationState

    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(background.opacity(0.92))
                .shadow(radius: 4)
        )
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .capturing, .detecting:
            ProgressView().controlSize(.mini).tint(.white)
        case .translating(let progress):
            ProgressView(value: progress)
                .progressViewStyle(.circular)
                .controlSize(.mini)
                .tint(.white)
        case .showing:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
        case .idle:
            EmptyView()
        }
    }

    private var label: String {
        switch state {
        case .idle: return ""
        case .capturing: return "Capturing screen…"
        case .detecting: return "Detecting text…"
        case .translating(let p): return "Translating \(Int(p * 100))%"
        case .showing: return "Translation shown"
        case .error(let msg): return msg
        }
    }

    private var background: Color {
        switch state {
        case .error: return .red
        default: return Color(nsColor: .darkGray)
        }
    }
}
