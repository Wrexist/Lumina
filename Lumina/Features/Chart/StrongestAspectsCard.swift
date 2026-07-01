import SwiftUI

/// The Chart tab's "Your strongest aspects" card — the user's tightest real
/// aspects, each interpreted by `AspectInterpreter`. Extracted from
/// `ChartHubView` to keep that type under the length budget.
struct StrongestAspectsCard: View {
    let chart: NatalChart

    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                Text("Your strongest aspects")
                    .font(LuminaTypography.heading)
                if chart.aspects.isEmpty {
                    Text("Your planets sit largely on their own right now — few major aspects between them.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                } else {
                    ForEach(Array(chart.aspects.prefix(5)), id: \.self) { aspect in
                        Text(AspectInterpreter.interpretation(
                            planet1: aspect.planet1,
                            planet2: aspect.planet2,
                            type: aspect.type
                        ))
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
