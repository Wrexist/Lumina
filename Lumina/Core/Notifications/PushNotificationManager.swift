import Foundation
import OneSignalFramework
import OSLog
import UIKit

/// Thin wrapper around the OneSignal SDK — the one place in the codebase
/// that touches `OneSignalFramework` directly. Mirrors the dev-safe
/// "no-op when config is missing" pattern used by `EphemerisService` and
/// `IAPManager`: every entry point guards on a real, non-placeholder
/// `LuminaOneSignalAppID` and silently no-ops otherwise, so CI/simulator
/// builds (and any build before the OneSignal app is provisioned) still
/// boot cleanly.
///
/// `AppDelegate.application(_:didFinishLaunchingWithOptions:)` calls
/// `initialize(appID:launchOptions:)` once, before
/// `NotificationPermission` ever requests the system prompt — see
/// `LEARNINGS.md` "OneSignal initialization". This type does **not**
/// request the system permission sheet itself; `NotificationPermission`
/// remains the single call site for that (see its doc comment), routing
/// through `requestPermission()` below when OneSignal is configured so
/// there is exactly one prompt, not two.
///
/// Segmentation (`ROADMAP.md` Phase 11 — premium / free / lapsed /
/// cohort-by-motivation) and the "Broadcast Capability" (OneSignal-console
/// APNs channel pushes) both key off OneSignal tags applied via `setTag`.
@MainActor
enum PushNotificationManager {
    /// A `.env.example` / CI placeholder — never a real OneSignal app ID.
    /// Treat it the same as an empty string.
    private static let placeholderAppID = "YOUR-UUID-HERE"

    private static let logger = Logger(subsystem: "app.lumina.ios", category: "PushNotifications")

    /// Set once `initialize` has run with a real app ID. Every other method
    /// guards on this so calling them before `initialize`, or with no
    /// configured app ID, is a harmless no-op rather than a crash.
    private static var isConfigured = false

    /// Whether OneSignal has been configured with a real app ID. Callers
    /// like `NotificationPermission.request()` check this *before* calling
    /// `requestPermission()` so they can branch on "OneSignal isn't set up,
    /// fall back to the direct system API" vs. "OneSignal is set up and the
    /// user simply denied" — the latter must never trigger a second prompt.
    static var isAvailable: Bool { isConfigured }

    /// Configures the OneSignal SDK. Safe to call with an empty or
    /// placeholder `appID` (dev/CI builds before the OneSignal app exists)
    /// — logs and returns without touching the SDK.
    ///
    /// Must be called before any notification-permission prompt is shown
    /// (`LEARNINGS.md` "OneSignal initialization") so OneSignal can attach
    /// its own push-token registration to the same system prompt.
    static func initialize(appID: String, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard !appID.isEmpty, appID != placeholderAppID else {
            logger.info("OneSignal app ID missing/placeholder — skipping initialization")
            return
        }

        // NOTE: double-check this against the actual OneSignal-XCFramework v5
        // API once it resolves in CI's package cache. `OneSignal.initialize`
        // is the documented v5 static entry point, but the exact launch
        // options parameter (label/type) has drifted across 5.x point
        // releases in OneSignal's own migration notes — verify the signature
        // compiles as-is before trusting this call site.
        OneSignal.initialize(appID, withLaunchOptions: launchOptions)
        isConfigured = true
        logger.info("OneSignal initialized")
    }

    /// Requests the system notification-permission prompt through OneSignal
    /// so a push token registers as part of the same authorization the user
    /// grants. `NotificationPermission.request()` is the only caller —
    /// routing through here (instead of `UNUserNotificationCenter` directly)
    /// keeps it to exactly one prompt when OneSignal is configured.
    ///
    /// Returns `false` without prompting if OneSignal hasn't been
    /// initialized (dev/CI builds).
    static func requestPermission() async -> Bool {
        guard isConfigured else {
            logger.debug("requestPermission called before OneSignal was configured — no-op")
            return false
        }

        // NOTE: double-check this against the actual SDK. `OneSignal.Notifications
        // .requestPermission(_:fallbackToSettings:)` is the documented v5 shape;
        // some 5.x releases expose it as a completion-handler API rather than
        // `async`, in which case this call site needs a
        // `withCheckedContinuation` bridge instead of a direct `await`.
        let granted = await OneSignal.Notifications.requestPermission(true)
        logger.debug("OneSignal permission request result: \(granted, privacy: .public)")
        return granted
    }

    /// Tags the current OneSignal user/subscription for segmentation
    /// (premium / free / lapsed / cohort-by-motivation per `ROADMAP.md`
    /// Phase 11, plus ad hoc tags like the palm-scanning waitlist). No-ops
    /// if OneSignal isn't configured.
    static func setTag(key: String, value: String) {
        guard isConfigured else {
            logger.debug("setTag(\(key, privacy: .public)) called before OneSignal was configured — no-op")
            return
        }

        // NOTE: double-check this against the actual SDK. `OneSignal.User
        // .addTag(key:value:)` is the documented v5 shape for the
        // "new" User Model API; older 5.x betas used
        // `OneSignal.User.addTags([:])` (plural, dictionary-based) instead.
        OneSignal.User.addTag(key: key, value: value)
        logger.debug("tagged \(key, privacy: .public)")
    }
}
