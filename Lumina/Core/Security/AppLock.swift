import Foundation
import LocalAuthentication
import OSLog

/// Face ID / passcode gate for sensitive surfaces (currently the Reflect
/// tab — see `docs/NAVIGATION.md` §14). Off by default; the user opts in
/// from Settings → Preferences → "Lock Reflect with Face ID".
@MainActor
@Observable
final class AppLock {
    enum LockReason: Equatable, Sendable {
        case reflectTab
    }

    enum LockError: Error, Equatable, Sendable {
        case notEnrolled
        case userCancelled
        case unavailable
        case failed(reason: String)
    }

    static let shared = AppLock()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "AppLock")

    /// `true` while the user has unlocked at least once this session for the
    /// reason. Reset to `false` on app background (in v1) so the user has
    /// to re-auth each time they return to the gated surface.
    private(set) var unlocked: Set<LockReason> = []

    /// Whether the device can perform biometrics or device passcode.
    var canEvaluate: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        )
    }

    /// Whether Face ID specifically is available — used by Settings copy.
    var faceIDAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        return context.biometryType == .faceID
    }

    init() {}

    /// Prompts Face ID / passcode. Updates `unlocked` on success. Throws a
    /// `LockError` so callers can surface the right `LuminaError` via
    /// `LuminaError.from(_:)` (Phase 13 wires that mapping).
    func unlock(_ reason: LockReason, prompt: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw LockError.unavailable
        }
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: prompt)
            if success {
                unlocked.insert(reason)
            } else {
                throw LockError.failed(reason: "Authentication did not succeed.")
            }
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .systemCancel, .appCancel:
                throw LockError.userCancelled
            case .biometryNotEnrolled, .passcodeNotSet:
                throw LockError.notEnrolled
            default:
                throw LockError.failed(reason: laError.localizedDescription)
            }
        }
    }

    /// Called from `LuminaApp` on `scenePhase == .background` to wipe the
    /// session-cached unlocks so the gate re-applies on return.
    func resetSessionUnlocks() {
        logger.debug("clearing app lock session unlocks")
        unlocked.removeAll()
    }
}
