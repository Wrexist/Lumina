import SwiftUI

/// A premium, shareable "you & them" compatibility card — the score plus the
/// relationship headline, rendered off-screen (`ImageRenderer`) for the share
/// sheet. The viral loop of the category: the result travels to the other
/// person. Real synastry, never faked (see `docs/VIRALITY.md`).
struct CompatibilityShareCard: View {
    let friendName: String
    let score: Int
    let headline: String
    @ScaledMetric private var scoreSize: CGFloat = 120

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            VStack(spacing: LuminaSpacing.xs) {
                Text("LUMINA")
                    .font(LuminaTypography.mono)
                    .tracking(6)
                    .foregroundStyle(LuminaColors.mutedGold)
                Text("You & \(friendName)")
                    .font(LuminaTypography.display)
                    .foregroundStyle(LuminaColors.inkBlack)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: LuminaSpacing.sm) {
                Text("\(score)")
                    .font(.system(size: scoreSize, weight: .light, design: .serif))
                    .foregroundStyle(LuminaColors.celestialBlue)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("OUT OF 100")
                    .font(LuminaTypography.mono)
                    .tracking(2)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
            Text(headline)
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
                .multilineTextAlignment(.center)
            Text("Real charts. Real synastry.")
                .font(LuminaTypography.bodyLight)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
        .padding(LuminaSpacing.xxl)
        .frame(width: 600, height: 800)
        .background(LuminaColors.parchment)
    }
}
