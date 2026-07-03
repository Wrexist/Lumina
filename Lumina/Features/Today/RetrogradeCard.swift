import SwiftUI

/// "Retrogrades" — which bodies are currently in apparent backward motion and
/// when each turns direct, as a compact strip under the Moon card (the two
/// together are Today's "sky context"; the reading stays the hero). Data
/// arrives from `TodayViewModel`'s shared fan-out, and the caller hides the
/// strip entirely when nothing is retrograde. Real ephemeris, never faked.
struct RetrogradeCard: View {
    let result: RetrogradesResult

    private static let stationFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Locale-aware ordering of the same fields (e.g. "Jul 2" vs "2 juil.").
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter
    }()

    var body: some View {
        LuminaCard {
            HStack(alignment: .top, spacing: LuminaSpacing.md) {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(LuminaColors.celestialBlue)
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text(RetrogradePhrasing.summary(for: result))
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !stationSummary.isEmpty {
                        Text(stationSummary)
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
            }
        }
    }

    /// The station dates joined into one caption line, keeping the strip to
    /// two lines of text instead of a bullet per planet.
    private var stationSummary: String {
        result.planets
            .filter(\.isRetrograde)
            .compactMap { RetrogradePhrasing.stationLine(for: $0, formatter: Self.stationFormatter) }
            .joined(separator: " ")
    }
}
