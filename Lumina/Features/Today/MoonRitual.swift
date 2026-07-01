import Foundation

/// The lunar ritual prompt for a given phase — new-moon *intentions* and
/// full-moon *release*, the two moments astrology audiences genuinely mark. A
/// recurring, premium reason to return (~twice a month), not a streak. Pure and
/// unit-testable; keyed to the real phase angle (0 = new, 180 = full).
enum MoonRitual {
    /// A ritual nudge when the moon is near new or full, else nil.
    static func prompt(forAngle angle: Double) -> String? {
        let normalized = (angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        switch normalized {
        case ..<45:
            return "New moon energy — a natural moment to set an intention."
        case 160..<200:
            return "Full moon energy — a time to release what's run its course."
        default:
            return nil
        }
    }

    /// The matching call-to-action verb for the Reflect hand-off.
    static func callToAction(forAngle angle: Double) -> String? {
        let normalized = (angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        switch normalized {
        case ..<45: return "Set an intention"
        case 160..<200: return "Reflect and release"
        default: return nil
        }
    }
}
