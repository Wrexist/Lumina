import Foundation
import UIKit
import UserNotifications

/// The userInfo contract between Lumina's local-notification schedulers and
/// the tap router below: one string key carrying a `lumina://` URL that
/// `LuminaDeepLink` (the app's single URL parser) already understands.
enum NotificationDeepLink {
    static let userInfoKey = "luminaDeepLinkURL"
    /// `lumina://reflect` — lands on the Reflect tab (today's prompt).
    static let reflect = "lumina://reflect"

    /// Extracts the deep-link URL from a notification's userInfo, if any.
    static func url(from userInfo: [AnyHashable: Any]) -> URL? {
        guard let raw = userInfo[userInfoKey] as? String else { return nil }
        return URL(string: raw)
    }
}

/// Routes taps on Lumina's own local notifications into the app's single
/// deep-link pipeline: the tapped notification's userInfo URL is handed to
/// `UIApplication.open`, which re-enters through `RootView.onOpenURL` →
/// `LuminaDeepLink.from(url:)` → `AppRouter.handle(deepLink:)` — the exact
/// path every external `lumina://` link takes, so routing stays in one place.
///
/// Installed from `LuminaApp.init`, before `AppDelegate` initialises
/// OneSignal (whose SDK swizzles the center delegate and forwards to a
/// pre-existing one, so the two coexist). Notifications without our userInfo
/// key are ignored.
final class NotificationTapRouter: NSObject, UNUserNotificationCenterDelegate {
    @MainActor static let shared = NotificationTapRouter()

    /// `UNUserNotificationCenter.delegate` is weak; `shared` keeps us alive.
    @MainActor
    func install(center: UNUserNotificationCenter = .current()) {
        center.delegate = self
    }

    // Deliberately no `willPresent` implementation: foreground behaviour
    // stays exactly as before this delegate existed (no banner in-app).
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let url = NotificationDeepLink.url(
            from: response.notification.request.content.userInfo
        ) else { return }
        await MainActor.run {
            UIApplication.shared.open(url)
        }
    }
}
