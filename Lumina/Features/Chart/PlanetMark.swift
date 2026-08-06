import SwiftUI

/// One chart body, drawn the same way everywhere it appears in a reading:
/// its generated sphere where we have art, its Unicode glyph where we don't.
///
/// The Moon always takes the glyph branch on purpose. Its phase is computed
/// from the real ephemeris and rendered live in `MoonSphere3DView`, so a
/// static Moon image would contradict the sky on most nights — the one thing
/// this app doesn't do.
///
/// Always decorative: every surface using it already names the planet in
/// adjacent text, so VoiceOver would otherwise read the same word twice.
struct PlanetMark: View {
    /// Backend planet name — "Sun", "Mercury", … (`ChartGlyphs.planetOrder`).
    let planet: String
    /// Edge length of the square the mark is drawn in. Pass a `@ScaledMetric`
    /// value from the call site so it grows with Dynamic Type.
    let size: CGFloat

    var body: some View {
        Group {
            if let sphere = LuminaImageAsset.planet(planet) {
                sphere.image
                    .resizable()
                    .scaledToFit()
            } else {
                Text(ChartGlyphs.planetGlyph(planet))
                    // Slightly under the frame: a glyph's drawn height sits
                    // below its point size, and this keeps the two branches
                    // reading at the same weight in a row.
                    .font(.system(size: size * 0.8))
                    .foregroundStyle(LuminaColors.goldInk)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview("Sphere and glyph") {
    HStack(spacing: LuminaSpacing.md) {
        PlanetMark(planet: "Jupiter", size: 64)
        PlanetMark(planet: "Saturn", size: 64)
        PlanetMark(planet: "Moon", size: 64)
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
