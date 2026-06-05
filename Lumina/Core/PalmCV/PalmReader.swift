import Foundation

/// Classical palmistry from real hand geometry. Pure and unit-testable: given
/// the proportions Vision measures on-device, it picks one of the four hand
/// types and the reading flows from `HandType`. The capture + landmark
/// extraction feeds this; the photo never leaves the device (CLAUDE.md rules).
enum PalmReader {
    // A palm reads as "square" when its width is close to its length, and
    // fingers as "long" when they approach the palm's length. Thresholds are
    // central so a borderline hand falls to the nearer type.
    private static let squareThreshold = 0.85
    private static let longFingerThreshold = 0.95

    static func handType(from features: PalmFeatures) -> HandType {
        guard features.palmLength > 0 else { return .earth }
        let squarePalm = features.palmWidth / features.palmLength >= squareThreshold
        let longFingers = features.averageFingerLength / features.palmLength >= longFingerThreshold
        switch (squarePalm, longFingers) {
        case (true, false): return .earth
        case (true, true): return .air
        case (false, false): return .fire
        case (false, true): return .water
        }
    }

    /// Convenience: the hand type plus its reading, ready for the detail surface.
    static func reading(from features: PalmFeatures) -> String {
        handType(from: features).reading
    }
}
