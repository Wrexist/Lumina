import SwiftUI

/// A pure-SwiftUI `Canvas` starfield — a soft field of twinkling points used
/// behind celestial focal surfaces (the hero band, the Moon sheet). Rendered
/// with `Canvas` rather than SceneKit/UIKit on purpose so it composes into the
/// `ImageRenderer` screenshot harness and honors Reduce Motion.
///
/// Star positions are DETERMINISTIC via a seeded splitmix-style hash (the same
/// approach as `MoonSphere3DView.pseudoRandom(_:)`), so the field is stable
/// across renders and launches — never `Double.random`, which would flicker on
/// every rebuild.
struct LuminaStarfield: View {
    var starCount: Int = 60
    var tint: Color = .white
    /// Parallax offset (points) fed from the gyroscope; nearer/brighter stars
    /// move more than dim ones for a sense of depth.
    var parallax: CGSize = .zero

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var preferences = AppPreferences.shared

    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    /// `TimelineView(.animation)` keeps ticking while the app is inactive or
    /// backgrounded, and two of these stack behind the launch tab. Freeze the
    /// field whenever it can't be seen — same code path Reduce Motion uses.
    private var isAnimating: Bool {
        !reduceMotion && scenePhase == .active
    }

    var body: some View {
        if !isAnimating {
            // A single static frame — no `TimelineView`, so nothing animates.
            Canvas { context, size in
                draw(in: context, size: size, time: 0)
            }
            .accessibilityHidden(true)
        } else {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let seconds = timeline.date.timeIntervalSinceReferenceDate
                    draw(in: context, size: size, time: seconds)
                }
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: - Drawing

    private func draw(in context: GraphicsContext, size: CGSize, time: Double) {
        for seed in Self.seeds.prefix(min(starCount, Self.maxStarCount)) {
            drawStar(star(seed, size: size), twinkle: twinkleOpacity(seed, time: time), in: context)
        }
    }

    private func drawStar(_ star: Star, twinkle: Double, in context: GraphicsContext) {
        // A subset of the brightest stars get a faint larger glow halo.
        if star.hasGlow {
            let glowRect = CGRect(
                x: star.position.x - star.radius * 3,
                y: star.position.y - star.radius * 3,
                width: star.radius * 6,
                height: star.radius * 6
            )
            context.fill(Circle().path(in: glowRect), with: .color(tint.opacity(twinkle * 0.18)))
        }
        let rect = CGRect(
            x: star.position.x - star.radius,
            y: star.position.y - star.radius,
            width: star.radius * 2,
            height: star.radius * 2
        )
        context.fill(Circle().path(in: rect), with: .color(tint.opacity(twinkle)))
    }

    // MARK: - Star model

    private struct Star {
        var position: CGPoint
        var radius: CGFloat
        var opacity: Double
        var hasGlow: Bool
    }

    /// Everything about a star that never changes: its normalised position, its
    /// size tier, and its twinkle phase.
    ///
    /// These used to be re-derived inside the draw loop — six hash
    /// evaluations per star, per frame, for values that are the same every
    /// frame. With two stacked fields behind the launch tab at 120 Hz that was
    /// ~150,000 hashes a second computing constants. They're hoisted into a
    /// single `static let` now; the draw loop does arithmetic only.
    private struct StarSeed: Sendable {
        let unitX: CGFloat
        let unitY: CGFloat
        let radius: CGFloat
        let baseOpacity: Double
        let hasGlow: Bool
        /// Depth factor 0.4…1.6 — scales how far this star drifts with parallax.
        let depth: CGFloat
        let twinklePhase: Double
        let twinkleSpeed: Double
    }

    /// Precomputed once for the largest field any caller asks for; smaller
    /// fields take a prefix, so star *n* is identical everywhere it appears.
    ///
    /// `nonisolated` because the view type infers `@MainActor` (it holds
    /// `@State` on a main-actor-isolated store), and a main-actor function
    /// can't be passed to `map` in a non-isolated static initialiser. These
    /// are pure arithmetic over `Sendable` values, so isolation buys nothing.
    private nonisolated static let maxStarCount = 256
    private nonisolated static let seeds: [StarSeed] = (0..<maxStarCount).map(makeSeed)

    private nonisolated static func makeSeed(index: Int) -> StarSeed {
        let rx = pseudoRandom(index * 3 + 1)
        let ry = pseudoRandom(index * 3 + 2)
        let rz = pseudoRandom(index * 3 + 3)

        // Three size tiers so the field reads as layered, not uniform.
        let tier = Int(rz * 3) % 3
        let radius: CGFloat
        let baseOpacity: Double
        switch tier {
        case 0:
            radius = 0.7
            baseOpacity = 0.35
        case 1:
            radius = 1.2
            baseOpacity = 0.55
        default:
            radius = 1.8
            baseOpacity = 0.85
        }

        return StarSeed(
            unitX: CGFloat(rx),
            unitY: CGFloat(ry),
            radius: radius,
            baseOpacity: baseOpacity,
            // The largest tier plus a deterministic subset carry a glow.
            hasGlow: tier == 2 && pseudoRandom(index * 7 + 5) > 0.5,
            // Brighter stars sit "nearer" and drift further with the parallax.
            depth: 0.4 + CGFloat(baseOpacity) * 1.2,
            twinklePhase: pseudoRandom(index * 11 + 7) * .pi * 2,
            twinkleSpeed: 0.6 + pseudoRandom(index * 13 + 3) * 0.8
        )
    }

    private func star(_ seed: StarSeed, size: CGSize) -> Star {
        Star(
            position: CGPoint(
                x: seed.unitX * size.width + parallax.width * seed.depth,
                y: seed.unitY * size.height + parallax.height * seed.depth
            ),
            radius: seed.radius,
            opacity: seed.baseOpacity,
            hasGlow: seed.hasGlow
        )
    }

    /// Slow opacity "breathing", out of phase per star. Amplitude is small
    /// (±25%) to stay calm, not blinking.
    private func twinkleOpacity(_ seed: StarSeed, time: Double) -> Double {
        let wave = sin(time * seed.twinkleSpeed + seed.twinklePhase)
        return seed.baseOpacity * (0.75 + 0.25 * (wave * 0.5 + 0.5))
    }

    /// Deterministic hash-based PRNG (splitmix-style) → 0…1, matching
    /// `MoonSphere3DView`'s crater placement so star positions never reseed.
    private nonisolated static func pseudoRandom(_ seed: Int) -> Double {
        var value = UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15
        value ^= value >> 30
        value = value &* 0xBF58_476D_1CE4_E5B9
        value ^= value >> 27
        return Double(value % 1_000) / 1_000
    }
}

#Preview("Starfield") {
    ZStack {
        LuminaColors.midnight
        LuminaStarfield(tint: LuminaColors.mutedGold)
    }
    .ignoresSafeArea()
}
