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

    func testMapsAIMissingAPIKey() {
        let mapped = LuminaError.from(LuminaAIClient.ClientError.missingAPIKey)
        XCTAssertEqual(mapped, .missingConfiguration(key: "AnthropicAPIKey"))
    }

    func testMapsAINotImplementedToUnknown() {
        if case .unknown = LuminaError.from(LuminaAIClient.ClientError.notImplemented) {
            // expected
        } else {
            XCTFail("expected .unknown")
        }
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

    func testMapsUnknownError() {
        struct DummyError: Error, LocalizedError {
            var errorDescription: String? { "boom" }
        }
        if case .unknown(let message) = LuminaError.from(DummyError()) {
            XCTAssertEqual(message, "boom")
        } else {
            XCTFail("expected .unknown")
        }
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
