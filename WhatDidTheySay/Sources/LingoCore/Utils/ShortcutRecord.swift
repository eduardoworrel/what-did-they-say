import Carbon.HIToolbox

/// A serialisable record of a global keyboard shortcut.
public struct ShortcutRecord: Codable, Equatable, Sendable {
    public var keyCode: UInt32
    public var carbonModifiers: UInt32
    /// Human-readable label built at record time, e.g. "⌘⇧T".
    public var displayString: String

    public init(keyCode: UInt32, carbonModifiers: UInt32, displayString: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.displayString = displayString
    }

    /// ⌘⇧T — hover-to-translate toggle
    public static let defaultPopover = ShortcutRecord(
        keyCode: UInt32(kVK_ANSI_T),
        carbonModifiers: UInt32(cmdKey | shiftKey),
        displayString: "⌘⇧T"
    )

    /// ⌘⇧S — screen translation toggle
    public static let defaultScreen = ShortcutRecord(
        keyCode: UInt32(kVK_ANSI_S),
        carbonModifiers: UInt32(cmdKey | shiftKey),
        displayString: "⌘⇧S"
    )
}
