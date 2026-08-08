@testable import Lumina
import XCTest

/// Smoke tests for Phase-1 design tokens and error mapping. These run on
/// every CI build — any drift in token values, error mapping, or analytics
/// keys fails the merge.
final class DesignTokensAndErrorTests: XCTestCase {
    // MARK: - LuminaRadii

    func testRadiiAreMonotonic() {
        XCTAssertLessThan(LuminaRadii.xs, LuminaRadii.sm)
        XCTAssertLessThan(LuminaRadii.sm, LuminaRadii.md)
        XCTAssertLessThan(LuminaRadii.md, LuminaRadii.lg)
        XCTAssertLessThan(LuminaRadii.lg, LuminaRadii.pill)
    }

    func testRadiiSpecificValues() {
        XCTAssertEqual(LuminaRadii.xs, 6)
        XCTAssertEqual(LuminaRadii.sm, 10)
        XCTAssertEqual(LuminaRadii.md, 16)
        XCTAssertEqual(LuminaRadii.lg, 24)
        XCTAssertEqual(LuminaRadii.pill, 999)
    }

    // MARK: - LuminaError mapping

    func testMapsEphemerisMissingConfiguration() {
        let mapped = LuminaError.from(EphemerisService.ServiceError.missingConfiguration)
        XCTAssertEqual(mapped, .missingConfiguration(key: "SwissEphServiceURL"))
    }

    func testMapsEphemerisHTTPError() {
        let mapped = LuminaError.from(EphemerisService.ServiceError.httpError(status: 500, body: ""))
        XCTAssertEqual(mapped, .server(status: 500))
    }

    func testMapsEphemerisDecodingErrorToUnprocessable() {
        let mapped = LuminaError.from(EphemerisService.ServiceError.decoding(message: "x"))
        XCTAssertEqual(mapped, .server(status: 422))
    }

    func testMapsAINotConfiguredToAnthropicKey() {
        let mapped = LuminaError.from(LuminaAIClient.ClientError.notConfigured)
        XCTAssertEqual(mapped, .missingConfiguration(key: "AnthropicAPIKey"))
    }

    func testMapsAIMissingConfigurationToBackend() {
        let mapped = LuminaError.from(LuminaAIClient.ClientError.missingConfiguration)
        XCTAssertEqual(mapped, .missingConfiguration(key: "SwissEphServiceURL"))
    }

    func testMapsAIHTTPErrorToServerStatus() {
        let mapped = LuminaError.from(LuminaAIClient.ClientError.httpError(status: 502, body: ""))
        XCTAssertEqual(mapped, .server(status: 502))
    }

    func testMapsAIInvalidResponse() {
        let mapped = LuminaError.from(LuminaAIClient.ClientError.invalidResponse)
        XCTAssertEqual(mapped, .server(status: 0))
    }

    func testMapsURLOfflineErrors() {
        let offline = URLError(.notConnectedToInternet)
        XCTAssertEqual(LuminaError.from(offline), .offline)

        let dropped = URLError(.networkConnectionLost)
        XCTAssertEqual(LuminaError.from(dropped), .offline)
    }

    func testMapsURLTimeoutToTimeout() {
        XCTAssertEqual(LuminaError.from(URLError(.timedOut)), .timeout)
    }

    /// An unrecognised error must become *our* copy, never the underlying
    /// framework's. `userBody` renders this string verbatim as the app's own
    /// body text, so passing `localizedDescription` through put Foundation
    /// sentences like "A server with the specified hostname could not be
    /// found." on screen as if Lumina had written them. This test used to
    /// assert exactly that leak.
    func testMapsUnknownErrorToOurOwnCopyNotTheUnderlyingDescription() {
        struct DummyError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        guard case .unknown(let message) = LuminaError.from(DummyError()) else {
            return XCTFail("expected .unknown")
        }
        XCTAssertFalse(message.contains("boom"), "developer text must not reach the user")
        XCTAssertFalse(message.isEmpty)
        // And it has to read like something a person wrote.
        XCTAssertTrue(message.hasSuffix("."), "user copy is a sentence")
    }

    func testPassesThroughExistingLuminaError() {
        let original: LuminaError = .subscriptionRequired(feature: "Audio")
        XCTAssertEqual(LuminaError.from(original), original)
    }

    // MARK: - Analytics keys

    func testAnalyticsKeysAreUnique() {
        let cases: [LuminaError] = [
            .offline,
            .server(status: 500),
            .timeout,
            .notSignedIn,
            .subscriptionRequired(feature: "X"),
            .permissionDenied(kind: .camera),
            .missingConfiguration(key: "Y"),
            .unknown(underlyingMessage: "Z"),
        ]
        let keys = cases.map(\.analyticsKey)
        XCTAssertEqual(Set(keys).count, keys.count, "analyticsKey collision: \(keys)")
    }
}
