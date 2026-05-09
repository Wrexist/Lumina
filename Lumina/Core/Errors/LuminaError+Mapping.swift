import Foundation

/// Maps service-layer errors into `LuminaError` so views never see raw
/// network or HTTP error types. Add a new mapping every time a service
/// throws a typed error — never let an `Error` leak into a View.
extension LuminaError {
    /// Wraps any caught `Error` into the closest matching `LuminaError`.
    /// Falls through to `.unknown(...)` so we always present *something*
    /// human, but the case-by-case mappings should cover production paths.
    static func from(_ error: Error) -> LuminaError {
        if let luminaError = error as? LuminaError {
            return luminaError
        }
        if let serviceError = error as? EphemerisService.ServiceError {
            return mapEphemeris(serviceError)
        }
        if let urlError = error as? URLError {
            return mapURL(urlError)
        }
        return .unknown(underlyingMessage: error.localizedDescription)
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

    private static func mapURL(_ error: URLError) -> LuminaError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .offline
        case .timedOut:
            return .timeout
        default:
            return .unknown(underlyingMessage: error.localizedDescription)
        }
    }
}
