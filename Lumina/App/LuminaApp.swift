import SwiftData
import SwiftUI

@main
struct LuminaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Route local-notification taps into the deep-link pipeline
        // (`RootView.onOpenURL`). Installed here, before AppDelegate
        // initialises OneSignal, so the delegate is in place for the app's
        // first notification interaction.
        NotificationTapRouter.shared.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // Explicit container with a versioned schema + migration plan. The
        // `.modelContainer(for:)` convenience traps when the store can't be
        // opened; `LuminaModelContainer` degrades to an in-memory store
        // instead, so a bad store costs the user their local data rather
        // than the whole app. See `LuminaSchema.swift`.
        .modelContainer(LuminaModelContainer.shared)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                // Re-arm session-scoped gates (e.g. the Reflect Face ID lock) when
                // the app is backgrounded so the user must re-authenticate on
                // return — see docs/NAVIGATION.md §14.
                AppLock.shared.resetSessionUnlocks()
            case .active:
                // Keep scheduled notifications alive and current: transit
                // alerts are finite (capped per 30-day plan) so they must be
                // re-planned as they fire, and the daily reflection reminder
                // is re-asserted as a cheap safety net. Both no-op unless
                // enabled and permission is granted.
                TransitAlertsRefresher.shared.appDidBecomeActive()
                ReflectReminderScheduler.shared.reassertIfEnabled()
            default:
                break
            }
        }
    }
}
