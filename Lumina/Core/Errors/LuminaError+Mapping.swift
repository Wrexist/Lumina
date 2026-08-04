import Foundation

/// Maps service-layer errors into `LuminaError` so views never see raw
/// network or HTTP error types. Add a new mapping every time a service
/// throws a typed error — never let an `Error` leak into a View.
extension LuminaError {
    /// Wraps any caught `Error` into the closest matching `LuminaError`.
    /// Falls through to `.unknown(...)` so we always present *something*
    /// human, but the case-by-case mappings should cover production paths.
    static func from(_ error: any Error) -> LuminaError {
        if let luminaError = error as? LuminaError {
            return luminaError
        }
        if let serviceError = error as? EphemerisService.ServiceError {
            return mapEphemeris(serviceError)
        }
        if let aiError = error as? LuminaAIClient.ClientError {
            return mapAI(aiError)
        }
        if let authError = error as? AuthManager.AuthError {
            return mapAuth(authError)
        }
        if let lockError = error as? AppLock.LockError {
            return mapLock(lockError)
        }
        if let managerError = error as? IAPManager.ManagerError {
            return mapIAP(managerError)
        }
        if error is KeychainStore.StoreError {
            // Never surface the raw OSStatus — no numeric codes in copy.
            return .unknown(underlyingMessage: "We couldn't securely save your session on this device. Try again.")
        }
        if error is SupabaseAuthService.ServiceError {
            return .missingConfiguration(key: "SupabaseURL")
        }
        if error is DecodingError {
            // A decode failure is *our* parsing, not the server erroring —
            // don't dress it up as an HTTP status.
            return .unknown(underlyingMessage: "We couldn't read the server's response. Try again in a moment.")
        }
        if let urlError = error as? URLError {
            return mapURL(urlError)
        }
        // Same rule as `mapURL`'s default: a Foundation/NSError description
        // is developer text, not user copy.
        return .unknown(underlyingMessage: "Something went wrong. Try again, and tell us if it keeps happening.")
    }

    private static func mapAuth(_ error: AuthManager.AuthError) -> LuminaError {
        switch error {
        case .invalidCredential:
            return .unknown(underlyingMessage: "Apple sent back a sign-in we couldn't verify. Please try again.")
        case .authorization:
            return .unknown(underlyingMessage: "Sign in with Apple didn't complete. Please try again.")
        case .noPresentationAnchor:
            return .unknown(underlyingMessage: "We couldn't open the sign-in window. Please try again.")
        }
    }

    private static func mapLock(_ error: AppLock.LockError) -> LuminaError {
        switch error {
        case .notEnrolled, .unavailable:
            return .permissionDenied(kind: .faceID)
        case .userCancelled:
            return .unknown(underlyingMessage: "Unlock was cancelled. Try again when you're ready.")
        case .failed:
            return .unknown(underlyingMessage: "Face ID couldn't verify you this time. Please try again.")
        }
    }

    private static func mapIAP(_ error: IAPManager.ManagerError) -> LuminaError {
        switch error {
        case .notConfigured:
            return .missingConfiguration(key: "RevenueCatAPIKey")
        case .noOfferingsAvailable:
            return .unknown(underlyingMessage: "Subscription plans aren't available right now. Try again shortly.")
        case .planUnavailable(let plan):
            // The paywall offered a plan the current offering doesn't sell.
            // Say so rather than silently charging for a different one — the
            // old code substituted the annual package for whatever was
            // selected, so the user paid a price they were never shown.
            let period = plan == .monthly ? "monthly" : "annual"
            return .unknown(underlyingMessage: "The \(period) plan isn't available right now. Try the other option, or check back shortly.")
        }
    }

    private static func mapEphemeris(_ error: EphemerisService.ServiceError) -> LuminaError {
        switch error {
        case .missingConfiguration:
            return .missingConfiguration(key: "SwissEphServiceURL")
        case .invalidResponse:
            return .server(status: 0)
        case .httpError(let status, _):
            return .server(status: status)
        case .decoding:
            return .server(status: 422)
        }
    }

    private static func mapAI(_ error: LuminaAIClient.ClientError) -> LuminaError {
        switch error {
        case .missingConfiguration:
            return .missingConfiguration(key: "SwissEphServiceURL")
        case .notConfigured:
            // Server has no Anthropic key yet — surfaced to the user as a gentle
            // "coming soon", never a hard failure.
            return .missingConfiguration(key: "AnthropicAPIKey")
        case .invalidResponse:
            return .server(status: 0)
        case .httpError(let status, _):
            return .server(status: status)
        }
    }

    private static func mapURL(_ error: URLError) -> LuminaError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .offline
        case .timedOut:
            return .timeout
        // These are all common in production and used to fall through to
        // `error.localizedDescription`, which is rendered verbatim as the
        // app's own body copy — so users saw Foundation strings like
        // "A server with the specified hostname could not be found."
        // docs/NAVIGATION.md §4 says we never show error codes; this is the
        // same class of leak one layer up.
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .unknown(underlyingMessage: "We couldn't reach Lumina's sky service. Try again in a moment.")
        case .secureConnectionFailed, .serverCertificateUntrusted,
             .serverCertificateHasBadDate, .serverCertificateNotYetValid,
             .serverCertificateHasUnknownRoot:
            return .unknown(underlyingMessage: "We couldn't make a secure connection. Check your network and try again.")
        case .badServerResponse, .cannotParseResponse, .zeroByteResource,
             .resourceUnavailable:
            return .unknown(underlyingMessage: "The sky service sent something we couldn't read. Try again in a moment.")
        case .internationalRoamingOff, .callIsActive:
            return .offline
        default:
            // Never `error.localizedDescription` — `userBody` renders it
            // verbatim as the app's own copy. Callers log the raw error.
            return .unknown(underlyingMessage: "Something went wrong reaching the sky service. Try again in a moment.")
        }
    }
}
