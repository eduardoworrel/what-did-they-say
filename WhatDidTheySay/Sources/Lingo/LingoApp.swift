import SwiftUI

@main
struct LingoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Lingo is a menu bar app — no main window.
        // Use Settings scene to allow Xcode's SwiftUI previews to work.
        Settings {
            EmptyView()
        }
    }
}
