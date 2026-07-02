@testable import Lumina
import XCTest

/// Unit tests for the Sign in with Apple nonce helpers (`AuthNonce`): the
/// raw nonce must be fresh per attempt, drawn from the documented URL-safe
/// charset, and hashed to the lowercase-hex SHA256 encoding Apple expects
/// on `ASAuthorizationAppleIDRequest.nonce`.
final class AuthNonceTests: XCTestCase {
    // MARK: - Randomness

    func testTwoNoncesDiffer() {
        // With 32 characters of 6 random bits each, a collision here would
        // indicate a broken generator, not bad luck.
        XCTAssertNotEqual(AuthNonce.random(), AuthNonce.random())
    }

    // MARK: - Length and charset

    func testDefaultNonceLengthIs32() {
        XCTAssertEqual(AuthNonce.random().count, 32)
    }

    func testCustomNonceLengthIsHonored() {
        XCTAssertEqual(AuthNonce.random(length: 16).count, 16)
    }

    func testNonceUsesOnlyTheDeclaredCharset() {
        let allowed = Set(AuthNonce.charset)
        let nonce = AuthNonce.random()
        XCTAssertTrue(nonce.allSatisfy { allowed.contains($0) })
    }

    func testCharsetHasExactly64UniqueCharacters() {
        // The generator masks a random byte with `0x3F`, which is only
        // uniform (bias-free) if the charset is exactly 64 entries.
        XCTAssertEqual(AuthNonce.charset.count, 64)
        XCTAssertEqual(Set(AuthNonce.charset).count, 64)
    }

    // MARK: - SHA256 hex encoding

    func testSHA256HexOfKnownInput() {
        // Standard NIST test vector for SHA-256("abc").
        XCTAssertEqual(
            AuthNonce.sha256Hex("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    func testSHA256HexOfEmptyString() {
        XCTAssertEqual(
            AuthNonce.sha256Hex(""),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )
    }
}
