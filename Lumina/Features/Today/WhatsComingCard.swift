import SwiftUI

/// Today-tab entry into the timing forecast (`ForecastView`) — the exact dates
/// upcoming transits perfect. Extracted to its own component to keep
/// `TodayHubView` under the length budget.
struct WhatsComingCard: View {
    var body: some View {
        NavigationLink {
            ForecastView()
        } label: {
            LuminaCard(surface: .glass) {
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel("What's coming")
    }
}
