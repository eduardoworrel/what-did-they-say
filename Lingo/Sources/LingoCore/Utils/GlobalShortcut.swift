import AppKit
import Carbon.HIToolbox

/// Registers system-wide keyboard shortcuts using Carbon's RegisterEventHotKey API.
/// Does not require Accessibility permission for basic hotkey registration.
public final class GlobalShortcut {

    public typealias Handler = () -> Void

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let handler: Handler
    private let id: UInt32

    // Shared registry so the EventHandler can dispatch to the right shortcut
    private static var registry: [UInt32: GlobalShortcut] = [:]
    private static var nextId: UInt32 = 1

    public init(keyCode: UInt32, modifiers: UInt32, handler: @escaping Handler) {
        self.id = GlobalShortcut.nextId
        self.handler = handler
        GlobalShortcut.nextId += 1

        GlobalShortcut.registry[id] = self
        register(keyCode: keyCode, modifiers: modifiers)
    }

    deinit {
        unregister()
        GlobalShortcut.registry.removeValue(forKey: id)
    }

    // MARK: - Registration

    private func register(keyCode: UInt32, modifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: fourCharCode("LNGO"), id: id)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if eventHandlerRef == nil {
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, event, _ -> OSStatus in
                    var hotKeyID = EventHotKeyID()
                    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                      nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                    GlobalShortcut.registry[hotKeyID.id]?.handler()
                    return noErr
                },
                1, &eventSpec, nil as UnsafeMutableRawPointer?, &eventHandlerRef
            )
        }
    }

    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    // MARK: - Convenience factory

    /// ⌘⇧T — toggle text translation popover
    public static func makePopoverShortcut(handler: @escaping Handler) -> GlobalShortcut {
        GlobalShortcut(
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(cmdKey | shiftKey),
            handler: handler
        )
    }

    /// ⌘⇧S — toggle screen translation
    public static func makeScreenShortcut(handler: @escaping Handler) -> GlobalShortcut {
        GlobalShortcut(
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(cmdKey | shiftKey),
            handler: handler
        )
    }
}

// MARK: - Helpers

private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for char in string.utf8.prefix(4) {
        result = (result << 8) + OSType(char)
    }
    return result
}
