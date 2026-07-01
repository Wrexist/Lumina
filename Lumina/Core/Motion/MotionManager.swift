import CoreMotion
import SwiftUI

/// Publishes a small, clamped device-tilt signal (`roll` / `pitch`, radians)
/// for the celestial starfield parallax. Kept deliberately tiny — the only job
/// is to turn raw `CMDeviceMotion` into two damped `Double`s that view layers
/// feed into `.offset()`.
///
/// Battery note (see LEARNINGS.md "Gyroscope parallax"): callers MUST call
/// `stop()` in `.onDisappear`, otherwise `CoreMotion` keeps the motion
/// coprocessor awake and drains the battery.
@MainActor
@Observable
final class MotionManager {
    /// Left/right tilt, radians, clamped to ±`maxTilt`.
    private(set) var roll: Double = 0
    /// Forward/back tilt, radians, clamped to ±`maxTilt`.
    private(set) var pitch: Double = 0

    /// CoreMotion is a non-`Sendable` reference type; it lives entirely on the
    /// main actor here (created, started, stopped, and its handler bridged back
    /// to `@MainActor`), so it never crosses an actor boundary.
    private let motionManager = CMMotionManager()

    /// A small clamp keeps the parallax subtle and premium — big tilts should
    /// nudge the stars, never swing them.
    private static let maxTilt: Double = 0.4
    private static let updateInterval: TimeInterval = 1.0 / 60.0

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !motionManager.isDeviceMotionActive else { return }
        motionManager.deviceMotionUpdateInterval = Self.updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            // Capture only plain `Double`s before hopping — `CMDeviceMotion` is
            // not `Sendable`, so nothing but these scalars crosses into the
            // isolated closure below.
            let rawRoll = motion.attitude.roll
            let rawPitch = motion.attitude.pitch
            // `startDeviceMotionUpdates(to: .main)` delivers on the main queue,
            // but Swift 6 can't prove that statically; assert the isolation we
            // already know holds so we can touch `@MainActor` state safely.
            MainActor.assumeIsolated {
                self?.roll = Self.clamp(rawRoll)
                self?.pitch = Self.clamp(rawPitch)
            }
        }
    }

    func stop() {
        guard motionManager.isDeviceMotionActive else { return }
        motionManager.stopDeviceMotionUpdates()
        roll = 0
        pitch = 0
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, -maxTilt), maxTilt)
    }
}
