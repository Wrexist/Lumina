import Foundation
import OSLog
import UserNotifications

/// Centralised notification-permission helper. Per `ROADMAP.md` Phase 11
/// and `docs/NAVIGATION.md` §14, we never ask on first launch — we ask
/// after the user has seen real value (the first daily reading, the first
/// chart). This wrapper gives the rest of the app one place to check
/// status and request authorisation, plus a small "pre-prompt" hook so
/// callers can show a contextual `LuminaCard` before the system sheet.
@MainActor
@Observable
final class NotificationPermission {
    enum Status: String, Sendable {
        case notDetermined
        case granted
        case denied
        case provisional
        case ephemeral
    }

    static let shared = NotificationPermission()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Notifications")
    private let center: UNUserNotificationCenter

    private(set) var status: Status = .notDetermined

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    private static func map(_ raw: UNAuthorizationStatus) -> Status {
        switch raw {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .granted
        case .provisional: .provisional
        case .ephemeral: .ephemeral
        @unknown default: .notDetermined
        }
    }

    /// Refreshes `status` from the system. Safe to call on every appear.
    func refreshStatus() async {
        let settings = await center.notificationSettings()
        status = Self.map(settings.authorizationStatus)
        logger.debug("notification status: \(self.status.rawValue, privacy: .public)")
    }

    /// Prompts the system permission sheet. Returns the resulting status
    /// so callers can branch (e.g. show a "Settings → Notifications" hint
    /// if denied). This is the only call site that triggers the OS sheet.
    ///
    /// When `PushNotificationManager` has been configured (a real OneSignal
    /// app ID), the prompt is routed through OneSignal's own permission API
    /// so a push token registers as part of the same system prompt — never
    /// two competing prompts. Dev/CI builds with no OneSignal app ID fall
    /// through to the direct `UNUserNotificationCenter` path unchanged.
    @discardableResult
    func request() async -> Status {
        guard PushNotificationManager.isAvailable else {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                status = granted ? .granted : .denied
                return status
            } catch {
                logger.error("notification authorisation failed: \(error.localizedDescription)")
                status = .denied
                return status
            }
        }
        _ = await PushNotificationManager.requestPermission()
        await refreshStatus()
        return status
    }
}
