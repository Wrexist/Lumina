import SwiftUI

/// The premium, shareable "cosmic profile" card — the user's Big-3 plus their
/// dominant element/modality and a one-line signature, rendered off-screen to a
/// portrait image (`ImageRenderer`) for the share sheet. Editorial, on-brand,
/// and honest (real positions) — the category's biggest premium-safe growth
/// lever (see `docs/VIRALITY.md`). Not interactive; carries its own fixed frame.
struct ChartShareCard: View {
    let chart: NatalChart
    @ScaledMetric private var glyphSize: CGFloat = 46

    var body: some View {
        let signature = CosmicSignatureMaker.make(from: chart)
        return VStack(spacing: LuminaSpacing.xl) {
            VStack(spacing: LuminaSpacing.xs) {
                Text("LUMINA")
                    .font(LuminaTypography.mono)
                    .tracking(6)
                    .foregroundStyle(LuminaColors.goldInk)
                Text("My cosmic signature")
                    .font(LuminaTypography.display)
                    .foregroundStyle(LuminaColors.inkBlack)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: LuminaSpacing.lg) {
                column("Sun", sign: signature.sunSign)
                column("Moon", sign: signature.moonSign)
                column("Rising", sign: signature.risingSign)
            }
            VStack(spacing: LuminaSpacing.sm) {
                Text("\(signature.element.uppercased())  ·  \(signature.modality.uppercased())")
                    .font(LuminaTypography.mono)
                    .tracking(2)
                    .foregroundStyle(LuminaColors.celestialBlue)
                Text(signature.headline)
                    .font(LuminaTypography.heading)
                    .foregroundStyle(LuminaColors.inkBlack)
                    .multilineTextAlignment(.center)
            }
            Text("Finally, a real one.")
                .font(LuminaTypography.bodyLight)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
        .padding(LuminaSpacing.xxl)
        .frame(width: 600, height: 800)
        .background(LuminaColors.parchment)
    }

    private func column(_ label: String, sign: String?) -> some View {
        VStack(spacing: LuminaSpacing.sm) {
            Text(label.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text(sign.map(ChartGlyphs.signGlyph) ?? "—")
                .font(.system(size: glyphSize))
                .foregroundStyle(LuminaColors.goldInk)
            Text(sign ?? "Hidden")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack)
        }
    }
}
