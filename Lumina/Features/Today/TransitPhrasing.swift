import Foundation

/// Turns a `TransitReading` into a short, human, *honest* one-liner for the
/// Today tab. No invented imagery — just the real contact and whether it's
/// tightening or loosening, in the brand's plain editorial voice.
///
/// Examples:
///   "Mars trine your Venus, building"
///   "Saturn square your Sun, easing"
///   "Sun conjunct your Sun, building"  (a solar return — your birthday)
enum TransitPhrasing {
    /// A one-line description: "<transiting> <aspect> your <natal>, <phase>".
    static func sentence(for transit: TransitReading) -> String {
        let phase = transit.applying ? "building" : "easing"
        return "\(transit.transiting) \(aspectWord(transit.type)) your \(transit.natal), \(phase)"
    }

    /// The conventional astrological preposition/verb for each aspect.
    static func aspectWord(_ type: AspectType) -> String {
        switch type {
        case .conjunction: "conjunct"
        case .sextile: "sextile"
        case .square: "square"
        case .trine: "trine"
        case .opposition: "opposite"
        }
    }
}
