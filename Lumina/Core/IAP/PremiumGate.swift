import SwiftUI

/// The features Lumina Plus actually unlocks.
///
/// Before this existed, `PremiumStatus.isPremium` was read in exactly one
/// place in the whole app — to hide a banner in Reflect — while the paywall
/// sold six features. Every one of them already worked for free, so a
/// subscriber received nothing they didn't already have. That is a Guideline
/// 3.1.2 rejection and a consumer-protection problem regardless of review.
///
/// The split follows the tier table in `README.md`: the daily reading and
/// the birth chart stay free (they are the reason to open the app at all),
/// and Plus covers the deeper interpretive surfaces.
enum PremiumFeature: String, CaseIterable, Sendable {
    case humanDesign
    case compatibility
    case forecast
    case widget

    /// Short label used in the paywall's feature list.
    var marketingLine: String {
        switch self {
        case .humanDesign:
            "Your Human Design bodygraph — the centres and channels your chart defines"
        case .compatibility:
            "Synastry and composite compatibility for everyone you add"
        case .forecast:
            "What's coming — your transit forecast for the months ahead"
        case .widget:
            "The home-screen widget, kept current with your sky"
        }
    }

    /// Heading shown on the locked state in place of the feature.
    var lockedTitle: String {
        switch self {
        case .humanDesign: "Human Design is part of Plus"
        case .compatibility: "Compatibility is part of Plus"
        case .forecast: "What's coming is part of Plus"
        case .widget: "The widget is part of Plus"
        }
    }

    /// One honest sentence about what unlocking actually gives them. No
    /// urgency, no countdowns — the app's whole pitch is not doing that.
    var lockedBlurb: String {
        switch self {
        case .humanDesign:
            "Your bodygraph is built from the same real birth data as your chart — which centres are defined, and the channels that connect them."
        case .compatibility:
            "See how two charts actually meet: the synastry aspects between them, and the composite chart they make together."
        case .forecast:
            "The transits building over the next few months, and when each one peaks."
        case .widget:
            "Your Sun, Moon and Rising on the home screen, updated as the sky moves."
        }
    }
}

/// Single source of truth for "is this feature available right now".
///
/// Every gated surface calls through here rather than reading
/// `PremiumStatus.isPremium` directly, so the free/paid split is defined in
/// one file instead of scattered across views.
@MainActor
enum PremiumGate {
    static func isUnlocked(_ feature: PremiumFeature) -> Bool {
        PremiumStatus.shared.isPremium
    }
}

/// Presents the paywall from anywhere in the app.
///
/// The paywall used to have exactly one call site — a one-shot during
/// onboarding, gated on `hasSeenInitialOffer` — so a user (or an App Review
/// tester) who tapped "Continue free" once could never reach the purchase
/// again. That is the classic "we were unable to locate the in-app purchase"
/// rejection.
@MainActor
@Observable
final class PaywallPresenter {
    static let shared = PaywallPresenter()

    /// Non-nil while the paywall should be on screen. Carries the feature
    /// that triggered it so the paywall can lead with the relevant line.
    var pendingFeature: PremiumFeature?
    var isPresented = false

    private init() {}

    func present(for feature: PremiumFeature? = nil) {
        pendingFeature = feature
        isPresented = true
    }

    func dismiss() {
        isPresented = false
        pendingFeature = nil
    }
}

/// The standard locked state. Explains the feature, offers the upgrade, and
/// is always dismissible — the surrounding screen stays usable.
struct PremiumLockedCard: View {
    let feature: PremiumFeature

    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text(feature.lockedTitle)
                    .font(LuminaTypography.heading)
                    .foregroundStyle(LuminaColors.inkBlack)

                Text(feature.lockedBlurb)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                LuminaButton(title: "See what's included", variant: .secondary) {
                    PaywallPresenter.shared.present(for: feature)
                }
                .padding(.top, LuminaSpacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }
}

extension View {
    /// Replaces the view with `PremiumLockedCard` unless `feature` is
    /// unlocked. Used at the surfaces the paywall names, so what the paywall
    /// sells and what the app gates cannot drift apart.
    @ViewBuilder
    func premiumGated(_ feature: PremiumFeature) -> some View {
        if PremiumGate.isUnlocked(feature) {
            self
        } else {
            PremiumLockedCard(feature: feature)
        }
    }
}
