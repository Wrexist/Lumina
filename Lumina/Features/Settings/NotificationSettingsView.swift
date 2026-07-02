import SwiftUI
import UIKit

/// Drilled-into screen from `SettingsView` → "Notifications".
///
/// Reflects the live status from `NotificationPermission`. If the user is
/// `.notDetermined`, the primary CTA triggers the system sheet. If they
/// previously denied, the CTA opens iOS Settings → Lumina so they can
/// flip the master toggle. We never re-prompt with the system sheet —
/// Apple won't show it twice anyway.
struct NotificationSettingsView: View {
    @State private var permission = NotificationPermission.shared
    @State private var preferences = AppPreferences.shared
    @State private var ephemeris = EphemerisService()
    @State private var alertsError: String?
    @State private var alertsTask: Task<Void, Never>?
    @State private var reflectError: String?
    @State private var reflectTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                statusCard
                primaryAction
                quietHoursPlaceholder
                transitAlertsCard
                reflectReminderCard
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await permission.refreshStatus() }
    }

    private var statusCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    Image(systemName: statusIcon)
                        .foregroundStyle(LuminaColors.celestialBlue)
                    Text(statusTitle)
                        .font(LuminaTypography.heading)
                }
                Text(statusBody)
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch permission.status {
        case .notDetermined:
            LuminaButton(title: "Turn on notifications", variant: .primary) {
                Task { await permission.request() }
            }
        case .denied:
            LuminaButton(title: "Open iOS Settings", variant: .secondary) {
                openSystemSettings()
            }
        case .granted, .provisional, .ephemeral:
            LuminaButton(title: "All set — manage in iOS Settings", variant: .ghost) {
                openSystemSettings()
            }
        }
    }

    private var quietHoursPlaceholder: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack {
                    Text("Quiet hours")
                        .font(LuminaTypography.body)
                    Spacer()
                    LuminaBadge(title: "Soon", tone: .neutral)
                }
                Text("Default 9pm–7am. Custom quiet hours are coming soon.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private var transitAlertsCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Toggle(isOn: transitAlertsBinding) {
                    VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                        Text("Transit alerts")
                            .font(LuminaTypography.body)
                        Text("A gentle heads-up the morning of each meaningful transit. On-device, opt-in, and capped at \(TransitNotificationPlanner.defaultLimit) — never doom, never spam.")
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
                .tint(LuminaColors.celestialBlue)
                if let alertsError {
                    Text(alertsError)
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.error)
                }
            }
        }
    }

    private var statusIcon: String {
        switch permission.status {
        case .granted, .provisional, .ephemeral: "bell.badge"
        case .denied: "bell.slash"
        case .notDetermined: "bell"
        }
    }

    private var statusTitle: String {
        switch permission.status {
        case .granted: "Notifications on"
        case .provisional: "Quiet delivery"
        case .ephemeral: "App-clip session"
        case .denied: "Notifications off"
        case .notDetermined: "Not yet decided"
        }
    }

    private var statusBody: String {
        switch permission.status {
        case .granted:
            return "You'll get tomorrow morning's reading delivered between 7:30–9:00 AM local."
        case .provisional:
            return "Notifications arrive quietly without sound or banner."
        case .ephemeral:
            return "Limited to this app-clip session."
        case .denied:
            return "Lumina can't send pushes until you flip the switch in iOS Settings."
        case .notDetermined:
            return "Turn on notifications and we'll wake you with tomorrow's reading."
        }
    }

    private var transitAlertsBinding: Binding<Bool> {
        Binding(
            get: { preferences.transitAlertsEnabled },
            set: { newValue in
                preferences.transitAlertsEnabled = newValue
                // Newest toggle wins: cancel the in-flight apply so a stale
                // reschedule can't land after a later cancelAll (the
                // `BirthChartViewModel.startLoad` idiom).
                alertsTask?.cancel()
                alertsTask = Task { await applyTransitAlerts(enabled: newValue) }
            }
        )
    }

    /// Turning on: ensure permission, then fetch the forecast and schedule a
    /// capped set of on-device alerts. Turning off: cancel ours. Any blocker
    /// (denied permission, no birth data, offline) reverts the toggle and shows
    /// a plain reason rather than silently doing nothing.
    private func applyTransitAlerts(enabled: Bool) async {
        alertsError = nil
        guard enabled else {
            if !Task.isCancelled {
                await TransitNotificationScheduler.shared.cancelAll()
            }
            return
        }
        var status = permission.status
        if status == .notDetermined {
            status = await permission.request()
        }
        guard !Task.isCancelled else { return }
        guard status.allowsScheduling else {
            preferences.transitAlertsEnabled = false
            alertsError = "Turn on notifications above first, then enable transit alerts."
            return
        }
        guard let birth = UserBirthDataStore.userDefaults.load() else {
            preferences.transitAlertsEnabled = false
            alertsError = "Add your birth info in Settings first, then turn this on."
            return
        }
        do {
            let forecast = try await ephemeris.forecast(for: birth)
            guard !Task.isCancelled else { return }
            await TransitNotificationScheduler.shared.reschedule(TransitNotificationPlanner.plan(from: forecast))
            preferences.transitAlertsLastPlannedAt = .now
        } catch {
            guard !Task.isCancelled else { return }
            preferences.transitAlertsEnabled = false
            alertsError = "Couldn't reach the sky just now. Try again in a moment."
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Daily reflection reminder

private extension NotificationSettingsView {
    var reflectReminderCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Toggle(isOn: reflectReminderBinding) {
                    VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                        Text("Daily reflection")
                            .font(LuminaTypography.body)
                        Text("One quiet evening nudge when the day's reflection prompt is ready. No streaks, no guilt — skip whenever you like.")
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
                .tint(LuminaColors.celestialBlue)
                if preferences.reflectReminderEnabled {
                    DatePicker(
                        "Remind me at",
                        selection: reflectTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .font(LuminaTypography.body)
                }
                if let reflectError {
                    Text(reflectError)
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.error)
                }
            }
        }
    }

    var reflectReminderBinding: Binding<Bool> {
        Binding(
            get: { preferences.reflectReminderEnabled },
            set: { newValue in
                preferences.reflectReminderEnabled = newValue
                // Same newest-toggle-wins pattern as the transit toggle.
                reflectTask?.cancel()
                reflectTask = Task { await applyReflectReminder(enabled: newValue) }
            }
        )
    }

    /// The stored hour/minute surfaced as a `Date` for the compact picker;
    /// only the hour and minute components round-trip.
    var reflectTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: preferences.reflectReminderHour,
                    minute: preferences.reflectReminderMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                preferences.reflectReminderHour = components.hour ?? 21
                preferences.reflectReminderMinute = components.minute ?? 0
                reflectTask?.cancel()
                reflectTask = Task { await applyReflectReminder(enabled: true) }
            }
        )
    }

    /// Same gating flow as transit alerts: request permission on first
    /// enable; when denied, revert with a plain reason (the status card up
    /// top already offers the "Open iOS Settings" path).
    func applyReflectReminder(enabled: Bool) async {
        reflectError = nil
        guard enabled else {
            ReflectReminderScheduler.shared.cancel()
            return
        }
        var status = permission.status
        if status == .notDetermined {
            status = await permission.request()
        }
        guard !Task.isCancelled else { return }
        guard status.allowsScheduling else {
            preferences.reflectReminderEnabled = false
            reflectError = "Turn on notifications above first, then enable the daily reminder."
            return
        }
        await ReflectReminderScheduler.shared.reschedule(
            hour: preferences.reflectReminderHour,
            minute: preferences.reflectReminderMinute
        )
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
