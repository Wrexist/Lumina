import Foundation
import OSLog

/// Keeps the capped set of scheduled transit alerts alive and correct.
///
/// `TransitNotificationPlanner` deliberately schedules at most
/// `defaultLimit` notifications in a 30-day window, so without re-planning
/// the alerts silently run dry once the last one fires — the Settings toggle
/// was previously the only call site. This coordinator re-plans:
/// - on every app activation, debounced to at most once per 24 h via a
///   persisted timestamp (`AppPreferences.transitAlertsLastPlannedAt`), and
/// - immediately whenever the stored birth data changes
///   (`UserBirthDataStore.didChangeNotification`), so alerts planned for an
///   old chart never linger.
///
/// Both paths no-op unless the user opted in
/// (`AppPreferences.transitAlertsEnabled`) and notification permission is
/// granted. Uses `BirthChartViewModel.startLoad`'s newest-wins task idiom so
/// a birth-data re-plan can never lose to an in-flight stale one.
@MainActor
final class TransitAlertsRefresher {
    /// Why a refresh was requested — birth-data changes bypass the debounce.
    enum Trigger {
        case appActive
        case birthDataChanged
    }

    static let shared = TransitAlertsRefresher()

    /// Skip app-activation re-plans when the last successful plan is younger
    /// than this. Birth-data changes ignore it.
    private static let minimumReplanInterval: TimeInterval = 24 * 60 * 60

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Notifications")
    private let chartCache = ChartCache.shared
    private var refreshTask: Task<Void, Never>?
    private var birthDataObserver: (any NSObjectProtocol)?

    /// Called from `LuminaApp` whenever the scene becomes active: starts
    /// listening for birth-data changes (idempotent) and kicks a debounced
    /// re-plan.
    func appDidBecomeActive() {
        startObservingBirthData()
        refresh(trigger: .appActive)
    }

    /// Cancels any in-flight refresh before starting a new one, so the
    /// newest request always wins (the `BirthChartViewModel.startLoad`
    /// pattern).
    func refresh(trigger: Trigger) {
        refreshTask?.cancel()
        refreshTask = Task { await performRefresh(trigger: trigger) }
    }

    private func startObservingBirthData() {
        guard birthDataObserver == nil else { return }
        birthDataObserver = NotificationCenter.default.addObserver(
            forName: UserBirthDataStore.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Posted on the caller's thread; hop to the main actor ourselves
            // (see the notification's doc comment on UserBirthDataStore).
            Task { @MainActor in
                TransitAlertsRefresher.shared.refresh(trigger: .birthDataChanged)
            }
        }
    }

    private func performRefresh(trigger: Trigger) async {
        let preferences = AppPreferences.shared
        guard preferences.transitAlertsEnabled else { return }
        await NotificationPermission.shared.refreshStatus()
        guard NotificationPermission.shared.status.allowsScheduling, !Task.isCancelled else { return }
        if trigger == .appActive,
           let last = preferences.transitAlertsLastPlannedAt,
           Date.now.timeIntervalSince(last) < Self.minimumReplanInterval {
            return
        }
        guard let birth = UserBirthDataStore.userDefaults.load() else {
            // Birth data was cleared — drop the now-meaningless alerts.
            await TransitNotificationScheduler.shared.cancelAll()
            return
        }
        do {
            let forecast = try await chartCache.forecast(for: birth)
            guard !Task.isCancelled else { return }
            await TransitNotificationScheduler.shared.reschedule(TransitNotificationPlanner.plan(from: forecast))
            preferences.transitAlertsLastPlannedAt = .now
            logger.debug("transit alerts re-planned (\(String(describing: trigger), privacy: .public))")
        } catch {
            // Offline or a service hiccup — keep whatever is already
            // scheduled and try again on a later activation (the timestamp
            // stays untouched, so the debounce won't swallow the retry).
            logger.error("transit re-plan failed: \(error.localizedDescription)")
        }
    }
}
