import Foundation

/// The 36 Human Design channels — each a pair of gates that, when both
/// activated (personality OR design side combined), define a connection
/// between the two centers they bridge. We render only personality-side
/// channels until the design-side endpoint ships (`ROADMAP.md` Phase 8
/// finish-line). Channels are still useful with personality-only data:
/// they show which gate-pairs the user's natal placements alone bridge.
struct HumanDesignChannel: Hashable, Sendable, Identifiable {
    let gateA: Int
    let gateB: Int
    let centerA: HumanDesignCenter
    let centerB: HumanDesignCenter
    let name: String

    var id: String { "\(min(gateA, gateB))-\(max(gateA, gateB))" }
}

enum HumanDesignChannels {
    static let all: [HumanDesignChannel] = [
        .init(gateA: 1, gateB: 8, centerA: .g, centerB: .throat, name: "Inspiration"),
        .init(gateA: 2, gateB: 14, centerA: .g, centerB: .sacral, name: "The Beat"),
        .init(gateA: 3, gateB: 60, centerA: .sacral, centerB: .root, name: "Mutation"),
        .init(gateA: 4, gateB: 63, centerA: .ajna, centerB: .head, name: "Logic"),
        .init(gateA: 5, gateB: 15, centerA: .sacral, centerB: .g, name: "Rhythm"),
        .init(gateA: 6, gateB: 59, centerA: .solarPlexus, centerB: .sacral, name: "Mating"),
        .init(gateA: 7, gateB: 31, centerA: .g, centerB: .throat, name: "The Alpha"),
        .init(gateA: 9, gateB: 52, centerA: .sacral, centerB: .root, name: "Concentration"),
        .init(gateA: 10, gateB: 20, centerA: .g, centerB: .throat, name: "Awakening"),
        .init(gateA: 10, gateB: 34, centerA: .g, centerB: .sacral, name: "Exploration"),
        .init(gateA: 10, gateB: 57, centerA: .g, centerB: .spleen, name: "Perfected Form"),
        .init(gateA: 11, gateB: 56, centerA: .ajna, centerB: .throat, name: "Curiosity"),
        .init(gateA: 12, gateB: 22, centerA: .throat, centerB: .solarPlexus, name: "Openness"),
        .init(gateA: 13, gateB: 33, centerA: .g, centerB: .throat, name: "The Prodigal"),
        .init(gateA: 16, gateB: 48, centerA: .throat, centerB: .spleen, name: "The Wavelength"),
        .init(gateA: 17, gateB: 62, centerA: .ajna, centerB: .throat, name: "Acceptance"),
        .init(gateA: 18, gateB: 58, centerA: .spleen, centerB: .root, name: "Judgement"),
        .init(gateA: 19, gateB: 49, centerA: .root, centerB: .solarPlexus, name: "Synthesis"),
        .init(gateA: 20, gateB: 34, centerA: .throat, centerB: .sacral, name: "Charisma"),
        .init(gateA: 20, gateB: 57, centerA: .throat, centerB: .spleen, name: "The Brain Wave"),
        .init(gateA: 21, gateB: 45, centerA: .heart, centerB: .throat, name: "Money"),
        .init(gateA: 23, gateB: 43, centerA: .throat, centerB: .ajna, name: "Structuring"),
        .init(gateA: 24, gateB: 61, centerA: .ajna, centerB: .head, name: "Awareness"),
        .init(gateA: 25, gateB: 51, centerA: .g, centerB: .heart, name: "Initiation"),
        .init(gateA: 26, gateB: 44, centerA: .heart, centerB: .spleen, name: "Surrender"),
        .init(gateA: 27, gateB: 50, centerA: .sacral, centerB: .spleen, name: "Preservation"),
        .init(gateA: 28, gateB: 38, centerA: .spleen, centerB: .root, name: "Struggle"),
        .init(gateA: 29, gateB: 46, centerA: .sacral, centerB: .g, name: "Discovery"),
        .init(gateA: 30, gateB: 41, centerA: .solarPlexus, centerB: .root, name: "Recognition"),
        .init(gateA: 32, gateB: 54, centerA: .spleen, centerB: .root, name: "Transformation"),
        .init(gateA: 34, gateB: 57, centerA: .sacral, centerB: .spleen, name: "Power"),
        .init(gateA: 35, gateB: 36, centerA: .throat, centerB: .solarPlexus, name: "Transitoriness"),
        .init(gateA: 37, gateB: 40, centerA: .solarPlexus, centerB: .heart, name: "Community"),
        .init(gateA: 39, gateB: 55, centerA: .root, centerB: .solarPlexus, name: "Emoting"),
        .init(gateA: 42, gateB: 53, centerA: .sacral, centerB: .root, name: "Maturation"),
        .init(gateA: 47, gateB: 64, centerA: .ajna, centerB: .head, name: "Abstraction"),
    ]

    /// Returns the subset of channels both of whose gates are activated.
    static func defined(in activation: HumanDesignActivation) -> [HumanDesignChannel] {
        all.filter { activation.activatedGates.contains($0.gateA) && activation.activatedGates.contains($0.gateB) }
    }
}
