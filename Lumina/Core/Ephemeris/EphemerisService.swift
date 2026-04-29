import Foundation
import OSLog

/// Calls the self-hosted Swiss Ephemeris microservice. **Never** ask the LLM
/// to compute planetary positions — see CLAUDE.md "Critical Rules".
actor EphemerisService {
    enum ServiceError: Error {
        case notImplemented
        case invalidResponse
        case missingConfiguration
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Ephemeris")
    private let session: URLSession
    private let baseURL: URL?
    private let apiSecret: String?

    init(session: URLSession = .shared, infoPlist: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        self.session = session
        self.baseURL = (infoPlist["LuminaSwissEphServiceURL"] as? String).flatMap(URL.init(string:))
        self.apiSecret = infoPlist["LuminaSwissEphAPISecret"] as? String
    }

    func chart(for birthData: BirthData) async throws -> NatalChart {
        // TODO(lumina): POST /chart to baseURL with birthData; decode NatalChart.
        logger.debug("chart requested for \(birthData.placeName, privacy: .public)")
        throw ServiceError.notImplemented
    }
}
