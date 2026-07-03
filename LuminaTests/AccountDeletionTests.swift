@testable import Lumina
import XCTest

/// Coverage for the account-deletion server seam (Apple Guideline 5.1.1(v)).
///
/// `AuthManager.deleteAccount()` relies on `SupabaseAuthService.deleteAccount()`
/// being best-effort: until a backend edge function + a provisioned project
/// exist, a real server-side user delete is impossible from a client (it needs
/// the service-role key), so the service throws `.missingConfiguration`, which
/// `AuthManager` swallows before wiping all on-device data. These tests pin
/// that contract so a future change can't silently make the server delete a
/// hard failure that would block the local wipe.
final class AccountDeletionTests: XCTestCase {
    func testDeleteAccountThrowsMissingConfigurationWhenUnprovisioned() async {
        let service = SupabaseAuthService(infoPlist: [:])
        do {
            try await service.deleteAccount()
            XCTFail("expected missingConfiguration when Supabase is unprovisioned")
        } catch let error as SupabaseAuthService.ServiceError {
            XCTAssertEqual(error, .missingConfiguration)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testSignInExchangeAlsoBestEffortWithoutToken() async {
        // The same best-effort shape the delete path depends on: no real
        // identity token is treated as a missing-configuration precondition,
        // not a hard error.
        let service = SupabaseAuthService(infoPlist: [:])
        do {
            try await service.signInWithApple(idToken: nil, nonce: nil)
            XCTFail("expected missingConfiguration with no identity token")
        } catch let error as SupabaseAuthService.ServiceError {
            XCTAssertEqual(error, .missingConfiguration)
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
