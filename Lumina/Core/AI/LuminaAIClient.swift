import Foundation
import OSLog

/// The kind of interpretation requested from the backend `/interpret` route.
enum InterpretKind: String, Sendable, Encodable {
    case ask
    case daily
    case placement
}

/// `POST /interpret` body. `question` is omitted when nil — the backend schema
/// treats it as optional (absent), not nullable.
private struct InterpretRequestBody: Encodable {
    enum CodingKeys: String, CodingKey {
        case kind
        case facts
        case question
    }

    let kind: InterpretKind
    let facts: String
    let question: String?

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)
        try container.encode(facts, forKey: .facts)
        try container.encodeIfPresent(question, forKey: .question)
    }
}

private struct InterpretResponse: Decodable {
    let text: String
}

/// Client for Lumina's interpretive content. Interpretation is grounded and
/// runs **server-side**: the app POSTs already-computed chart facts to the
/// Lumina backend, which holds the Anthropic key. The key is deliberately NOT
/// in the app bundle — a client-side key is trivially extractable from the
/// IPA. See docs/AUDIT-2026-06-03.md R2 and backend/src/routes/interpret.ts.
///
/// Reuses the same backend + shared secret as `EphemerisService`
/// (`LuminaSwissEphServiceURL` / `LuminaSwissEphAPISecret`).
actor LuminaAIClient {
    enum ClientError: Error, Equatable {
        /// The app has no backend URL/secret (dev / simulator builds).
        case missingConfiguration
        /// The server has no Anthropic key yet (HTTP 503) — degrade gracefully.
        case notConfigured
        case invalidResponse
        case httpError(status: Int, body: String)
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "AI")
    private let session: URLSession
    private nonisolated let baseURL: URL?
    private nonisolated let apiSecret: String?

    /// Production initializer — reads the shared backend config from
    /// `Info.plist` (populated by xcconfig), same as `EphemerisService`.
    init(session: URLSession = .shared, infoPlist: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        self.session = session
        self.baseURL = (infoPlist["LuminaSwissEphServiceURL"] as? String).flatMap(URL.init(string:))
        self.apiSecret = infoPlist["LuminaSwissEphAPISecret"] as? String
    }

    /// Test seam — inject a mocked `URLSession` and explicit config.
    init(session: URLSession, baseURL: URL, apiSecret: String) {
        self.session = session
        self.baseURL = baseURL
        self.apiSecret = apiSecret
    }

    /// Whether the app is wired to a backend at all. Not whether the server has
    /// an Anthropic key — that surfaces as `.notConfigured` at call time.
    nonisolated var isConfigured: Bool {
        baseURL != nil && !(apiSecret ?? "").isEmpty
    }

    /// Free-text "ask your chart", grounded on the real chart facts.
    func ask(_ question: String, chart: NatalChart) async throws -> String {
        try await interpret(kind: .ask, facts: ChartFacts.summary(of: chart), question: question)
    }

    /// Core call. Throws `ClientError`; `.notConfigured` on a 503 so callers can
    /// fall back to the deterministic grounded answers.
    func interpret(kind: InterpretKind, facts: String, question: String? = nil) async throws -> String {
        guard let baseURL, let apiSecret, !apiSecret.isEmpty else {
            throw ClientError.missingConfiguration
        }
        let body = InterpretRequestBody(kind: kind, facts: facts, question: question)
        var request = URLRequest(url: baseURL.appendingPathComponent("interpret"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiSecret, forHTTPHeaderField: "X-Lumina-Secret")
        request.httpBody = try Self.encoder.encode(body)
        logger.debug("interpret requested (kind: \(kind.rawValue, privacy: .public))")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
        if http.statusCode == 503 { throw ClientError.notConfigured }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.httpError(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        return try Self.decoder.decode(InterpretResponse.self, from: data).text
    }
}
