import SwiftUI

/// Sun / Moon / Rising — the three placements every casual user can name.
/// Sits at the top of the Chart tab so first-time users see something
/// they recognise before the full wheel decoder-ring sets in.
struct BigThreeBand: View {
    let chart: NatalChart

    var body: some View {
        HStack(spacing: LuminaSpacing.md) {
            cell(label: "Sun", longitude: planetLongitude("Sun"))
            cell(label: "Moon", longitude: planetLongitude("Moon"))
            cell(label: "Rising", longitude: chart.houses?.ascendant)
        }
    }

    private func planetLongitude(_ name: String) -> Double? {
        chart.planets.first(where: { $0.planet == name })?.longitude
    }

    private func cell(label: String, longitude: Double?) -> some View {
        LuminaCard(padding: LuminaSpacing.sm) {
            VStack(spacing: LuminaSpacing.xs) {
                Text(label.uppercased())
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(longitude.map(signGlyph) ?? "—")
                    .font(.system(size: 36))
                    .foregroundStyle(LuminaColors.mutedGold)
                Text(longitude.map(signName) ?? "Hidden")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func signGlyph(_ longitude: Double) -> String {
        ChartGlyphs.signGlyph(ChartGlyphs.sign(forLongitude: longitude))
    }

    private func signName(_ longitude: Double) -> String {
        ChartGlyphs.sign(forLongitude: longitude)
    }
}
