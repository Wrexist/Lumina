import Foundation

/// Effective "reduce motion" for Lumina. Components should respect *either* the
/// OS Accessibility → Reduce Motion setting *or* the in-app override (Settings →
/// Reduce motion), so that the in-app toggle actually does something. Read the
/// OS flag via `@Environment(\.accessibilityReduceMotion)` and combine it here.
enum LuminaMotion {
    /// True when motion should be minimized — system Reduce Motion or the
    /// in-app override.
    static func isReduced(system: Bool, appOverride: Bool) -> Bool {
        system || appOverride
    }
}
