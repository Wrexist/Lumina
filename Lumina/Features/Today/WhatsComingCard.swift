import SwiftUI

/// The "Ahead" card — what's on the horizon, in one place. An imminent
/// Jupiter/Saturn return (when there is one) leads as a highlighted row,
/// followed by the entry into the timing forecast (`ForecastView`) with the
/// exact dates upcoming transits perfect. Extracted to its own component to
/// keep `TodayHubView` under the length budget.
struct WhatsComingCard: View {
    /// Returns within the next year, soonest first, from `TodayViewModel`.
    let imminentReturns: [ReturnEvent]

    var body: some View {
        LuminaCard(surface: .glass) {
            VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                Text("AHEAD")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                if !imminentReturns.isEmpty {
                    ReturnsCard(imminent: imminentReturns)
                    Divider()
                }
                forecastLink
            }
        }
    }

    @ViewBuilder
    private var forecastLink: some View {
        if PremiumGate.isUnlocked(.forecast) {
            unlockedForecastLink
        } else {
            // Keep the row visible but route it to the paywall instead of the
            // forecast — the entry point stays discoverable, which is also
            // what gives App Review a reachable path to the purchase.
            Button {
                PaywallPresenter.shared.present(for: .forecast)
            } label: {
                forecastLabel(locked: true)
            }
            .buttonStyle(.plain)
        }
    }

    private var unlockedForecastLink: some View {
        NavigationLink {
            ForecastView()
        } label: {
            forecastLabel(locked: false)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("What's coming")
    }

    private func forecastLabel(locked: Bool) -> some View {
        HStack(spacing: LuminaSpacing.md) {
            Image(systemName: "calendar")
                .foregroundStyle(LuminaColors.celestialBlue)
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text("What's coming")
                    .font(LuminaTypography.heading)
                Text(locked
                    ? "The exact dates your transits perfect — part of Lumina Plus."
                    : "The exact dates your transits perfect.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: locked ? "lock" : "chevron.right")
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.3))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(locked ? "What's coming, included with Lumina Plus" : "What's coming")
        .accessibilityAddTraits(.isButton)
    }
}
