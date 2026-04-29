import Foundation
import OSLog

/// Calls the self-hosted Swiss Ephemeris microservice. **Never** ask the LLM
/// to compute planetary positions — see CLAUDE.md "Critical Rules".
///
/// Wire format and auth are defined in `backend/src/routes/chart.ts`:
/// `POST {baseURL}/chart`, body = `BirthData` JSON, header
/// `X-Lumina-Secret: $LUMINA_API_SECRET`.
actor EphemerisService {
    enum ServiceError: Error, Equatable {
        case missingConfiguration
        case invalidResponse
        case httpError(status: Int, body: String)
        case decoding(message: String)
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Ephemeris")
    private let session: URLSession
    private let baseURL: URL?
    private let apiSecret: String?

    /// Production initializer — reads `LuminaSwissEphServiceURL` and
    /// `LuminaSwissEphAPISecret` from `Info.plist` (populated by xcconfig).
    init(session: URLSession = .shared, infoPlist: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        self.session = session
        self.baseURL = (infoPlist["LuminaSwissEphServiceURL"] as? String).flatMap(URL.init(string:))
        self.apiSecret = infoPlist["LuminaSwissEphAPISecret"] as? String
    }

    /// Test seam — construct directly when injecting a mocked `URLSession`.
    init(session: URLSession, baseURL: URL, apiSecret: String) {
        self.session = session
        self.baseURL = baseURL
        self.apiSecret = apiSecret
    }

    func chart(for birthData: BirthData) async throws -> NatalChart {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let request = try makeChartRequest(baseURL: baseURL, apiSecret: apiSecret, birthData: birthData)
        logger.debug("chart requested for \(birthData.placeName, privacy: .public)")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ServiceError.httpError(status: http.statusCode, body: body)
        }
        return try Self.chartDecoder.decode(NatalChart.self, from: data)
    }

    private func makeChartRequest(baseURL: URL, apiSecret: String, birthData: BirthData) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("chart"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "X-Lumina-Secret")
        request.httpBody = try Self.chartEncoder.encode(birthData)
        return request
    }

    private static let chartEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let chartDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = withFractionalSeconds.date(from: raw) { return date }
            if let date = withoutFractionalSeconds.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO 8601 date, got \"\(raw)\""
            )
        }
        return decoder
    }()

    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let withoutFractionalSeconds = ISO8601DateFormatter()
}
