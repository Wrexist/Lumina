import Foundation

/// The four classical palmistry hand shapes, each tied to an element. Derived
/// purely from hand *geometry* (palm proportions + finger length), never from a
/// generic illustration — the honest core of `PalmReader`.
enum HandType: String, CaseIterable, Sendable {
    case earth
    case air
    case fire
    case water

    var element: String {
        switch self {
        case .earth: "Earth"
        case .air: "Air"
        case .fire: "Fire"
        case .water: "Water"
        }
    }

    /// "Earth hand", etc.
    var title: String { "\(element) hand" }

    /// A grounded reading of the hand shape — classical palmistry traits tied to
    /// the measured proportions, no invented mysticism.
    var reading: String {
        switch self {
        case .earth:
            "A square palm with shorter fingers — the Earth hand. It reads as practical, "
                + "grounded, and hands-on: you trust what you can build, test, and touch."
        case .air:
            "A square palm with long fingers — the Air hand. It reads as curious and "
                + "analytical: you live in ideas, words, and the why behind things."
        case .fire:
            "A long palm with shorter fingers — the Fire hand. It reads as energetic and "
                + "instinctive: you move on momentum and lead with action over deliberation."
        case .water:
            "A long palm with long fingers — the Water hand. It reads as sensitive and "
                + "intuitive: you feel first, with creativity and empathy close to the surface."
        }
    }
}
