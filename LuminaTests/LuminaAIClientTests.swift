@testable import Lumina
import XCTest

/// `LuminaAIClient` had no tests at all, despite owning the one network path
/// that carries a shared secret and the one degradation the whole "Ask your
/// chart" screen depends on: a 503 must become `.notConfigured` so the UI
/// falls back to the deterministic answers instead of showing a failure.
///
/// These pin the wire contract (method, path, headers, body shape) and every
/// branch of the response handling.
final class LuminaAIClientTests: XCTestCase {
    private let baseURL = URL(string: "https://eph.test.lumina")!
    private let secret = "test-secret"

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    private func makeClient() -> LuminaAIClient {
        LuminaAIClient(session: MockURLProtocol.session(), baseURL: baseURL, apiSecret: secret)
    }

    private func respond(
        _ status: Int,
        _ json: String,
        inspect: (@Sendable (URLRequest) -> Void)? = nil
    ) {
        let url = baseURL
        MockURLProtocol.handler = { request in
            inspect?(request)
            let response = HTTPURLResponse(
                url: request.url ?? url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
            guard let response else { throw URLError(.badServerResponse) }
            return (response, Data(json.utf8))
        }
    }

    // MARK: - Wire contract

    func testPostsToInterpretWithTheSharedSecretAndGroundedFacts() async throws {
        let seen = RequestBox()
        respond(200, #"{"text":"You lead with warmth."}"#) { seen.store($0) }

        let text = try await makeClient().interpret(
            kind: .placement,
            facts: "Sun in Leo, 5th house",
            question: nil
        )

        XCTAssertEqual(text, "You lead with warmth.")
        let request = try XCTUnwrap(seen.value)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://eph.test.lumina/interpret")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Lumina-Secret"), secret)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(request.bodyData())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["kind"] as? String, "placement")
        XCTAssertEqual(json["facts"] as? String, "Sun in Leo, 5th house")
        // Omitted, not null — the backend schema treats `question` as optional.
        XCTAssertNil(json["question"])
    }

    func testIncludesTheQuestionWhenOneIsAsked() async throws {
        let seen = RequestBox()
        respond(200, #"{"text":"ok"}"#) { seen.store($0) }

        _ = try await makeClient().interpret(kind: .ask, facts: "facts", question: "How do I come across?")

        let body = try XCTUnwrap(seen.value?.bodyData())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["question"] as? String, "How do I come across?")
    }

    /// The timeout is the difference between a retry state and a screen that
    /// hangs for URLSession's 60-second default (docs/NAVIGATION.md §12).
    func testUsesAShortTimeoutRatherThanTheURLSessionDefault() async throws {
        let seen = RequestBox()
        respond(200, #"{"text":"ok"}"#) { seen.store($0) }
        _ = try await makeClient().interpret(kind: .daily, facts: "facts")
        XCTAssertEqual(seen.value?.timeoutInterval, 10)
    }

    // MARK: - Response handling

    func test503BecomesNotConfiguredSoTheUIFallsBackInsteadOfFailing() async {
        respond(503, #"{"error":"anthropic_not_configured"}"#)
        await assertThrows(.notConfigured) {
            try await self.makeClient().interpret(kind: .ask, facts: "facts", question: "q")
        }
    }

    func testOtherHTTPErrorsCarryTheirStatusAndBody() async {
        respond(429, #"{"error":"rate_limited"}"#)
        await assertThrows(.httpError(status: 429, body: #"{"error":"rate_limited"}"#)) {
            try await self.makeClient().interpret(kind: .ask, facts: "facts", question: "q")
        }
    }

    func testMalformedJSONSurfacesAsADecodingFailureNotAnEmptyAnswer() async {
        // The dangerous shape here is a *silent* empty string: the screen would
        // render a blank reading as if the model had said nothing.
        respond(200, #"{"unexpected":"shape"}"#)
        do {
            _ = try await makeClient().interpret(kind: .ask, facts: "facts", question: "q")
            XCTFail("expected a decoding failure")
        } catch is DecodingError {
            // Expected — `LuminaError.from` maps this to honest copy.
        } catch {
            XCTFail("expected DecodingError, got \(error)")
        }
    }

    func testTransportFailurePropagatesAsAURLError() async {
        MockURLProtocol.handler = { _ in throw URLError(.timedOut) }
        do {
            _ = try await makeClient().interpret(kind: .ask, facts: "facts", question: "q")
            XCTFail("expected a URLError")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .timedOut)
        } catch {
            XCTFail("expected URLError, got \(error)")
        }
    }

    // MARK: - Configuration

    func testUnwiredBuildThrowsMissingConfigurationAndNeverSendsARequest() async {
        MockURLProtocol.handler = { _ in
            XCTFail("an unconfigured client must not reach the network")
            throw URLError(.badServerResponse)
        }
        let client = LuminaAIClient(session: MockURLProtocol.session(), infoPlist: [:])
        XCTAssertFalse(client.isConfigured)
        await assertThrows(.missingConfiguration) {
            try await client.interpret(kind: .ask, facts: "facts", question: "q")
        }
    }

    /// `BuildConfig.realValue` filters unexpanded xcconfig placeholders, so a
    /// build whose secrets were never injected must not send the literal
    /// `$(LUMINA_...)` string as a credential.
    func testUnexpandedXcconfigPlaceholdersAreNotTreatedAsConfiguration() {
        let client = LuminaAIClient(
            session: MockURLProtocol.session(),
            infoPlist: [
                "LuminaSwissEphServiceURL": "$(LUMINA_SWISS_EPH_SERVICE_URL)",
                "LuminaSwissEphAPISecret": "$(LUMINA_SWISS_EPH_API_SECRET)",
            ]
        )
        XCTAssertFalse(client.isConfigured)
    }

    // MARK: - Helpers

    private func assertThrows(
        _ expected: LuminaAIClient.ClientError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: @escaping () async throws -> String
    ) async {
        do {
            _ = try await operation()
            XCTFail("expected \(expected)", file: file, line: line)
        } catch let error as LuminaAIClient.ClientError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("expected \(expected), got \(error)", file: file, line: line)
        }
    }
}

/// Captures the request the mock protocol saw. The handler is `@Sendable`, so
/// the capture needs a reference type rather than an inout local.
private final class RequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: URLRequest?

    var value: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func store(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        stored = request
    }
}
