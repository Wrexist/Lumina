import Foundation

/// Reduces a `NatalChart` to the personality-side gate activations and
/// the centers those gates define.
///
/// **What's real**: the gate activated by each natal planet, computed
/// from `HumanDesignMandala`. Centers are marked defined only when a
/// complete channel (both gates of a pair activated) connects them —
/// hanging gates alone leave a center open, per the HD rule.
///
/// **What's NOT real yet**: the design-side activations (Sun, Earth, etc.
/// at the moment 88° of solar arc before birth). Real HD requires both
/// sides; channels (defined when both gates of a pair are activated)
/// also require both. Those land when the backend exposes a `/design`
/// endpoint (`ROADMAP.md` Phase 8 finish-line). The renderer is honest
/// about what's missing — see `BodygraphView.designSideMissingNote`.
struct HumanDesignActivation: Sendable, Equatable {
    struct GateActivation: Hashable, Sendable {
        let planet: String
        let gate: Int
        let line: Int
    }

    /// Personality-side activations: one per natal planet, plus the Earth.
    let personality: [GateActivation]
    /// Set of all activated gate numbers, derived from `personality`.
    let activatedGates: Set<Int>
    /// Set of centers connected by at least one complete channel.
    let definedCenters: Set<HumanDesignCenter>

    static func compute(from chart: NatalChart) -> HumanDesignActivation {
        let personality = chart.planets.flatMap(Self.activations(for:))
        let activatedGates = Set(personality.map(\.gate))
        // A center is defined only when a complete channel reaches it;
        // a hanging gate (its partner gate unactivated) does not define.
        let defined = Set(HumanDesignChannels.defined(gates: activatedGates)
            .flatMap { [$0.centerA, $0.centerB] })
        return HumanDesignActivation(
            personality: personality,
            activatedGates: activatedGates,
            definedCenters: defined
        )
    }

    /// The activations a single natal body contributes: its own gate, and —
    /// for the Sun alone — the Earth's.
    ///
    /// The Earth is one of the thirteen personality activations in every Human
    /// Design chart, and it is always exactly opposite the Sun, so it costs no
    /// ephemeris call — only arithmetic that nobody had done. Leaving it out
    /// mattered: the backend returns ten bodies, and with ten gates a large
    /// share of real charts complete no channel at all and render a bodygraph
    /// with every centre open. Adding the Earth is one more chance at a
    /// channel for a paid feature that was silently blank for many people.
    private static func activations(for planet: NatalChart.PlanetPosition) -> [GateActivation] {
        let own = activation(planet: planet.planet, longitude: planet.longitude)
        guard planet.planet == "Sun" else { return [own] }
        return [own, activation(planet: "Earth", longitude: planet.longitude + 180)]
    }

    /// `HumanDesignMandala` normalises the angle itself, so Sun + 180° needs
    /// no wrapping here.
    private static func activation(planet: String, longitude: Double) -> GateActivation {
        GateActivation(
            planet: planet,
            gate: HumanDesignMandala.gate(forLongitude: longitude),
            line: HumanDesignMandala.line(forLongitude: longitude)
        )
    }
}
