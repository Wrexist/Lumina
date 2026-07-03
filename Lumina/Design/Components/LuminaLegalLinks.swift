import SwiftUI

/// The Privacy Policy + Terms of Service links Apple requires on both the
/// settings surface and the subscription paywall (Guidelines 3.1.2 / 5.1.1).
/// Small, quiet, tokenized — one source of truth so the two placements can't
/// drift apart.
struct LuminaLegalLinks: View {
    /// `https://lumina.app/privacy.html` — built from the same host the app's
    /// universal links already use (`LuminaDeepLink.universalLinkHost`) so the
    /// legal pages live on the app's canonical domain. (The `lumina.app`
    /// hosting is a known pre-existing blocker; the live fallback today is the
    /// GitHub Pages mirror at `wrexist.github.io/Lumina/privacy.html`.)
    private static var privacyPolicyURL: URL? {
        URL(string: "https://\(LuminaDeepLink.universalLinkHost)/privacy.html")
    }

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
