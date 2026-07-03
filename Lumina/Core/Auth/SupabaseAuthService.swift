import Foundation
import OSLog
import Supabase

/// Exchanges a Sign in with Apple identity token for a Supabase session.
/// Actor for the service layer, matching the `EphemerisService` /
/// `LuminaAIClient` convention.
///
/// There is no Supabase project provisioned yet — `LuminaSupabaseURL`
/// / `LuminaSupabaseAnonKey` will be empty/placeholder in every CI and dev
/// build today (see `TASK.md` Blockers table). This actor guards on that
/// exactly like `EphemerisService` guards on its own missing config: it
/// throws a typed `ServiceError.missingConfiguration` rather than crashing,
/// and the `SupabaseClient` itself is constructed lazily so an app that
/// never calls this actor never touches the SDK at all.
///
/// `signInWithApple(idToken:nonce:)` is currently unreachable from any real
/// user flow — `AuthManager.signIn()` calls it best-effort and silently
/// swallows exactly the `.missingConfiguration` case, since local
/// Keychain-backed sign-in is already useful before a backend exists. That's
/// expected: this method has no meaningful call site until the Supabase
/// project is provisioned and a real `idToken` can be minted.
actor SupabaseAuthService {
    enum ServiceError: Error, Equatable {
        case missingConfiguration
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "SupabaseAuthService")
    private let url: URL?
    private let anonKey: String?
    private var client: SupabaseClient?

    /// Production initializer — reads `LuminaSupabaseURL` and
    /// `LuminaSupabaseAnonKey` from `Info.plist` (populated by xcconfig).
    init(infoPlist: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        self.url = Self.realConfigValue(infoPlist["LuminaSupabaseURL"] as? String).flatMap(URL.init(string:))
        self.anonKey = Self.realConfigValue(infoPlist["LuminaSupabaseAnonKey"] as? String)
    }

    /// A value is unusable if it's empty or still the unexpanded xcconfig
    /// placeholder like `$(SUPABASE_URL)` (happens when
    /// `secrets/Config.xcconfig` isn't generated yet) — the same rejection
    /// `IAPManager.isRealAPIKey` applies to its RevenueCat key.
    private static func realConfigValue(_ value: String?) -> String? {
        guard let value, !value.isEmpty, !value.hasPrefix("$(") else { return nil }
        return value
    }

    /// Test seam — construct directly with a known URL/key.
    init(url: URL, anonKey: String) {
        self.url = url
        self.anonKey = anonKey
    }

    /// Exchanges an Apple identity token for a Supabase session using
    /// Supabase's native Sign in with Apple support. Returns once the
    /// exchange succeeds; there's nothing meaningful to hand back to the
    /// caller yet beyond "it worked" since no other part of the app reads a
    /// Supabase session today.
    ///
    /// NOTE: verify once CI resolves the `supabase-swift` package (pinned
    /// `from: 2.0.0` in `project.yml`, so the exact minor/patch is whatever
    /// resolves) that `OpenIDConnectCredentials` and
    /// `auth.signInWithIdToken(credentials:)` still match this shape —
    /// this is written to the documented Supabase Swift API but has never
    /// been compiled against the real package in this repo (zero prior
    /// `import Supabase` sites existed before this file).
    func signInWithApple(idToken: String?, nonce: String?) async throws {
        guard let idToken, !idToken.isEmpty else {
            // No real token to exchange yet — this is the expected shape
            // until a caller has a live ASAuthorizationAppleIDCredential's
            // `identityToken` decoded to a JWT string. Treat as a missing
            // configuration/precondition rather than a hard error so
            // `AuthManager.signIn()`'s best-effort call site behaves the
            // same way it does when Supabase itself isn't configured.
            throw ServiceError.missingConfiguration
        }

        let client = try resolvedClient()
        logger.debug("exchanging Apple identity token with Supabase")

        let credentials = OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
        try await client.auth.signInWithIdToken(credentials: credentials)
    }

    /// Best-effort server-side account deletion for Apple Guideline
    /// 5.1.1(v). Deleting a Supabase auth user requires the service-role key
    /// via the admin API — which must never ship in a client — so a real
    /// deletion has to run through a server-side edge function keyed on the
    /// caller's session. Neither that function nor a provisioned project
    /// exists yet, so this throws the same `.missingConfiguration` the
    /// sign-in exchange does; `AuthManager.deleteAccount()` swallows it and
    /// still wipes all on-device data. Once the backend lands, replace the
    /// throw with the edge-function invocation.
    func deleteAccount() async throws {
        // TODO(lumina): replace the throw with the edge-function invocation once a backend project exists.
        _ = try resolvedClient()
        logger.debug("server-side account delete needs a provisioned backend edge function — not yet available")
        throw ServiceError.missingConfiguration
    }

    private func resolvedClient() throws -> SupabaseClient {
        if let client {
            return client
        }
        guard let url, let anonKey, !anonKey.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
        self.client = client
        return client
    }
}
