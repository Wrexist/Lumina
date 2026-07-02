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

    private var forecastLink: some View {
        NavigationLink {
            ForecastView()
        } label: {
            HStack(spacing: LuminaSpacing.md) {
                Image(systemName: "calendar")
                    .foregroundStyle(LuminaColors.celestialBlue)
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text("What's coming")
                        .font(LuminaTypography.heading)
                    Text("The exact dates your transits perfect.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.3))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("What's coming")
    }
}
