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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                statusCard
                primaryAction
                quietHoursPlaceholder
                eventsPlaceholder
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
                Text("Default 9pm–7am. Adjustable per Phase 11 of the roadmap.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private var eventsPlaceholder: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack {
                    Text("Event-triggered pushes")
                        .font(LuminaTypography.body)
                    Spacer()
                    LuminaBadge(title: "Soon", tone: .neutral)
                }
                Text("Eclipse, retrograde, ingress — capped at 5 per week. Ships in Phase 11.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
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
