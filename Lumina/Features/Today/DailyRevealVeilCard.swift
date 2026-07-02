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
                Image(systemName: "sparkles")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.mutedGold)
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
