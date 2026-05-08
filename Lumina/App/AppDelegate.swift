import OSLog
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "app.lumina.ios", category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // TODO(lumina): configure RevenueCat with LuminaRevenueCatAPIKeyIOS from Info.plist
        // TODO(lumina): configure OneSignal with LuminaOneSignalAppID from Info.plist
        // DECISION: per LEARNINGS.md, RevenueCat must be initialized here, not in LuminaApp.init,
        // to avoid SwiftUI Preview crashes.
        logger.info("Lumina launched")
        return true
    }
}
