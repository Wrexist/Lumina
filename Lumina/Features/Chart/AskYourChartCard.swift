import SwiftUI

/// Chart-tab entry into the grounded "Ask your chart" Q&A (`ChartQAView`).
/// Extracted from `ChartHubView` to keep that type under the length budget.
struct AskYourChartCard: View {
    let chart: NatalChart

    var body: some View {
        NavigationLink {
            ChartQAView(chart: chart)
        } label: {
            LuminaCard(surface: .glass) {
                HStack(spacing: LuminaSpacing.md) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(LuminaColors.celestialBlue)
                    VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                        Text("Ask your chart")
                            .font(LuminaTypography.heading)
                        Text("Real answers, read straight from your placements.")
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
        .accessibilityLabel("Ask your chart")
    }
}
