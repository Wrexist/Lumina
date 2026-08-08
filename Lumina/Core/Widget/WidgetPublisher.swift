import Foundation
import WidgetKit

/// App-side writer for the home-screen widget. Distils a freshly-loaded natal
/// chart into the small shared `WidgetSnapshot` and nudges WidgetKit to reload.
/// Lives in the app target only — the widget extension reads, never writes.
///
/// Runtime data-sharing needs the App Group container, which only exists in a
/// properly-signed build (device / TestFlight). In the simulator or an
/// unsigned CI build `WidgetSharedStore` degrades to standard `UserDefaults`,
/// so this is a harmless no-op there rather than a crash.
enum WidgetPublisher {
    @MainActor
    static func publish(from chart: NatalChart) {
        // The widget is a Plus feature (README tier table), so a free user's
        // chart is not written to the shared container at all — the widget
        // shows its own locked copy instead of silently rendering paid
        // content on the home screen.
        guard PremiumGate.isUnlocked(.widget) else { return }

        let signature = CosmicSignatureMaker.make(from: chart)
        let snapshot = WidgetSnapshot(
            sunSign: signature.sunSign,
            moonSign: signature.moonSign,
            risingSign: signature.risingSign,
            headline: signature.headline
        )
        WidgetSharedStore.write(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Clears the shared snapshot — called when the entitlement lapses so a
    /// former subscriber's widget doesn't keep serving Plus content
    /// indefinitely.
    static func clear() {
        WidgetSharedStore.clear()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
