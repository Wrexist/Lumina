import Foundation
import OSLog
import UserNotifications

/// Schedules local, on-device transit notifications via
/// `UNUserNotificationCenter` — no OneSignal, no server push (the deliberate
/// anti-Co-Star stance: honest, on-device, opt-in, capped). Every Lumina
/// transit notification shares an id prefix so we can cancel and re-schedule
/// our own without touching any other notifications.
@MainActor
final class TransitNotificationScheduler {
    static let shared = TransitNotificationScheduler()

    private static let idPrefix = "lumina.transit."
    private let logger = Logger(subsystem: "app.lumina.ios", category: "Notifications")
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Cancel-then-add: replaces all previously-scheduled Lumina transit
    /// notifications with `planned`, so re-running is idempotent.
    func reschedule(_ planned: [PlannedTransitNotification]) async {
        await cancelAll()
        for item in planned {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: item.fireDateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.idPrefix + item.id,
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
            } catch {
                logger.error("failed to schedule \(item.id, privacy: .public): \(error.localizedDescription)")
            }
        }
        logger.debug("scheduled \(planned.count) transit notifications")
    }

    /// Cancels every pending Lumina transit notification, leaving any others
    /// (e.g. a future daily-reading reminder) untouched.
    func cancelAll() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
