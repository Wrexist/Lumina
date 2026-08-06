import SwiftUI

/// "Retrogrades" — which bodies are currently in apparent backward motion and
/// when each turns direct, as a compact strip under the Moon card (the two
/// together are Today's "sky context"; the reading stays the hero). Data
/// arrives from `TodayViewModel`'s shared fan-out, and the caller hides the
/// strip entirely when nothing is retrograde. Real ephemeris, never faked.
struct RetrogradeCard: View {
    let result: RetrogradesResult
    @ScaledMetric private var markSize: CGFloat = 24

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
                    // docs/NAVIGATION.md §1.4: no jargon without an inline
                    // glossary. "Retrograde" is the single most-asked-about
                    // word in this category and the app defined it nowhere.
                    GlossaryLink("Retrograde")
                        .font(LuminaTypography.mono)
                        .tracking(1.4)
                    Text(RetrogradePhrasing.summary(for: result))
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !retrograde.isEmpty {
                        marks
                    }
                    if !stationSummary.isEmpty {
                        Text(stationSummary)
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
            }
        }
    }

    /// Which bodies are actually walking backwards right now, in the order
    /// the backend returned them (Mercury outward).
    private var retrograde: [RetrogradeState] {
        result.planets.filter(\.isRetrograde)
    }

    /// The bodies themselves, under the sentence that names them — the
    /// summary line is already the accessible version, so these are purely
    /// the "which ones?" answered at a glance.
    ///
    /// Up to seven bodies can be retrograde at once, so the scaled size is
    /// capped: at accessibility text sizes an uncapped strip would run off
    /// the card rather than growing usefully.
    private var marks: some View {
        HStack(spacing: LuminaSpacing.sm) {
            ForEach(retrograde) { state in
                PlanetMark(planet: state.planet, size: min(markSize, 32))
            }
        }
        .accessibilityHidden(true)
    }

    /// The station dates joined into one caption line, keeping the strip to
    /// two lines of text instead of a bullet per planet.
    private var stationSummary: String {
        retrograde
            .compactMap { RetrogradePhrasing.stationLine(for: $0, formatter: Self.stationFormatter) }
            .joined(separator: " ")
    }
}
