import Foundation

/// Output of `EphemerisService.moonPhase(at:)` — tonight's Moon. Global sky
/// data (not personalized). Mirrors `MoonPhaseResultSchema` in
/// `backend/src/types.ts`.
struct MoonPhaseResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    /// The moment the phase was computed for.
    let at: Date
    /// Phase angle 0–360° (0 = new, 90 = first quarter, 180 = full).
    let angle: Double
    /// Human-readable phase name ("Waxing Gibbous", …).
    let phase: String
    /// Illuminated fraction of the lunar disk, 0–1.
    let illumination: Double
    /// The next new moon at or after `at`.
    let nextNewMoon: Date
    /// The next full moon at or after `at`.
    let nextFullMoon: Date
}
