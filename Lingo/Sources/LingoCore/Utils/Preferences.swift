import Foundation
import ServiceManagement
import AppKit

/// App-wide user preferences backed by UserDefaults.
@MainActor
public final class Preferences: ObservableObject {
    public static let shared = Preferences()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Key {
        static let sourceLanguageId = "sourceLanguageId"
        static let targetLanguageId = "targetLanguageId"
        static let launchAtLogin    = "launchAtLogin"
        static let popoverShortcut  = "popoverShortcut"
        static let screenShortcut   = "screenShortcut"
    }

    // MARK: - Properties

    @Published public var sourceLanguageId: String {
        didSet { defaults.set(sourceLanguageId, forKey: Key.sourceLanguageId) }
    }

    @Published public var targetLanguageId: String {
        didSet { defaults.set(targetLanguageId, forKey: Key.targetLanguageId) }
    }

    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
            applyLaunchAtLogin(launchAtLogin)
        }
    }

    @Published public var popoverShortcut: ShortcutRecord {
        didSet {
            if let data = try? JSONEncoder().encode(popoverShortcut) {
                defaults.set(data, forKey: Key.popoverShortcut)
            }
        }
    }

    @Published public var screenShortcut: ShortcutRecord {
        didSet {
            if let data = try? JSONEncoder().encode(screenShortcut) {
                defaults.set(data, forKey: Key.screenShortcut)
            }
        }
    }

    // MARK: - Init

    private init() {
        sourceLanguageId = defaults.string(forKey: Key.sourceLanguageId) ?? ""
        targetLanguageId = defaults.string(forKey: Key.targetLanguageId) ?? "en"
        launchAtLogin    = defaults.bool(forKey: Key.launchAtLogin)

        if let data = defaults.data(forKey: Key.popoverShortcut),
           let rec  = try? JSONDecoder().decode(ShortcutRecord.self, from: data) {
            popoverShortcut = rec
        } else {
            popoverShortcut = .defaultPopover
        }

        if let data = defaults.data(forKey: Key.screenShortcut),
           let rec  = try? JSONDecoder().decode(ShortcutRecord.self, from: data) {
            screenShortcut = rec
        } else {
            screenShortcut = .defaultScreen
        }
    }

    // MARK: - Launch at Login

    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Log but don't crash — user can always set this in Login Items manually
                NSLog("What Did They Say: launch-at-login error: \(error.localizedDescription)")
            }
        }
    }
}
