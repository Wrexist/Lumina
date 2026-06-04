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

    /// Request body for `POST /chart`. Encodes to a flat object — `BirthData`
    /// fields plus an optional `houseSystem`. Delegates to `BirthData`'s own
    /// `Encodable` (which always emits `birthTime` as JSON null when nil),
    /// then layers `houseSystem` on top.
    private struct ChartRequestBody: Encodable {
        enum CodingKeys: String, CodingKey {
            case houseSystem
        }

        let birthData: BirthData
        let houseSystem: HouseSystem?

        func encode(to encoder: any Encoder) throws {
            try birthData.encode(to: encoder)
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(houseSystem, forKey: .houseSystem)
        }
    }

    /// Request body for `POST /transits` — `BirthData` fields plus an
    /// optional `at` moment (omitted means "now" on the server).
    private struct TransitsRequestBody: Encodable {
        enum CodingKeys: String, CodingKey {
            case at
        }

        let birthData: BirthData
        let at: Date?

        func encode(to encoder: any Encoder) throws {
            try birthData.encode(to: encoder)
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(at, forKey: .at)
        }
    }

    /// Request body for `POST /synastry` — the two people to compare.
    private struct SynastryRequestBody: Encodable {
        let personA: SynastryPerson
        let personB: SynastryPerson
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
            if let date = EphemerisService.withFractionalSeconds.date(from: raw) { return date }
            if let date = EphemerisService.withoutFractionalSeconds.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO 8601 date, got \"\(raw)\""
            )
        }
        return decoder
    }()

    // ISO8601DateFormatter isn't Sendable, but parsing is thread-safe, so these
    // shared formatters are safe to read from any isolation.
    nonisolated(unsafe) private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let withoutFractionalSeconds = ISO8601DateFormatter()

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

    func chart(for birthData: BirthData, houseSystem: HouseSystem? = nil) async throws -> NatalChart {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = ChartRequestBody(birthData: birthData, houseSystem: houseSystem)
        let request = try makeChartRequest(baseURL: baseURL, apiSecret: apiSecret, body: body)
        logger.debug("chart requested for \(birthData.placeName, privacy: .public)")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ServiceError.httpError(status: http.statusCode, body: body)
        }
        return try Self.chartDecoder.decode(NatalChart.self, from: data)
    }

    private func makeChartRequest(baseURL: URL, apiSecret: String, body: ChartRequestBody) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("chart"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "X-Lumina-Secret")
        request.httpBody = try Self.chartEncoder.encode(body)
        return request
    }

    /// Transit→natal aspects for `moment` (defaults to "now" on the server).
    /// Real positions only — see CLAUDE.md "Critical Rules". Wire format is
    /// defined in `backend/src/routes/transits.ts`.
    func transits(for birthData: BirthData, at moment: Date? = nil) async throws -> TransitsResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = TransitsRequestBody(birthData: birthData, at: moment)
        var request = URLRequest(url: baseURL.appendingPathComponent("transits"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "X-Lumina-Secret")
        request.httpBody = try Self.chartEncoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw ServiceError.httpError(status: http.statusCode, body: errorBody)
        }
        return try Self.chartDecoder.decode(TransitsResult.self, from: data)
    }

    /// Synastry (relationship) cross-aspects between two people's charts.
    /// Real positions only — see CLAUDE.md "Critical Rules". Wire format is
    /// defined in `backend/src/routes/synastry.ts`.
    func synastry(personA: SynastryPerson, personB: SynastryPerson) async throws -> SynastryResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = SynastryRequestBody(personA: personA, personB: personB)
        var request = URLRequest(url: baseURL.appendingPathComponent("synastry"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "X-Lumina-Secret")
        request.httpBody = try Self.chartEncoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw ServiceError.httpError(status: http.statusCode, body: errorBody)
        }
        return try Self.chartDecoder.decode(SynastryResult.self, from: data)
    }
}
