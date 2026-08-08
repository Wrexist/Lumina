import SwiftUI

/// "What makes your chart rare" — surfaces a stellium or unaspected planet, the
/// curiosity-gap hook. Hidden when the chart is unremarkable, so it only ever
/// appears as a genuine "wait, that's special?" moment.
struct ChartStandoutCard: View {
    let chart: NatalChart

    var body: some View {
        Group {
            if let standout = ChartStandoutFinder.find(in: chart) {
                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        HStack(spacing: LuminaSpacing.sm) {
                            Image(systemName: "sparkle")
                                .foregroundStyle(LuminaColors.goldInk)
                            Text("WHAT MAKES YOUR CHART RARE")
                                .font(LuminaTypography.mono)
                                .tracking(1.4)
                                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                        }
                        Text(standout.headline)
                            .font(LuminaTypography.heading)
                            .foregroundStyle(LuminaColors.inkBlack)
                        Text(standout.detail)
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
