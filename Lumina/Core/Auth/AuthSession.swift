import Foundation

/// Persisted shape for a completed Sign in with Apple session — kept as a
/// separate `Codable` struct from the live `AuthManager` so the on-disk
/// (Keychain) format can stay stable independent of the manager's own
/// in-memory state, mirroring `OnboardingSnapshot` / `AppRouterStorage`'s
/// persisted-shape pattern elsewhere in this codebase.
///
/// `email` and `displayName` are only ever provided by Apple on the *first*
/// authorization for a given `appleUserIdentifier` — subsequent sign-ins
/// return `nil` for both, so callers must merge rather than overwrite when
/// re-authenticating the same user.
struct AuthSession: Codable, Equatable, Sendable {
    let appleUserIdentifier: String
    var email: String?
    var displayName: String?
    let createdAt: Date
}
