import SwiftUI
import AppKit
import Carbon.HIToolbox
import WhatDidTheySayCore

/// A SwiftUI wrapper around an NSView that captures a key combination for use
/// as a global shortcut. Click the field, then press the desired combination.
/// Press Escape to cancel without saving.
struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var record: ShortcutRecord

    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let v = HotkeyRecorderNSView()
        v.onRecord = { r in record = r }
        return v
    }

    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        if !nsView.isRecording {
            nsView.currentRecord = record
            nsView.needsDisplay = true
        }
    }
}

// MARK: - NSView

final class HotkeyRecorderNSView: NSView {
    var onRecord: ((ShortcutRecord) -> Void)?
    var currentRecord: ShortcutRecord = .defaultPopover

    private(set) var isRecording = false {
        didSet { needsDisplay = true }
    }

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 90, height: 24) }

    // MARK: - Input

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        // Escape — cancel without saving
        if event.keyCode == UInt16(kVK_Escape) {
            isRecording = false
            window?.makeFirstResponder(nil)
            return
        }

        // Require at least one modifier key
        let relevant = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard !relevant.isEmpty else { return }

        // Convert NSEvent modifiers → Carbon modifiers
        var carbonMods: UInt32 = 0
        if relevant.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if relevant.contains(.shift)   { carbonMods |= UInt32(shiftKey) }
        if relevant.contains(.option)  { carbonMods |= UInt32(optionKey) }
        if relevant.contains(.control) { carbonMods |= UInt32(controlKey) }

        // Build display string: ⌃⌥⇧⌘ order (standard macOS)
        let modStr = (relevant.contains(.control) ? "⌃" : "")
                   + (relevant.contains(.option)  ? "⌥" : "")
                   + (relevant.contains(.shift)   ? "⇧" : "")
                   + (relevant.contains(.command) ? "⌘" : "")
        let keyChar = event.characters?.uppercased() ?? "?"

        let rec = ShortcutRecord(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbonMods,
            displayString: modStr + keyChar
        )
        onRecord?(rec)
        currentRecord = rec
        isRecording = false
        window?.makeFirstResponder(nil)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return super.resignFirstResponder()
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let bg: NSColor = isRecording ? NSColor.selectedTextBackgroundColor.withAlphaComponent(0.15)
                                      : NSColor.controlBackgroundColor
        bg.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4).fill()

        let border: NSColor = isRecording ? NSColor.controlAccentColor : NSColor.separatorColor
        border.setStroke()
        let border_path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4)
        border_path.lineWidth = 1
        border_path.stroke()

        let text  = isRecording ? "Type shortcut…" : currentRecord.displayString
        let color: NSColor = isRecording ? NSColor.controlAccentColor : NSColor.labelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let sz  = str.size()
        str.draw(at: NSPoint(x: (bounds.width - sz.width) / 2,
                             y: (bounds.height - sz.height) / 2))
    }
}
