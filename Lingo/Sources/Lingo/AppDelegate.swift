import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController?
    private var popoverShortcut: GlobalShortcut?
    private var screenShortcut: GlobalShortcut?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only — hide from Dock and app switcher
        NSApp.setActivationPolicy(.accessory)

        // Warm up translation engine
        _ = TranslationEngineProvider.shared

        // Set up menu bar status item
        menuBarController = MenuBarController()
        menuBarController?.setup()

        // Register global shortcuts
        registerShortcuts()

        // Prompt for Screen Recording permission upfront (non-blocking)
        ScreenCaptureManager.requestPermission()

        // Observe model download notifications to inform user
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelDownloadRequired(_:)),
            name: .modelDownloadRequired,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        popoverShortcut = nil
        screenShortcut = nil
        menuBarController?.tearDown()
    }

    // MARK: - Shortcuts

    private func registerShortcuts() {
        popoverShortcut = GlobalShortcut.makePopoverShortcut { [weak self] in
            DispatchQueue.main.async {
                self?.menuBarController?.togglePopover()
            }
        }

        screenShortcut = GlobalShortcut.makeScreenShortcut { [weak self] in
            guard let self, let _ = self.menuBarController else { return }
            Task { @MainActor in
                let lang = Preferences.shared.targetLanguageId
                let locale = Locale.Language(identifier: lang.isEmpty ? "en" : lang)
                NotificationCenter.default.post(name: .toggleScreenTranslation, object: locale)
            }
        }
    }

    // MARK: - Notifications

    @objc private func modelDownloadRequired(_ notification: Notification) {
        guard let displayName = notification.userInfo?["displayName"] as? String else { return }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "NLLB Offline Engine Available"
            alert.informativeText = "\(displayName) can be downloaded for fully offline translation. Would you like to download it now?"
            alert.addButton(withTitle: "Not Now")
            alert.addButton(withTitle: "Download")
            alert.alertStyle = .informational
            // For v1.0 we just inform; actual download UI is future work
            _ = alert.runModal()
        }
    }
}

extension Notification.Name {
    static let toggleScreenTranslation = Notification.Name("LingoToggleScreenTranslation")
}
