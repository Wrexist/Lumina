import SwiftUI

/// A premium, shareable card of the user's Big-3, rendered off-screen to an
/// image (`ImageRenderer`) for the system share sheet. Editorial and on-brand,
/// and honest — real positions, the same data the app shows. Not interactive;
/// built purely for rendering, so it carries its own fixed frame and background.
struct ChartShareCard: View {
    let chart: NatalChart
    @ScaledMetric private var glyphSize: CGFloat = 44

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            VStack(spacing: LuminaSpacing.xs) {
                Text("LUMINA")
                    .font(LuminaTypography.mono)
                    .tracking(6)
                    .foregroundStyle(LuminaColors.mutedGold)
                Text("My birth chart")
                    .font(LuminaTypography.display)
                    .foregroundStyle(LuminaColors.inkBlack)
            }
            HStack(spacing: LuminaSpacing.lg) {
                column("Sun", longitude: longitude("Sun"))
                column("Moon", longitude: longitude("Moon"))
                column("Rising", longitude: chart.houses?.ascendant)
            }
            Text("Finally, a real one.")
                .font(LuminaTypography.bodyLight)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
        .padding(LuminaSpacing.xxl)
        .frame(width: 540, height: 540)
        .background(LuminaColors.parchment)
    }

    private func longitude(_ name: String) -> Double? {
        chart.planets.first(where: { $0.planet == name })?.longitude
    }

    private func column(_ label: String, longitude: Double?) -> some View {
        VStack(spacing: LuminaSpacing.sm) {
            Text(label.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text(longitude.map { ChartGlyphs.signGlyph(ChartGlyphs.sign(forLongitude: $0)) } ?? "—")
                .font(.system(size: glyphSize))
                .foregroundStyle(LuminaColors.mutedGold)
            Text(longitude.map { ChartGlyphs.sign(forLongitude: $0) } ?? "Hidden")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack)
        }
    }
}
