import SwiftUI

@main
struct WhatDidTheySayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // WhatDidTheySay is a menu bar app — no main window.
        // Use Settings scene to allow Xcode's SwiftUI previews to work.
        Settings {
            EmptyView()
        }
    }
}
