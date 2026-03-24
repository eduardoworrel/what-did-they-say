import WhatDidTheySayCore
import SwiftUI

/// Settings panel shown inside the menu bar popover.
/// Covers keyboard shortcut customisation and launch-at-login.
struct SettingsView: View {
    @ObservedObject var prefs: Preferences
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            shortcutsSection
            Divider()
            launchAtLoginRow
            Spacer()
        }
        .frame(width: 360)
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack(spacing: 6) {
            Button {
                showSettings = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)

            Text("Settings")
                .font(.system(size: 13, weight: .semibold))

            Spacer()
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
