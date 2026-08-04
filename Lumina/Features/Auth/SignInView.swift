import AuthenticationServices
import SwiftUI

/// Sign in with Apple screen. Self-contained so it can be presented as a
/// `.sheet` from a Settings row without this file needing to know anything
/// about `SettingsView` — the caller passes `onSignedIn` and handles
/// dismissal/navigation itself.
struct SignInView: View {
    var onSignedIn: (AuthSession) -> Void = { _ in }

    @State private var authManager = AuthManager.shared
    @State private var isSigningIn = false
    @State private var error: LuminaError?

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            Spacer()

            VStack(spacing: LuminaSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(.largeTitle))
                    .foregroundStyle(LuminaColors.goldInk)
                    .accessibilityHidden(true)
                Text("Sign in to sync")
                    .font(LuminaTypography.heading)
                    .foregroundStyle(LuminaColors.inkBlack)
                Text("Keep your chart, journal, and friends backed up and available on every device.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LuminaSpacing.lg)
            }

            if let error {
                LuminaErrorState(error: error, onRetry: handleSignIn, onCancel: { self.error = nil })
            } else {
                signInButton
            }

            Spacer()
            Spacer()
        }
        .padding(LuminaSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LuminaColors.parchment)
    }

    // `SignInWithAppleButton` is one of the few elements in this codebase
    // that doesn't route through `LuminaButton` — Apple's HIG requires the
    // mark/label/corner treatment it ships with, and reskinning it risks
    // violating the Sign in with Apple usage guidelines. We only control
    // its size, corner radius, and the light/dark style token, not its
    // internal typography or icon.
    //
    // NOTE: this button's own `onRequest`/`onCompletion` drive a *second*,
    // separate `ASAuthorizationController` request internal to SwiftUI's
    // wrapper — we deliberately don't use them for the real flow, since
    // `AuthManager.signIn()` already owns its own `ASAuthorizationController`
    // (Keychain persistence, session merging, the Supabase exchange). Wiring
    // both would fire two competing native Apple ID prompts. `onRequest`
    // still needs the right scopes configured (SwiftUI requires a non-empty
    // closure), and `onCompletion` is used only to swallow *this* wrapper's
    // own result so it never surfaces a duplicate error alongside
    // `AuthManager`'s.
    private var signInButton: some View {
        SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: { _ in })
            .signInWithAppleButtonStyle(.black)
            .frame(height: LuminaButtonMetrics.primaryHeight)
            .luminaCornerRadius(LuminaRadii.md)
            .padding(.horizontal, LuminaSpacing.lg)
            .opacity(isSigningIn ? 0.6 : 1)
            .allowsHitTesting(false)
            .overlay {
                if isSigningIn {
                    ProgressView()
                } else {
                    Button(action: handleSignIn) {
                        Color.clear
                    }
                    .accessibilityLabel("Sign in with Apple")
                }
            }
    }

    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleSignIn() {
        guard !isSigningIn else { return }
        error = nil
        isSigningIn = true
        Task {
            defer { isSigningIn = false }
            do {
                let session = try await authManager.signIn()
                onSignedIn(session)
            } catch {
                self.error = LuminaError.from(error)
            }
        }
    }
}

/// Local sizing constant — kept out of `LuminaSpacing` since it describes
/// one button's height rather than a general spacing rhythm, and out of
/// `LuminaButton` since `SignInWithAppleButton` isn't a `LuminaButton`.
private enum LuminaButtonMetrics {
    static let primaryHeight: CGFloat = 56
}

#Preview {
    SignInView()
}
