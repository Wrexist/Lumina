import SwiftUI

/// The Lumina Plus offer, per Apple Guideline 3.1.2. Explicitly non-blocking
/// — the free tier is genuinely free.
///
/// This screen previously had three compliance problems, all fixed here:
///
/// 1. It advertised six features and the app gated **none** of them, so a
///    subscriber received nothing. The list now renders `PremiumFeature`,
///    which is the same enum the gates read — the marketing and the gating
///    cannot drift apart.
/// 2. The `.rescue` variant showed "$41.99" and a "30% off" badge, then
///    purchased the standard annual package. The user was charged a price
///    they were never shown. There is no fake discount now: the rescue
///    variant is a softer re-ask at the same price.
/// 3. Prices were hardcoded USD. They now come from StoreKit via
///    `IAPManager.availableOffers()`, so every storefront sees its real
///    price, and there is a plan picker because a monthly option is
///    advertised.
struct PaywallOfferView: View {
    enum Variant: String, Identifiable, Hashable, Sendable {
        case initial
        case rescue

        var id: String { rawValue }
    }

    let variant: Variant
    /// Feature that triggered the paywall, when it was opened from a locked
    /// surface. Used to lead with the line the user actually wanted.
    var triggeringFeature: PremiumFeature?
    /// True while the owner is resolving a purchase — keeps the CTA in a
    /// loading state instead of the cover vanishing under the user.
    var purchaseInFlight = false
    /// A genuine purchase failure, surfaced inline. Never swallowed.
    var purchaseError: LuminaError?
    let onStartTrial: (IAPManager.PremiumPlan) -> Void
    let onContinueFree: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var offers: [IAPManager.PlanOffer] = []
    @State private var selectedPlan: IAPManager.PremiumPlan = .annual
    @State private var isLoadingOffers = true
    @State private var isRestoring = false
    @State private var restoreMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                hero
                planPicker
                featureList
                primaryCTA
                restoreLink
                continueFreeLink
                trustNote
                LuminaLegalLinks()
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .task { await loadOffers() }
    }

    // MARK: - Sub-views

    private var hero: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text(variant == .rescue ? "One last thing" : "Lumina Plus")
                .font(LuminaTypography.display)
                .foregroundStyle(LuminaColors.inkBlack)
            Text(heroBlurb)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroBlurb: String {
        if let triggeringFeature {
            return triggeringFeature.lockedBlurb
        }
        return variant == .rescue
            ? "We'd love to keep you. Everything below is included — and the free tier stays free either way."
            : "Human Design, compatibility, your forecast and the widget. Your daily reading and chart stay free."
    }

    // MARK: Plan picker

    @ViewBuilder
    private var planPicker: some View {
        if isLoadingOffers {
            LuminaCard {
                HStack {
                    ProgressView()
                    Text("Loading prices…")
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if offers.isEmpty {
            // No offering resolved (RevenueCat unconfigured, or the products
            // aren't live yet). Quote no price at all rather than a number we
            // might not honour.
            LuminaCard {
                Text("Subscription pricing isn't available right now. Please try again in a moment — you won't be charged anything until you confirm on Apple's payment sheet.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(spacing: LuminaSpacing.sm) {
                ForEach(offers, id: \.plan) { offer in
                    planRow(offer)
                }
            }
        }
    }

    private func planRow(_ offer: IAPManager.PlanOffer) -> some View {
        let isSelected = offer.plan == selectedPlan
        return Button {
            selectedPlan = offer.plan
            Haptics.light.play()
        } label: {
            LuminaCard {
                HStack(alignment: .firstTextBaseline, spacing: LuminaSpacing.sm) {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(LuminaColors.celestialBlue)
                    VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                        Text(planTitle(offer))
                            .font(LuminaTypography.heading)
                            .foregroundStyle(LuminaColors.inkBlack)
                        if let intro = offer.introductoryOffer {
                            Text("\(intro), then \(offer.localizedPrice)")
                                .font(LuminaTypography.caption)
                                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        }
                    }
                    Spacer()
                    if offer.plan == .annual, offers.count > 1 {
                        LuminaBadge(title: "Best value", tone: .neutral)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(planTitle(offer))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private func planTitle(_ offer: IAPManager.PlanOffer) -> String {
        PaywallCopy.planTitle(offer)
    }

    // MARK: Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            // Driven by the same enum the gates consult, so this list is
            // always exactly what Plus unlocks.
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                featureRow(feature.marketingLine)
            }
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: LuminaSpacing.sm) {
            Image(systemName: "checkmark")
                .foregroundStyle(LuminaColors.celestialBlue)
            Text(text)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Actions

    private var primaryCTA: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            LuminaButton(
                title: primaryCTATitle,
                variant: .primary,
                isLoading: purchaseInFlight,
                isEnabled: !offers.isEmpty && !purchaseInFlight
            ) {
                Haptics.medium.play()
                onStartTrial(selectedPlan)
            }
            if let purchaseError {
                Text(purchaseError.userBody)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.error)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Purchase failed. \(purchaseError.userBody)")
            }
        }
    }

    private var primaryCTATitle: String {
        PaywallCopy.primaryCTATitle(for: selectedPlan, in: offers)
    }

    /// Required by Guideline 3.1.1, and genuinely needed here: the paywall is
    /// shown during onboarding, *before* Settings is reachable, so a
    /// reinstalling subscriber had no way to restore without paying again.
    private var restoreLink: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            LuminaButton(title: "Restore purchases", variant: .ghost, isLoading: isRestoring) {
                Task { await restore() }
            }
            if let restoreMessage {
                Text(restoreMessage)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var continueFreeLink: some View {
        LuminaButton(title: "Continue free", variant: .ghost) {
            onContinueFree()
        }
    }

    private var trustNote: some View {
        Text(trustCopy)
            .font(LuminaTypography.caption)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.55))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, LuminaSpacing.sm)
    }

    private var trustCopy: String {
        PaywallCopy.trustCopy(for: variant)
    }

    // MARK: - Behaviour

    private func loadOffers() async {
        isLoadingOffers = true
        defer { isLoadingOffers = false }
        let loaded = await IAPManager.shared.availableOffers()
        offers = loaded
        // Prefer annual when present, otherwise whatever exists.
        if let annual = loaded.first(where: { $0.plan == .annual }) {
            selectedPlan = annual.plan
        } else if let first = loaded.first {
            selectedPlan = first.plan
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        restoreMessage = nil
        do {
            let restored = try await IAPManager.shared.restorePurchases()
            restoreMessage = restored
                ? "Restored — Lumina Plus is active on this device."
                : "No previous purchase found for this Apple Account."
        } catch {
            restoreMessage = "Couldn't reach the App Store just now. Please try again."
        }
    }
}
