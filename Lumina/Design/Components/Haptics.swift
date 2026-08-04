import SwiftUI
import UIKit

/// Centralised haptics. Use these tokens, not raw `UIImpactFeedbackGenerator`,
/// so we can audit feedback intensity in one place and turn it down globally
/// when "Reduce Motion" or "Reduce Haptics" is enabled.
///
/// See `docs/NAVIGATION.md` §13 — the brand stays quiet; spring bounces and
/// celebratory haptics are anti-patterns in this category.
enum Haptics {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case failure

    /// Fires the haptic. Falls through silently when the OS reports that
    /// haptics should be suppressed, or on hardware without a Taptic engine.
    ///
    /// This used to gate on `isReduceMotionEnabled`. Reduce Motion is a
    /// vestibular setting about animation, not touch — using it here meant a
    /// motion-sensitive user lost every tactile confirmation in the app,
    /// including the reveal-ritual success haptic Today is built around.
    /// `UIDevice` reports the actual haptic capability, and iOS itself honours
    /// the system Reduce-Haptics preference when playing feedback.
    @MainActor
    func play() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .failure:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
