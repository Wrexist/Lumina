import SwiftUI

/// The Privacy Policy + Terms of Service links Apple requires on both the
/// settings surface and the subscription paywall (Guidelines 3.1.2 / 5.1.1).
/// Small, quiet, tokenized — one source of truth so the two placements can't
/// drift apart.
struct LuminaLegalLinks: View {
    /// Points at the **live** GitHub Pages mirror, which actually serves the
    /// page today. The `lumina.app` domain is a known pre-existing hosting
    /// blocker, so linking there would 404 — and Apple rejects a subscription
    /// paywall (or Settings) with a dead Privacy Policy link (Guideline
    /// 3.1.2). Switch this to `https://\(LuminaDeepLink.universalLinkHost)/
    /// privacy.html` once `lumina.app` serves it.
    private static let privacyPolicyURL = URL(
        string: "https://wrexist.github.io/Lumina/privacy.html"
    )

    /// No custom Terms page exists yet, so this points at Apple's standard
    /// EULA — the App Store's documented default for apps without their own.
    private static let termsOfServiceURL = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )

    var body: some View {
        HStack(spacing: LuminaSpacing.md) {
            if let privacyPolicyURL = Self.privacyPolicyURL {
                Link("Privacy Policy", destination: privacyPolicyURL)
            }
            Text("·")
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.4))
            if let termsOfServiceURL = Self.termsOfServiceURL {
                Link("Terms of Service", destination: termsOfServiceURL)
            }
        }
        .font(LuminaTypography.caption)
        .foregroundStyle(LuminaColors.celestialBlue)
    }
}

#Preview {
    LuminaLegalLinks()
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
}
