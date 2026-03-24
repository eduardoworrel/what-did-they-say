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
        static let globalShortcut   = "globalShortcut"
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

    // MARK: - Init

    private init() {
        sourceLanguageId = defaults.string(forKey: Key.sourceLanguageId) ?? ""
        targetLanguageId = defaults.string(forKey: Key.targetLanguageId) ?? "en"
        launchAtLogin    = defaults.bool(forKey: Key.launchAtLogin)
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
