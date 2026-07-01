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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                statusCard
                primaryAction
                quietHoursPlaceholder
                transitAlertsCard
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
                Task { await applyTransitAlerts(enabled: newValue) }
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
            await TransitNotificationScheduler.shared.cancelAll()
            return
        }
        var status = permission.status
        if status == .notDetermined {
            status = await permission.request()
        }
        guard isAuthorized(status) else {
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
            await TransitNotificationScheduler.shared.reschedule(TransitNotificationPlanner.plan(from: forecast))
        } catch {
            preferences.transitAlertsEnabled = false
            alertsError = "Couldn't reach the sky just now. Try again in a moment."
        }
    }

    private func isAuthorized(_ status: NotificationPermission.Status) -> Bool {
        status == .granted || status == .provisional || status == .ephemeral
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
