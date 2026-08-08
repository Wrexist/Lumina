import OSLog
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "app.lumina.ios", category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // DECISION: per LEARNINGS.md, RevenueCat/OneSignal must be initialized here, not in
        // LuminaApp.init, to avoid SwiftUI Preview crashes. Both no-op safely when their
        // Info.plist key is empty/placeholder — see docs/CAPABILITIES-PLAN.md.
        let info = Bundle.main.infoDictionary ?? [:]

        // Subscribe to MetricKit first — iOS delivers the pending diagnostic
        // payload shortly after launch, so registering late means missing the
        // crash report from the previous session. Without this the app had no
        // crash reporting at all, and a post-launch crash would only ever
        // surface as an App Store review.
        CrashReporter.shared.start()

        let revenueCatKey = info["LuminaRevenueCatAPIKeyIOS"] as? String ?? ""
        Task {
            await IAPManager.shared.configure(apiKey: revenueCatKey)
        }

        let oneSignalAppID = info["LuminaOneSignalAppID"] as? String ?? ""
        PushNotificationManager.initialize(appID: oneSignalAppID, launchOptions: launchOptions)

        // Restore any previously-signed-in Sign in with Apple session (and
        // clear it if Apple reports the credential was revoked) before the
        // rest of the app reads `AuthManager.shared.session`.
        Task { @MainActor in
            await AuthManager.shared.restoreSessionIfAvailable()
        }

        logger.info("Lumina launched")
        return true
    }
}
