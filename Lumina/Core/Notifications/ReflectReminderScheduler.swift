import Foundation
import OSLog
import UserNotifications

/// Schedules the single daily "reflection prompt is ready" local
/// notification — the journal's retention nudge, done the Lumina way: one
/// honest reminder at a user-chosen hour, no streaks, no guilt (the same
/// tone contract `PlannedTransitNotification` holds itself to). One stable
/// identifier means re-scheduling always replaces the previous
/// registration, so there is never more than one pending reminder.
@MainActor
final class ReflectReminderScheduler {
    static let shared = ReflectReminderScheduler()

    /// Stable id: `UNUserNotificationCenter.add` replaces any pending
    /// request with the same identifier. Deliberately outside the transit
    /// prefix (`lumina.transit.`) so `TransitNotificationScheduler.cancelAll()`
    /// never sweeps it up.
    static let identifier = "lumina.reflect.reminder"
    static let title = "A quiet minute"
    static let body = "Tonight's reflection prompt is ready when you are."

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Notifications")
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// The repeating trigger's match components — hour and minute only, so
    /// the system fires it every day at that local time. Pure and
    /// unit-testable; adding any date field would stop the daily repeat.
    nonisolated static func triggerComponents(hour: Int, minute: Int) -> DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }

    /// Registers (or replaces) the daily reminder at the given local time.
    /// Tapping it deep-links to the Reflect tab via `NotificationTapRouter`.
    func reschedule(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = Self.title
        content.body = Self.body
        content.sound = .default
        content.userInfo = [NotificationDeepLink.userInfoKey: NotificationDeepLink.reflect]
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Self.triggerComponents(hour: hour, minute: minute),
            repeats: true
        )
        let request = UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger)
        do {
            try await center.add(request)
            logger.debug("scheduled daily reflection reminder for \(hour):\(minute)")
        } catch {
            logger.error("failed to schedule reflection reminder: \(error.localizedDescription)")
        }
    }

    /// Removes the pending reminder (Settings toggle off).
    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    }

    /// Safety re-assert on app activation: calendar triggers repeat on their
    /// own, so this only re-registers in case the pending request was lost.
    /// No-ops unless the reminder is enabled and permission allows it.
    func reassertIfEnabled() {
        let preferences = AppPreferences.shared
        guard preferences.reflectReminderEnabled else { return }
        Task {
            await NotificationPermission.shared.refreshStatus()
            guard NotificationPermission.shared.status.allowsScheduling else { return }
            await reschedule(hour: preferences.reflectReminderHour, minute: preferences.reflectReminderMinute)
        }
    }
}
