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

    /// Single source of truth for the copy in `priceRow`.
    ///
    /// These are the US App Store reference prices, NOT localized prices.
    /// `IAPManager`'s public surface (`configure` / `currentEntitlements` /
    /// `purchaseCurrentOffering` / `restorePurchases`) never exposes the
    /// fetched `Offering` or a `localizedPriceString`, and views may not
    /// reach for `Purchases.shared` themselves (`.swiftlint.yml`'s
    /// `no_direct_revenuecat_calls_in_views`), so this view cannot show the
    /// user's real regional price yet. Rather than invent regional prices,
    /// we show the USD reference and say so in `disclosure` — Apple's
    /// payment sheet always shows the true local price before purchase.
    ///
    /// TODO(lumina): when `IAPManager` grows an accessor for the current
    /// offering's localized prices, load them on appear and keep this struct
    /// only as the fallback for builds where RevenueCat isn't configured
    /// (dev/CI without a real API key).
    struct PriceDisplay: Equatable, Sendable {
        let yearlyPrice: String
        let subline: String
        let disclosure: String

        static func fallback(for variant: Variant) -> PriceDisplay {
            PriceDisplay(
                yearlyPrice: variant == .rescue ? "$41.99" : "$59.99",
                subline: "Or $9.99 / month. 7-day free trial. Cancel anytime in Settings.",
                disclosure: "Prices shown in USD — your exact local price appears "
                    + "on Apple's payment sheet before you're charged."
            )
        }
    }

    let variant: Variant
    let onStartTrial: () -> Void
    let onContinueFree: () -> Void

    private var priceDisplay: PriceDisplay {
        .fallback(for: variant)
    }

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
                LuminaLegalLinks()
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
                : "Your full chart, daily transits, and every compatibility tool — the real depth, unlocked.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
        }
    }

    private var priceRow: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(priceDisplay.yearlyPrice)
                        .font(LuminaTypography.heading)
                    Text("/year")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    Spacer()
                    LuminaBadge(title: "Best value", tone: .neutral)
                }
                Text(priceDisplay.subline)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(priceDisplay.disclosure)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            featureRow("Your full interactive birth chart")
            featureRow("The Human Design bodygraph, in full")
            featureRow("Synastry + composite compatibility")
            featureRow("Your daily transit reading")
            featureRow("Pattern detection across your journal — the emotional threads over a month")
            featureRow("The home-screen widget")
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
        Text(variant == .rescue
            ? "No charge until your trial ends. This is the last time we'll bring it up — cancel anytime in Settings."
            : "No charge until your trial ends. We never use dark patterns — cancel anytime in Settings.")
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
