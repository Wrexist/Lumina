import AuthenticationServices
import Foundation
import OSLog
import UIKit

/// Sign in with Apple session manager. Mirrors the `AppLock` /
/// `NotificationPermission` shape: a `@MainActor @Observable` singleton the
/// rest of the app reads/observes directly.
///
/// This manager is fully self-contained at the on-device level — it works
/// standalone (Keychain-backed session, no network) even before a Supabase
/// project exists. `SupabaseAuthService` is a separate, optional exchange
/// step layered on top; see `signIn()` below for how the two are stitched
/// together without letting a missing backend break local sign-in.
@MainActor
@Observable
final class AuthManager {
    enum AuthError: Error, Equatable, Sendable {
        case invalidCredential
        case authorization(String)
        case noPresentationAnchor
    }

    static let shared = AuthManager()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "AuthManager")
    private let keychain: KeychainStore
    private let supabaseAuthService: SupabaseAuthService

    private(set) var session: AuthSession?

    init(keychain: KeychainStore = KeychainStore(), supabaseAuthService: SupabaseAuthService = SupabaseAuthService()) {
        self.keychain = keychain
        self.supabaseAuthService = supabaseAuthService
    }

    /// Drives the native Sign in with Apple sheet. On success, persists the
    /// resulting `AuthSession` to Keychain, updates `session`, and returns it.
    ///
    /// Apple only supplies `email`/`fullName` on the *first* authorization
    /// for a given user — if we already have a persisted session for the
    /// same `appleUserIdentifier`, the previously-known values are merged in
    /// rather than clobbered with the `nil`s a repeat sign-in returns.
    func signIn() async throws -> AuthSession {
        // Resolve the presentation anchor on the main actor, where a window
        // reliably exists (this is only called from a visible sign-in sheet),
        // and pass it into the coordinator — avoiding reconstructing a window
        // in the delegate (iOS 26 deprecates every `UIWindow` initializer
        // except `init(windowScene:)`).
        guard let anchor = Self.presentationAnchor() else {
            throw AuthError.noPresentationAnchor
        }

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let coordinator = AppleSignInCoordinator(anchor: anchor)
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator

        let credential = try await coordinator.perform(controller)
        let newSession = mergedSession(from: credential)
        try persist(newSession)
        session = newSession

        let identityToken = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
        await exchangeWithSupabase(idToken: identityToken)
        return newSession
    }

    /// Builds the `AuthSession`, merging in any previously-known email/name for
    /// the same Apple user — Apple only supplies those on the *first*
    /// authorization, so a repeat sign-in returns `nil`s we must not clobber.
    private func mergedSession(from credential: AppleIDCredentialResult) -> AuthSession {
        let userIdentifier = credential.userIdentifier
        var previousEmail: String?
        var previousDisplayName: String?
        if let existing = session, existing.appleUserIdentifier == userIdentifier {
            previousEmail = existing.email
            previousDisplayName = existing.displayName
        } else if let stored = try? keychain.load(),
                  let decoded = try? Self.decoder.decode(AuthSession.self, from: stored),
                  decoded.appleUserIdentifier == userIdentifier {
            previousEmail = decoded.email
            previousDisplayName = decoded.displayName
        }
        return AuthSession(
            appleUserIdentifier: userIdentifier,
            email: credential.email ?? previousEmail,
            displayName: Self.displayName(from: credential.fullName) ?? previousDisplayName,
            createdAt: Date()
        )
    }

    /// Best-effort backend exchange. A missing Supabase project (no token yet)
    /// is an expected, dev-safe condition — local sign-in already succeeded and
    /// is meaningful on its own, so that specific failure is swallowed; any
    /// other failure is logged, never surfaced (the on-device sign-in stands).
    ///
    /// NOTE: no `nonce` is passed. Once Supabase exists, generate a random
    /// nonce, set its SHA256 digest on `request.nonce` in `signIn()`, and pass
    /// the raw value here for full replay protection.
    private func exchangeWithSupabase(idToken: String?) async {
        do {
            try await supabaseAuthService.signInWithApple(idToken: idToken, nonce: nil)
        } catch SupabaseAuthService.ServiceError.missingConfiguration {
            logger.debug("Supabase not configured yet (or no identity token available) — local sign-in only.")
        } catch {
            logger.error("Supabase sign-in exchange failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Loads any persisted session from Keychain, then asks Apple whether
    /// that user's authorization is still valid. Clears both the in-memory
    /// session and the Keychain entry if Apple reports `.revoked` or
    /// `.notFound` (the user revoked Sign in with Apple in iOS Settings).
    ///
    /// Exposed as a plain async method so it can be called once at app
    /// launch and again from `signOut()` — call sites outside this file
    /// (e.g. `AppDelegate`) are wired by whoever owns those files.
    func restoreSessionIfAvailable() async {
        guard let data = try? keychain.load(), let stored = try? Self.decoder.decode(AuthSession.self, from: data) else {
            session = nil
            return
        }
        session = stored

        let state: ASAuthorizationAppleIDProvider.CredentialState
        do {
            state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: stored.appleUserIdentifier)
        } catch {
            logger.error("credentialState lookup failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        switch state {
        case .revoked, .notFound:
            logger.debug("Apple credential no longer valid — clearing local session.")
            clearLocalSession()
        case .authorized, .transferred:
            break
        @unknown default:
            break
        }
    }

    /// Clears the local session only. Per `ROADMAP.md`, sign-out never
    /// touches local SwiftData (journal, friends, chart) — that's a
    /// deliberate product decision, not something to "fix" here.
    func signOut() {
        clearLocalSession()
    }

    private func persist(_ session: AuthSession) throws {
        let data = try Self.encoder.encode(session)
        try keychain.save(data)
    }

    private func clearLocalSession() {
        // Delete the persisted session first; only drop the in-memory copy once
        // the Keychain entry is actually gone. Clearing `session` on a failed
        // delete would let the old session restore on next launch.
        do {
            try keychain.delete()
            session = nil
        } catch {
            logger.error("failed to clear Keychain auth session: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func displayName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatted = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
        return formatted.isEmpty ? nil : formatted
    }

    /// The window to anchor the Sign in with Apple sheet on. Uses only the
    /// non-deprecated scene-based window lookup (iOS 26 deprecates every
    /// `UIWindow` initializer except `init(windowScene:)`), so there is no
    /// fabricated-window fallback: a genuinely window-less app can't present
    /// the sheet, and `signIn()` throws `.noPresentationAnchor` instead.
    private static func presentationAnchor() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
}

/// The handful of fields `AuthManager.signIn()` needs out of an
/// `ASAuthorizationAppleIDCredential`, extracted into a plain `Sendable`
/// value inside the `nonisolated` delegate callback. `ASAuthorization` /
/// `ASAuthorizationAppleIDCredential` are Objective-C types that aren't
/// themselves `Sendable`, so — exactly like `BirthPlaceSearch` mapping
/// `MKLocalSearchCompleter.results` to `[Suggestion]` before hopping actors
/// — we pull out only the data we need before crossing back to the
/// `@MainActor` continuation.
private struct AppleIDCredentialResult: Sendable {
    let userIdentifier: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: Data?
}

/// `nonisolated` bridge between `ASAuthorizationControllerDelegate` (called
/// back on an arbitrary queue) and the `@MainActor` caller, mirroring
/// `BirthPlaceSearch`'s `MKLocalSearchCompleter` delegate-isolation pattern:
/// the delegate methods are `nonisolated`, capture only `Sendable` values,
/// and hop back via a continuation rather than touching actor-isolated
/// state directly.
private final class AppleSignInCoordinator: NSObject, @unchecked Sendable {
    /// Resolved on the main actor in `AuthManager.signIn()` and only read back
    /// (never mutated), so exposing it to the `nonisolated`
    /// `presentationAnchor(for:)` is safe under the type's `@unchecked Sendable`.
    private let anchor: ASPresentationAnchor
    private var continuation: CheckedContinuation<AppleIDCredentialResult, any Error>?

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
        super.init()
    }

    /// Runs the controller and suspends until the delegate callback fires.
    /// Each coordinator instance is used for exactly one authorization
    /// request, so a single stored continuation is safe.
    func perform(_ controller: ASAuthorizationController) async throws -> AppleIDCredentialResult {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in
                self.finish(.failure(AuthManager.AuthError.invalidCredential))
            }
            return
        }
        let result = AppleIDCredentialResult(
            userIdentifier: appleIDCredential.user,
            email: appleIDCredential.email,
            fullName: appleIDCredential.fullName,
            identityToken: appleIDCredential.identityToken
        )
        Task { @MainActor in
            self.finish(.success(result))
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.finish(.failure(AuthManager.AuthError.authorization(message)))
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // The anchor was resolved on the main actor at init; just hand it back.
        anchor
    }
}

extension AppleSignInCoordinator {
    /// Resolves the stored continuation exactly once. Called only from the
    /// `@MainActor` hops above, so touching `continuation` here is safe even
    /// though the type itself is `@unchecked Sendable`.
    @MainActor
    func finish(_ result: Result<AppleIDCredentialResult, any Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }
}
