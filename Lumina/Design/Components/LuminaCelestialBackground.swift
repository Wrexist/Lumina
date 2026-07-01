import SwiftUI

/// The reusable immersive backdrop for celestial focal surfaces — a deep navy
/// gradient overlaid with two parallaxing starfields (gold foreground, faint
/// white background). Used sparingly as *punctuation* (the Today hero band, the
/// Moon sheet), never wall-to-wall — the app stays a light, warm, editorial
/// theme.
///
/// The navy stays indigo, never purple (brand principle #1). Gyroscope depth is
/// opt-in via `showsMotion` so the `ImageRenderer` screenshot harness and
/// previews render a clean static frame.
struct LuminaCelestialBackground: View {
    /// When false, the two starfields sit still (no `MotionManager`) — used by
    /// the screenshot harness and previews.
    var showsMotion: Bool = true

    @State private var motion = MotionManager()

    /// Foreground stars drift ~1.5× the tilt, background ~0.6×, for depth.
    private static let foregroundParallax: CGFloat = 14
    private static let backgroundParallax: CGFloat = 6

    var body: some View {
        ZStack {
            gradient
            LuminaStarfield(
                tint: LuminaColors.parchment.opacity(0.5),
                parallax: offset(multiplier: Self.backgroundParallax)
            )
            .opacity(0.7)
            LuminaStarfield(
                starCount: 70,
                tint: LuminaColors.mutedGold.opacity(0.9),
                parallax: offset(multiplier: Self.foregroundParallax)
            )
        }
        .onAppear { if showsMotion { motion.start() } }
        .onDisappear { motion.stop() }
    }

    private var gradient: some View {
        // Base midnight, lifted toward a subtle indigo at the top by layering a
        // faint `celestialBlue` wash — keeps it navy, not purple, and avoids
        // hand-mixing token colors.
        LuminaColors.midnight
            .overlay(
                LinearGradient(
                    colors: [LuminaColors.celestialBlue.opacity(0.28), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    /// The live tilt, scaled — zeroed when motion is disabled so static renders
    /// are perfectly centered.
    private func offset(multiplier: CGFloat) -> CGSize {
        guard showsMotion else { return .zero }
        return CGSize(
            width: CGFloat(motion.roll) * multiplier,
            height: CGFloat(motion.pitch) * multiplier
        )
    }
}

#Preview("Celestial Background") {
    LuminaCelestialBackground(showsMotion: false)
        .ignoresSafeArea()
}
