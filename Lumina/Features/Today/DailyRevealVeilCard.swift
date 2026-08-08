import SwiftUI

/// The pre-reveal face of the Today reading card: the same `LuminaCard`
/// frame the reading lives in, dressed as a small patch of night sky —
/// a quiet anticipation beat, not a prize box. Tapping anywhere unveils
/// today's reading (handled by `TodayHubView`, which owns the transition
/// and the reveal state).
///
/// Only ever shown for the happy path — loading, error, and
/// transits-unavailable states are never veiled.
struct DailyRevealVeilCard: View {
    /// Fired on tap; the parent plays the haptic and marks the day revealed.
    var onUnveil: () -> Void

    /// Keeps the veil close to the revealed reading card's height so the
    /// unveil swap doesn't reflow the page. Scales with Dynamic Type like
    /// the text it stands in for.
    @ScaledMetric private var minHeight: CGFloat = 148

    /// Width of the crescent-and-orbits mark. The art is roughly 16:9, so
    /// this adds about 56pt of height — enough to carry the card, little
    /// enough that the veil still lands near the revealed reading's height.
    @ScaledMetric private var markWidth: CGFloat = 96

    var body: some View {
        Button(action: onUnveil) {
            LuminaCard(surface: .midnight, padding: 0) {
                veilFace
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your sky is ready")
        .accessibilityHint("Unveils today's reading")
    }

    private var veilFace: some View {
        ZStack {
            // Static under Reduce Motion — the starfield handles that itself.
            LuminaStarfield(starCount: 40, tint: LuminaColors.mutedGold)
            VStack(spacing: LuminaSpacing.sm) {
                // Gold-and-cream line art on the midnight card face: the same
                // palette as the starfield behind it, so the veil reads as
                // one drawn surface rather than a symbol pasted on a texture.
                LuminaImageAsset.revealSignature.image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: markWidth)
                    .accessibilityHidden(true)
                Text("Your sky is ready")
                    .font(LuminaTypography.heading)
                Text("Tap to unveil today's reading")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.parchment.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .padding(LuminaSpacing.lg)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }
}

#Preview("Veiled reading") {
    DailyRevealVeilCard(onUnveil: {})
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
}
