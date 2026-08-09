import Foundation
import OSLog

// MARK: - Request bodies
//
// File-private request payloads, kept out of the actor body so the actor stays
// focused on the API surface (and under the type-body-length budget). Each
// encodes to the flat object the matching backend route expects, omitting nil
// optional keys (the routes treat them as optional, not nullable).

/// `POST /chart` — `BirthData` fields plus an optional `houseSystem`.
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

/// `POST /transits` — `BirthData` plus an optional `at` moment.
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

/// `POST /synastry` — the two people to compare.
private struct SynastryRequestBody: Encodable {
    let personA: SynastryPerson
    let personB: SynastryPerson
}

/// `POST /moon` and `POST /retrogrades` — an optional `at` moment.
private struct MoonRequestBody: Encodable {
    enum CodingKeys: String, CodingKey {
        case at
    }

    let at: Date?

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(at, forKey: .at)
    }
}

/// `POST /progressions` — `BirthData` plus an optional target date (`on`).
private struct ProgressionsRequestBody: Encodable {
    enum CodingKeys: String, CodingKey {
        case on
    }

    let birthData: BirthData
    let on: Date?

    func encode(to encoder: any Encoder) throws {
        try birthData.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(on, forKey: .on)
    }
}

/// `POST /returns` — `BirthData` plus an optional window start (`from`).
private struct ReturnsRequestBody: Encodable {
    enum CodingKeys: String, CodingKey {
        case from
    }

    let birthData: BirthData
    let from: Date?

    func encode(to encoder: any Encoder) throws {
        try birthData.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(from, forKey: .from)
    }
}

/// `POST /forecast` — `BirthData` plus the window (`from` + `days`).
private struct ForecastRequestBody: Encodable {
    enum CodingKeys: String, CodingKey {
        case from
        case days
    }

    let birthData: BirthData
    let from: Date?
    let days: Int?

    func encode(to encoder: any Encoder) throws {
        try birthData.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(from, forKey: .from)
        try container.encodeIfPresent(days, forKey: .days)
    }
}

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
        // `BuildConfig.realValue` filters unexpanded "$(…)" xcconfig
        // placeholders, so an unwired build throws `.missingConfiguration`
        // instead of sending the literal placeholder as a credential.
        self.baseURL = BuildConfig.realValue(infoPlist["LuminaSwissEphServiceURL"] as? String)
            .flatMap(URL.init(string:))
        self.apiSecret = BuildConfig.realValue(infoPlist["LuminaSwissEphAPISecret"] as? String)
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
        let request = try makeRequest(path: "chart", baseURL: baseURL, apiSecret: apiSecret, body: body)
        logger.debug("chart requested for \(birthData.placeName, privacy: .public)")

        return try await send(request, as: NatalChart.self)
    }

    /// Per-attempt timeouts. They sum, with `retryDelay` between them, to the
    /// same ten seconds `docs/NAVIGATION.md` §12 allows before the UI must
    /// show an error with a retry — the retry happens *inside* that budget,
    /// it does not extend it.
    nonisolated static let attemptTimeouts: [TimeInterval] = [4, 5]

    /// Long enough for a suspended container to finish booting, short enough
    /// to leave the second attempt most of the budget.
    nonisolated static let retryDelay: Duration = .seconds(1)

    /// Sends the request, retrying once through the transient failures a
    /// scale-to-zero host produces while it wakes up.
    ///
    /// There was no retry at all: one 10-second attempt, and any blip failed
    /// the call. On a host that suspends when idle, the first launch of the
    /// day therefore errored on Today, Chart, People and Reflect at once, and
    /// the only available fix was to pay for a permanently warm machine.
    ///
    /// Only genuinely transient conditions retry — a timeout, a refused or
    /// dropped connection, and the 502/503/504 a proxy returns while the
    /// instance behind it boots. A 401 or a 400 never retries; those are
    /// wrong, not early. Neither does a decode failure.
    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        var lastError: any Error = ServiceError.invalidResponse
        for (attempt, timeout) in Self.attemptTimeouts.enumerated() {
            if attempt > 0 {
                try? await Task.sleep(for: Self.retryDelay)
                logger.debug("retrying \(request.url?.lastPathComponent ?? "request", privacy: .public)")
            }
            var attemptRequest = request
            attemptRequest.timeoutInterval = timeout
            do {
                let (data, response) = try await session.data(for: attemptRequest)
                guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
                guard (200..<300).contains(http.statusCode) else {
                    let errorBody = String(data: data, encoding: .utf8) ?? ""
                    let failure = ServiceError.httpError(status: http.statusCode, body: errorBody)
                    guard Self.isWaking(status: http.statusCode) else { throw failure }
                    lastError = failure
                    continue
                }
                return try Self.chartDecoder.decode(T.self, from: data)
            } catch let error as URLError where Self.isTransient(error) {
                lastError = error
            }
        }
        throw lastError
    }

    /// Transport failures that a second attempt can plausibly fix.
    /// `.notConnectedToInternet` is deliberately absent — the device is
    /// offline, and retrying only delays telling the user so.
    nonisolated static func isTransient(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .cannotConnectToHost, .networkConnectionLost, .cannotFindHost, .dnsLookupFailed:
            true
        default:
            false
        }
    }

    /// What a load balancer answers while the instance behind it is booting.
    nonisolated static func isWaking(status: Int) -> Bool {
        [502, 503, 504].contains(status)
    }

    /// Builds the authenticated JSON POST every route shares. The timeout is
    /// set per attempt in `send(_:as:)`, which owns the §12 budget.
    private func makeRequest(path: String, baseURL: URL, apiSecret: String, body: some Encodable) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
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
        let request = try makeRequest(path: "transits", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: TransitsResult.self)
    }

    /// Synastry (relationship) cross-aspects between two people's charts.
    /// Real positions only — see CLAUDE.md "Critical Rules". Wire format is
    /// defined in `backend/src/routes/synastry.ts`.
    func synastry(personA: SynastryPerson, personB: SynastryPerson) async throws -> SynastryResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = SynastryRequestBody(personA: personA, personB: personB)
        let request = try makeRequest(path: "synastry", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: SynastryResult.self)
    }

    /// The composite (midpoint) relationship chart of two people — a single
    /// merged chart. Reuses the two-person synastry payload. Real positions
    /// only. Wire format: `backend/src/routes/composite.ts`.
    func composite(personA: SynastryPerson, personB: SynastryPerson) async throws -> CompositeResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = SynastryRequestBody(personA: personA, personB: personB)
        let request = try makeRequest(path: "composite", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: CompositeResult.self)
    }

    /// Tonight's Moon — phase, illumination, next new/full. Global sky data
    /// (no birth input). Wire format: `backend/src/routes/moon.ts`.
    func moonPhase(at moment: Date? = nil) async throws -> MoonPhaseResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = MoonRequestBody(at: moment)
        let request = try makeRequest(path: "moon", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: MoonPhaseResult.self)
    }

    /// Which bodies are retrograde now and when each next stations. Global sky
    /// data (no birth input). Wire format: `backend/src/routes/retrogrades.ts`.
    func retrogrades(at moment: Date? = nil) async throws -> RetrogradesResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = MoonRequestBody(at: moment)
        let request = try makeRequest(path: "retrogrades", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: RetrogradesResult.self)
    }

    /// The secondary-progressed chart for `date` (defaults to now). Real
    /// positions only. Wire format: `backend/src/routes/progressions.ts`.
    func progressions(for birthData: BirthData, on date: Date? = nil) async throws -> ProgressionsResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = ProgressionsRequestBody(birthData: birthData, on: date)
        let request = try makeRequest(path: "progressions", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: ProgressionsResult.self)
    }

    /// Upcoming Jupiter and Saturn returns to the natal chart (from `from`,
    /// default now). Real positions. Wire format: `backend/src/routes/returns.ts`.
    func returns(for birthData: BirthData, from: Date? = nil) async throws -> ReturnsResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = ReturnsRequestBody(birthData: birthData, from: from)
        let request = try makeRequest(path: "returns", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: ReturnsResult.self)
    }

    /// Upcoming exact transit dates over a window (default 30 days from now).
    /// Real positions only. Wire format: `backend/src/routes/forecast.ts`.
    func forecast(for birthData: BirthData, from: Date? = nil, days: Int? = nil) async throws -> ForecastResult {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ServiceError.missingConfiguration
        }
        let body = ForecastRequestBody(birthData: birthData, from: from, days: days)
        let request = try makeRequest(path: "forecast", baseURL: baseURL, apiSecret: apiSecret, body: body)

        return try await send(request, as: ForecastResult.self)
    }
}
