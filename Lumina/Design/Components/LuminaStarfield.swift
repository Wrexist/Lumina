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
    @State private var preferences = AppPreferences.shared

    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    var body: some View {
        if reduceMotion {
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
        for index in 0..<starCount {
            let star = star(index: index, size: size)
            let twinkle = twinkleOpacity(seed: index, base: star.opacity, time: time)
            drawStar(star, twinkle: twinkle, in: context)
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
        /// Depth factor 0.4…1.6 — scales how far this star drifts with parallax.
        var depth: CGFloat
    }

    private func star(index: Int, size: CGSize) -> Star {
        let rx = Self.pseudoRandom(index * 3 + 1)
        let ry = Self.pseudoRandom(index * 3 + 2)
        let rz = Self.pseudoRandom(index * 3 + 3)

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

        // Brighter stars sit "nearer" and drift further with the parallax.
        let depth = 0.4 + CGFloat(baseOpacity) * 1.2
        let drift = CGSize(width: parallax.width * depth, height: parallax.height * depth)
        let position = CGPoint(
            x: CGFloat(rx) * size.width + drift.width,
            y: CGFloat(ry) * size.height + drift.height
        )
        // The largest tier plus a deterministic subset of others carry a glow.
        let hasGlow = tier == 2 && Self.pseudoRandom(index * 7 + 5) > 0.5
        return Star(position: position, radius: radius, opacity: baseOpacity, hasGlow: hasGlow, depth: depth)
    }

    /// Slow opacity "breathing" keyed to each star's seed so they twinkle out of
    /// phase. Amplitude is small (±25%) to stay calm, not blinking.
    private func twinkleOpacity(seed: Int, base: Double, time: Double) -> Double {
        let phase = Self.pseudoRandom(seed * 11 + 7) * .pi * 2
        let speed = 0.6 + Self.pseudoRandom(seed * 13 + 3) * 0.8
        let wave = sin(time * speed + phase)
        return base * (0.75 + 0.25 * (wave * 0.5 + 0.5))
    }

    /// Deterministic hash-based PRNG (splitmix-style) → 0…1, matching
    /// `MoonSphere3DView`'s crater placement so star positions never reseed.
    private static func pseudoRandom(_ seed: Int) -> Double {
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
