import Foundation

/// User-facing error wrapper. Every service throw is mapped to one of these
/// before reaching a View, so views never see `URLError(...)` or raw HTTP
/// codes. The user-facing copy lives here, not in the View.
///
/// See `docs/NAVIGATION.md` §1.6 — errors must speak human, must offer a
/// retry, and must never show numeric codes.
enum LuminaError: Error, Equatable, Sendable {
    case offline
    case server(status: Int)
    case timeout
    case notSignedIn
    case subscriptionRequired(feature: String)
    case permissionDenied(kind: PermissionKind)
    case missingConfiguration(key: String)
    case unknown(underlyingMessage: String)

    enum PermissionKind: String, Sendable {
        case camera
        case contacts
        case notifications
        case faceID
        case location
    }

    /// 1-line title shown in the error state hero.
    var userTitle: String {
        switch self {
        case .offline: "You're offline"
        case .server: "Something on our end"
        case .timeout: "That took too long"
        case .notSignedIn: "Sign in to continue"
        case .subscriptionRequired: "Lumina Plus"
        case .permissionDenied(let kind): permissionTitle(kind)
        case .missingConfiguration: "App is mid-setup"
        case .unknown: "Unexpected error"
        }
    }

    /// 1–2 sentences of body copy. No technical jargon, no error codes.
    var userBody: String {
        switch self {
        case .offline:
            return "We can't reach the network right now. Your last reading is saved on this device."
        case .server:
            return "Our chart service hiccupped. Try again in a moment."
        case .timeout:
            return "The connection seems slow. Try again, or come back when you have better signal."
        case .notSignedIn:
            return "Sign in with Apple to keep your chart in sync across devices."
        case .subscriptionRequired(let feature):
            return "\(feature) is part of Lumina Plus. You can keep using everything else for free."
        case .permissionDenied(let kind):
            return permissionBody(kind)
        case .missingConfiguration:
            return "Lumina is finishing setup. Try again in a moment, or get in touch if it persists."
        case .unknown(let message):
            return message.isEmpty ? "Try again, and tell us if it keeps happening." : message
        }
    }

    /// Single short call-to-action verb for the recovery button. Never longer
    /// than 2 words. The View pairs it with a secondary "Not now" / "Close".
    var recoveryActionTitle: String {
        switch self {
        case .offline, .server, .timeout, .unknown, .missingConfiguration: "Try again"
        case .notSignedIn: "Sign in"
        case .subscriptionRequired: "See plans"
        case .permissionDenied: "Open Settings"
        }
    }

    /// Stable analytics key. Never includes user content; used as
    /// `error.<analyticsKey>` event suffix.
    var analyticsKey: String {
        switch self {
        case .offline: "offline"
        case .server: "server"
        case .timeout: "timeout"
        case .notSignedIn: "not_signed_in"
        case .subscriptionRequired: "subscription_required"
        case .permissionDenied(let kind): "permission_denied.\(kind.rawValue)"
        case .missingConfiguration: "missing_configuration"
        case .unknown: "unknown"
        }
    }

    private func permissionTitle(_ kind: PermissionKind) -> String {
        switch kind {
        case .camera: "Camera off"
        case .contacts: "Contacts off"
        case .notifications: "Notifications off"
        case .faceID: "Face ID off"
        case .location: "Location off"
        }
    }

    private func permissionBody(_ kind: PermissionKind) -> String {
        switch kind {
        case .camera:
            return "Lumina needs camera access to scan your hand. We never upload photos — the analysis happens on your phone."
        case .contacts:
            return "We only read names and birthdays from contacts you choose. Nothing leaves your phone."
        case .notifications:
            return "Turn on notifications to get tomorrow morning's reading delivered."
        case .faceID:
            return "Face ID locks your Reflect entries privately on this device."
        case .location:
            return "We only use location to fill in your birth place once. You can also enter it manually."
        }
    }
}
