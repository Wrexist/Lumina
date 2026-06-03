import SwiftData
import SwiftUI

@main
struct LuminaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [JournalEntry.self, Friend.self])
        .onChange(of: scenePhase) { _, phase in
            // Re-arm session-scoped gates (e.g. the Reflect Face ID lock) when
            // the app is backgrounded so the user must re-authenticate on
            // return — see docs/NAVIGATION.md §14.
            if phase == .background {
                AppLock.shared.resetSessionUnlocks()
            }
        }
    }
}
