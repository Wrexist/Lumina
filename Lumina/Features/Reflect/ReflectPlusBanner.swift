import SwiftUI

/// Dismissible upsell shown in Reflect once the user has written a few
/// entries.
///
/// Extracted from `ReflectHubView` so that view stays under SwiftLint's
/// 250-line `type_body_length` limit — and because this is genuinely its own
/// piece of UI.
///
/// The copy used to advertise "Pattern detection at 30 entries", a feature
/// that was never built and that the paywall was also selling. Reflect is
/// entirely free; this points at what Plus actually unlocks.
struct ReflectPlusBanner: View {
    @Binding var dismissed: Bool

    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack {
                    LuminaBadge(title: "Plus", tone: .premium)
                    Text("Go deeper with Lumina Plus")
                        .font(LuminaTypography.body)
                    Spacer()
                    Button {
                        dismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
                    }
                    .accessibilityLabel("Dismiss Plus banner")
                }
                Text("Reflect is free, and stays free. Plus adds your Human Design bodygraph, compatibility for everyone you add, your transit forecast, and the home-screen widget.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                LuminaButton(title: "See what's included", variant: .secondary) {
                    PaywallPresenter.shared.present()
                }
            }
        }
    }
}
