import SwiftUI

/// The soft post-onboarding paywall offer per `ROADMAP.md` Phase 2 and
/// Apple Guideline 3.1.2(c). Shown as a `.fullScreenCover` after the
/// chart-reveal step; explicitly non-blocking. The user can pick "Start
/// 7-day free trial" (RevenueCat wires up later) or "Continue free" — the
/// free tier is genuinely free, not gated behind a hard wall.
struct PaywallOfferView: View {
    enum Variant: String, Identifiable, Hashable, Sendable {
        case initial
        case rescue

        var id: String { rawValue }
    }

    let variant: Variant
    let onStartTrial: () -> Void
    let onContinueFree: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                hero
                priceRow
                featureList
                primaryCTA
                continueFreeLink
                trustNote
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
    }

    // MARK: - Sub-views

    private var hero: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            if variant == .rescue {
                LuminaBadge(title: "30% off", tone: .premium)
            }
            Text(variant == .rescue ? "One last thing" : "Lumina Plus")
                .font(LuminaTypography.display)
                .foregroundStyle(LuminaColors.inkBlack)
            Text(variant == .rescue
                ? "We'd love to keep you. Take 30% off your first year — only this once."
                : "Real readings, daily. The full chart, palm scans without limits, your own narrated audio.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
        }
    }

    private var priceRow: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(variant == .rescue ? "$41.99" : "$59.99")
                        .font(LuminaTypography.heading)
                    Text("/year")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    Spacer()
                    LuminaBadge(title: "Best value", tone: .neutral)
                }
                Text("Or $9.99 / month. 7-day free trial. Cancel anytime in Settings.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            featureRow("Audio narration of every daily reading")
            featureRow("Unlimited palm scans (free is 1 / month)")
            featureRow("Full Human Design bodygraph + authority")
            featureRow("Monthly journal pattern detection")
            featureRow("Crush Report unlocked")
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: LuminaSpacing.sm) {
            Image(systemName: "checkmark")
                .foregroundStyle(LuminaColors.celestialBlue)
            Text(text)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.9))
        }
    }

    private var primaryCTA: some View {
        LuminaButton(
            title: variant == .rescue ? "Take 30% off" : "Start 7-day free trial",
            variant: .primary
        ) {
            Haptics.medium.play()
            onStartTrial()
        }
    }

    private var continueFreeLink: some View {
        LuminaButton(title: "Continue free", variant: .ghost) {
            onContinueFree()
        }
    }

    private var trustNote: some View {
        Text("No charge until trial ends. We never use dark patterns, and we never re-prompt you in the same session.")
            .font(LuminaTypography.caption)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.55))
            .multilineTextAlignment(.leading)
            .padding(.top, LuminaSpacing.sm)
    }
}

#Preview("Initial") {
    func noop() { }
    return PaywallOfferView(variant: .initial, onStartTrial: noop, onContinueFree: noop)
}

#Preview("Rescue") {
    func noop() { }
    return PaywallOfferView(variant: .rescue, onStartTrial: noop, onContinueFree: noop)
}
