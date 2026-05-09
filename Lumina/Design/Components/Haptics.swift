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

    /// Fires the haptic. Falls through silently when the user has Reduce
    /// Motion / Reduce Haptics on, when the feedback engine isn't available,
    /// or on platforms without a Taptic engine.
    @MainActor
    func play() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
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
