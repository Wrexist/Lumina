import Foundation

/// Every string on the paywall that mentions money.
///
/// Pulled out of `PaywallOfferView` so it can be unit-tested, because this is
/// the copy Apple checks hardest and the copy this app has already got wrong
/// once: the rescue variant advertised "30% off" and "$41.99" and then
/// purchased the standard annual package at full price.
///
/// The rule these functions encode, and that `PaywallCopyTests` enforces:
/// **a price only ever reaches the screen by being read off a real
/// `PlanOffer`.** There is no fallback price, no reference price, and no
/// discount arithmetic anywhere in this type. If StoreKit hasn't resolved an
/// offering yet, the paywall quotes nothing at all.
enum PaywallCopy {
    /// Guideline 3.1.2 requires the title, the length, and the price per
    /// period to be visible before purchase.
    static func planTitle(_ offer: IAPManager.PlanOffer) -> String {
        switch offer.plan {
        case .monthly: "\(offer.localizedPrice) / month"
        case .annual: "\(offer.localizedPrice) / year"
        }
    }

    /// The primary button's title. Falls back to a price-free "Continue" when
    /// the selected plan has no resolved offer — never to a guessed number.
    static func primaryCTATitle(
        for plan: IAPManager.PremiumPlan,
        in offers: [IAPManager.PlanOffer]
    ) -> String {
        guard let offer = offers.first(where: { $0.plan == plan }) else {
            return "Continue"
        }
        // Never promise a trial the product doesn't actually carry.
        if let intro = offer.introductoryOffer {
            return "Start your \(intro)"
        }
        return "Subscribe — \(offer.localizedPrice)"
    }

    /// The rescue variant is a softer re-ask at the *same* price. It reassures;
    /// it does not sweeten. Nothing here may imply a discount.
    static func trustCopy(for variant: PaywallOfferView.Variant) -> String {
        let base = "Cancel anytime in Settings. Your subscription renews automatically until you cancel."
        return variant == .rescue ? "This is the last time we'll bring it up. " + base : base
    }
}
