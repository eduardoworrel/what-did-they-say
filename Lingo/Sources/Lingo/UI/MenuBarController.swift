import LingoCore
import AppKit
import SwiftUI
/// Owns the NSStatusItem and NSPopover for the Lingo menu bar icon.
@MainActor
final class MenuBarController {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let screenTranslator: ScreenTranslator
    private let screenStatusBadge = ScreenTranslationStatusBadge()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let engine = TranslationEngineProvider.shared.engine
        screenTranslator = ScreenTranslator(engine: engine)
    }

    // MARK: - Lifecycle

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            // Use an SF Symbol as the menu bar icon; replace with custom Asset when available
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Lingo")
            button.image?.isTemplate = true
            button.action = #selector(statusButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item

        buildPopover()
        observeScreenTranslator()
    }

    func tearDown() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
        popover = nil
    }

    // MARK: - Popover

    private func buildPopover() {
        let engine = TranslationEngineProvider.shared.engine
        let prefs = Preferences.shared
        let content = PopoverView(engine: engine, screenTranslator: screenTranslator, prefs: prefs)

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 360, height: 280)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(rootView: content)
        pop.animates = true
        self.popover = pop
    }

    func togglePopover() {
        guard let button = statusItem?.button else { return }
        if popover?.isShown == true {
            popover?.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate()
        }
    }

    // MARK: - Screen translator observation

    private func observeScreenTranslator() {
        screenTranslator.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.screenStatusBadge.show(state: state)
                self?.updateMenuBarIcon(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarIcon(for state: ScreenTranslationState) {
        guard let button = statusItem?.button else { return }
        switch state {
        case .showing:
            button.image = NSImage(systemSymbolName: "globe.badge.chevron.backward", accessibilityDescription: "Lingo — translating")
        default:
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Lingo")
        }
        button.image?.isTemplate = true
    }

    // MARK: - Menu

    @objc private func statusButtonClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let translateScreenItem = NSMenuItem(
            title: screenTranslator.isActive ? "Stop Screen Translation" : "Translate Screen  ⌘⇧S",
            action: #selector(toggleScreenTranslation),
            keyEquivalent: ""
        )
        translateScreenItem.target = self
        menu.addItem(translateScreenItem)

        menu.addItem(.separator())

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = Preferences.shared.launchAtLogin ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Lingo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func toggleScreenTranslation() {
        let target = Preferences.shared.targetLanguageId
        Task {
            await screenTranslator.toggle(targetLanguage: Locale.Language(identifier: target.isEmpty ? "en" : target))
        }
    }

    @objc private func toggleLaunchAtLogin() {
        Preferences.shared.launchAtLogin.toggle()
    }
}

import Combine
