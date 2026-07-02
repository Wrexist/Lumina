@testable import Lumina
import XCTest

/// Guards the xcconfig-placeholder config filter and the newer `LuminaError`
/// mappings. An unexpanded `$(…)` placeholder passing a config guard means
/// the app sends garbage credentials to the backend — any drift here fails
/// the merge.
final class BuildConfigAndErrorMappingTests: XCTestCase {
    // MARK: - BuildConfig.realValue

    func testRealValueRejectsNil() {
        XCTAssertNil(BuildConfig.realValue(nil))
    }

    func testRealValueRejectsEmpty() {
        XCTAssertNil(BuildConfig.realValue(""))
    }

    func testRealValueRejectsUnexpandedXcconfigPlaceholder() {
        XCTAssertNil(BuildConfig.realValue("$(FOO)"))
        XCTAssertNil(BuildConfig.realValue("$(SWISS_EPH_API_SECRET)"))
    }

    func testRealValuePassesRealValuesThroughUnchanged() {
        XCTAssertEqual(BuildConfig.realValue("https://api.example.com"), "https://api.example.com")
        XCTAssertEqual(BuildConfig.realValue("s3cret-value"), "s3cret-value")
    }

    // MARK: - DecodingError mapping

    func testMapsDecodingErrorToUnknownNotServer() {
        let invalidJSON = Data("not json".utf8)
        do {
            _ = try JSONDecoder().decode([String: String].self, from: invalidJSON)
            XCTFail("expected decode to throw")
        } catch {
            let mapped = LuminaError.from(error)
            if case .unknown(let message) = mapped {
                XCTAssertTrue(
                    message.contains("couldn't read the server's response"),
                    "unexpected copy: \(message)"
                )
            } else {
                XCTFail("expected .unknown, got \(mapped)")
            }
        }
    }

    // MARK: - isMissingConfiguration

    func testIsMissingConfigurationIsTrueForAnyKey() {
        XCTAssertTrue(LuminaError.missingConfiguration(key: "AnthropicAPIKey").isMissingConfiguration)
        XCTAssertTrue(LuminaError.missingConfiguration(key: "SomeRenamedKey").isMissingConfiguration)
    }

    func testIsMissingConfigurationIsFalseForOtherCases() {
        XCTAssertFalse(LuminaError.offline.isMissingConfiguration)
        XCTAssertFalse(LuminaError.server(status: 500).isMissingConfiguration)
        XCTAssertFalse(LuminaError.timeout.isMissingConfiguration)
        XCTAssertFalse(LuminaError.unknown(underlyingMessage: "x").isMissingConfiguration)
    }

    // MARK: - New service error mappings

    func testMapsIAPNotConfiguredToMissingConfiguration() {
        let mapped = LuminaError.from(IAPManager.ManagerError.notConfigured)
        XCTAssertEqual(mapped, .missingConfiguration(key: "RevenueCatAPIKey"))
    }

    func testMapsSupabaseMissingConfiguration() {
        let mapped = LuminaError.from(SupabaseAuthService.ServiceError.missingConfiguration)
        XCTAssertEqual(mapped, .missingConfiguration(key: "SupabaseURL"))
    }

    func testMapsAppLockNotEnrolledToFaceIDPermission() {
        let mapped = LuminaError.from(AppLock.LockError.notEnrolled)
        XCTAssertEqual(mapped, .permissionDenied(kind: .faceID))
    }

    func testMapsKeychainFailureToUnknownWithoutStatusCode() {
        let mapped = LuminaError.from(KeychainStore.StoreError.unhandledStatus(-25300))
        if case .unknown(let message) = mapped {
            XCTAssertFalse(message.contains("25300"), "OSStatus must never reach user copy")
        } else {
            XCTFail("expected .unknown, got \(mapped)")
        }
    }

    func testMapsAuthErrorsToHumanCopy() {
        let mapped = LuminaError.from(AuthManager.AuthError.invalidCredential)
        if case .unknown(let message) = mapped {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("expected .unknown, got \(mapped)")
        }
    }
}
