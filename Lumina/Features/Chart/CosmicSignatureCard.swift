import SwiftUI

/// In-app "your cosmic signature" — the identity headline (dominant element +
/// modality + a one-liner) drawn straight from the real chart. It's the
/// recognition hit ("this is so me") and doubles as the thing worth sharing.
struct CosmicSignatureCard: View {
    let chart: NatalChart

    var body: some View {
        let signature = CosmicSignatureMaker.make(from: chart)
        return LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("YOUR COSMIC SIGNATURE")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(signature.headline)
                    .font(LuminaTypography.heading)
                    .foregroundStyle(LuminaColors.inkBlack)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: LuminaSpacing.sm) {
                    tag(signature.element)
                    tag(signature.modality)
                }
            }
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text.uppercased())
            .font(LuminaTypography.mono)
            .tracking(1.2)
            .foregroundStyle(LuminaColors.celestialBlue)
            .padding(.horizontal, LuminaSpacing.sm)
            .padding(.vertical, LuminaSpacing.xs)
            .background(LuminaColors.celestialBlue.opacity(0.1))
            .luminaCornerRadius(LuminaRadii.sm)
    }
}
