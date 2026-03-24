import WhatDidTheySayCore
import SwiftUI

/// The main menu bar popover — shows hotkey configuration and screen translation controls.
struct PopoverView: View {

    @State private var sourceLanguage = Language.auto
    @State private var targetLanguage = Language.all.first(where: { $0.id == "en" }) ?? Language.all[0]

    @ObservedObject var screenTranslator: ScreenTranslator
    @ObservedObject var prefs: Preferences

    init(screenTranslator: ScreenTranslator, prefs: Preferences) {
        self.screenTranslator = screenTranslator
        self.prefs = prefs
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            shortcutsSection
            Divider()
            languageRow
            Divider()
            launchAtLoginRow
        }
        .frame(width: 360)
        .onAppear {
            if let src = Language.all.first(where: { $0.id == prefs.sourceLanguageId }) {
                sourceLanguage = src
            } else {
                sourceLanguage = Language.auto
            }
            if let dst = Language.all.first(where: { $0.id == prefs.targetLanguageId }) {
                targetLanguage = dst
            }
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            Text("What Did They Say")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button {
                Task {
                    await screenTranslator.toggle(targetLanguage: targetLanguage.locale)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: screenTranslator.isActive ? "stop.fill" : "camera.viewfinder")
                        .font(.system(size: 12))
                    Text(screenTranslator.isActive ? "Stop" : "Screen")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(screenTranslator.isActive ? .red : .accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KEYBOARD SHORTCUTS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            shortcutRow(
                label: "Hover Translate",
                hint: "Toggle hover-to-translate",
                record: $prefs.popoverShortcut
            )

            shortcutRow(
                label: "Screen Translate",
                hint: "Translate everything on screen",
                record: $prefs.screenShortcut
            )
        }
        .padding(.bottom, 12)
    }

    private func shortcutRow(label: String, hint: String, record: Binding<ShortcutRecord>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13))
                Text(hint)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            HotkeyRecorderView(record: record)
                .frame(width: 90, height: 26)
                .help("Click and press a key combination")
        }
        .padding(.horizontal, 12)
    }

    private var languageRow: some View {
        HStack {
            Text("Language")
                .font(.system(size: 13))
            Spacer()
            LanguageButton(label: "From", selection: $sourceLanguage,
                           languages: [Language.auto] + Language.all)
            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            LanguageButton(label: "To", selection: $targetLanguage,
                           languages: Language.all)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .onChange(of: sourceLanguage) { _, new in prefs.sourceLanguageId = new.id }
        .onChange(of: targetLanguage) { _, new in prefs.targetLanguageId = new.id }
    }

    private var launchAtLoginRow: some View {
        HStack {
            Text("Launch at Login")
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: $prefs.launchAtLogin)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
