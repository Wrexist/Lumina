import SwiftUI

/// Phase-4 starter chart-wheel renderer. Single-pass `Canvas` for the
/// rings + radial dividers + sign glyphs (cheap, 60fps); SwiftUI overlay
/// `Button`s for the planet glyphs so each one is independently tappable
/// with a 44pt touch target.
///
/// When `chart.houses` is present the wheel rotates so the Ascendant sits
/// at the left (9 o'clock) per Western convention. Without houses, 0° Aries
/// is anchored at the left.
struct ChartWheelView: View {
    /// The wheel's colours, named by role.
    ///
    /// The wheel is the app's signature object and the one place the brand's
    /// midnight belongs at full strength — a chart drawn in ink on parchment
    /// reads as a diagram, the same disc on midnight reads as the sky. Naming
    /// the roles keeps that a single decision: every stroke below asks the
    /// palette what colour it is, so the ground can change without hunting
    /// through twenty `inkBlack.opacity(…)` literals.
    struct Palette: Sendable {
        let disc: Color
        let ringStrong: Color
        let ringSoft: Color
        let divider: Color
        let signGlyph: Color
        let houseCusp: Color
        let houseCuspAngular: Color
        let houseNumeral: Color
        let planetGlyph: Color
        let retrogradeMark: Color

        /// The default: a deep midnight disc with gold glyphs.
        static let midnight = Palette(
            disc: LuminaColors.midnight,
            ringStrong: LuminaColors.parchment.opacity(0.45),
            ringSoft: LuminaColors.parchment.opacity(0.22),
            divider: LuminaColors.parchment.opacity(0.16),
            signGlyph: LuminaColors.mutedGold,
            houseCusp: LuminaColors.parchment.opacity(0.14),
            houseCuspAngular: LuminaColors.parchment.opacity(0.5),
            houseNumeral: LuminaColors.parchment.opacity(0.45),
            planetGlyph: LuminaColors.parchment,
            retrogradeMark: LuminaColors.mutedGold.opacity(0.85)
        )
    }

    let chart: NatalChart
    var onTapPlanet: ((NatalChart.PlanetPosition) -> Void)?
    var palette: Palette = .midnight

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size / 2

            ZStack {
                Circle()
                    .fill(palette.disc)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                Canvas { context, _ in
                    drawZodiacRing(in: context, center: center, radius: radius)
                    drawHouses(in: context, center: center, radius: radius)
                    drawAspects(in: context, center: center, radius: radius)
                    drawRetrogradeMarkers(in: context, center: center, radius: radius)
                }
                planetButtons(center: center, radius: radius)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Birth chart wheel")
    }

    // MARK: - Layout helpers

    private var rotationDegrees: Double {
        // Place Ascendant at the left (9 o'clock) when we have it.
        chart.houses?.ascendant ?? 0
    }

    /// Astrology convention: 0° at left, signs increase CCW visually
    /// (which goes down first because of the screen y-axis direction).
    private func point(longitude: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let rotated = longitude - rotationDegrees
        let angleRad = (180.0 - rotated) * .pi / 180
        let x = center.x + radius * CGFloat(cos(angleRad))
        let y = center.y + radius * CGFloat(sin(angleRad))
        return CGPoint(x: x, y: y)
    }

    // MARK: - Canvas drawing

    private func drawZodiacRing(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let outer = radius * 0.98
        let inner = radius * 0.82

        // Outer + inner rings
        context.stroke(
            Path { path in path.addArc(center: center, radius: outer, startAngle: .zero, endAngle: .degrees(360), clockwise: false) },
            with: .color(palette.ringStrong),
            lineWidth: 1
        )
        context.stroke(
            Path { path in path.addArc(center: center, radius: inner, startAngle: .zero, endAngle: .degrees(360), clockwise: false) },
            with: .color(palette.ringSoft),
            lineWidth: 1
        )

        // 12 dividers at every 30°
        for i in 0..<12 {
            let cuspLongitude = Double(i) * 30
            let p1 = point(longitude: cuspLongitude, radius: inner, center: center)
            let p2 = point(longitude: cuspLongitude, radius: outer, center: center)
            context.stroke(
                Path { path in path.move(to: p1); path.addLine(to: p2) },
                with: .color(palette.divider),
                lineWidth: 1
            )
        }

        // Sign glyphs at the mid-sign position (15°, 45°, 75°, ...)
        for i in 0..<12 {
            let mid = Double(i) * 30 + 15
            let position = point(longitude: mid, radius: (outer + inner) / 2, center: center)
            let glyph = ChartGlyphs.signGlyph(ChartGlyphs.signOrder[i])
            let text = Text(glyph)
                .font(.system(size: radius * 0.10))
                .foregroundColor(palette.signGlyph)
            context.draw(text, at: position)
        }
    }

    private func drawHouses(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        // Exactly 12 cusps are required; bail rather than index out of bounds
        // (`cusps[(index + 1) % 12]`) on a malformed payload.
        guard let houses = chart.houses, houses.cusps.count == 12 else { return }
        let outer = radius * 0.82
        let inner = radius * 0.50

        // Inner house ring
        context.stroke(
            Path { path in path.addArc(center: center, radius: inner, startAngle: .zero, endAngle: .degrees(360), clockwise: false) },
            with: .color(palette.ringSoft),
            lineWidth: 1
        )

        // Cusp dividers — Asc/Desc/MC/IC slightly heavier
        for (index, cusp) in houses.cusps.enumerated() {
            let isAngular = index == 0 || index == 3 || index == 6 || index == 9
            let p1 = point(longitude: cusp, radius: inner, center: center)
            let p2 = point(longitude: cusp, radius: outer, center: center)
            context.stroke(
                Path { path in path.move(to: p1); path.addLine(to: p2) },
                with: .color(isAngular ? palette.houseCuspAngular : palette.houseCusp),
                lineWidth: isAngular ? 1.5 : 0.8
            )

            // House numerals just inside the cusp's mid-sector
            let nextCusp = houses.cusps[(index + 1) % 12]
            let mid = midLongitude(from: cusp, to: nextCusp)
            let labelPos = point(longitude: mid, radius: inner * 0.92, center: center)
            let numeralText = Text("\(index + 1)")
                .font(.system(size: radius * 0.06, weight: .light, design: .monospaced))
                .foregroundColor(palette.houseNumeral)
            context.draw(numeralText, at: labelPos)
        }
    }

    private func drawAspects(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let aspectRadius = radius * 0.50
        // Tolerate duplicate planet names in a malformed payload (first wins)
        // rather than trapping in `Dictionary(uniqueKeysWithValues:)`.
        let positions = Dictionary(
            chart.planets.map { ($0.planet, $0.longitude) },
            uniquingKeysWith: { first, _ in first }
        )
        for aspect in chart.aspects {
            guard let lon1 = positions[aspect.planet1],
                  let lon2 = positions[aspect.planet2] else { continue }
            let p1 = point(longitude: lon1, radius: aspectRadius, center: center)
            let p2 = point(longitude: lon2, radius: aspectRadius, center: center)
            context.stroke(
                Path { path in path.move(to: p1); path.addLine(to: p2) },
                with: .color(aspectColor(aspect.type)),
                lineWidth: aspectLineWidth(aspect.type)
            )
        }
    }

    /// Aspect strokes, tuned for the midnight disc.
    ///
    /// These were picked for parchment and do not survive the move: measured
    /// measured against `midnight`, `celestialBlue` lands at 2.6:1 and the
    /// oxblood `error` at 2.4:1 — both effectively invisible, the same class
    /// of bug as the old `blush` squares that never rendered at all.
    /// `aspectHarmonious` (8.7:1) and `aspectTense` (6.1:1) are picked for
    /// this surface, and carry no opacity because the disc gives them room.
    private func aspectColor(_ type: AspectType) -> Color {
        switch type {
        // Strokes, not text — `mutedGold` needs no darkened variant.
        case .conjunction: LuminaColors.mutedGold.opacity(0.9)
        case .sextile, .trine: LuminaColors.aspectHarmonious
        case .square, .opposition: LuminaColors.aspectTense
        }
    }

    private func aspectLineWidth(_ type: AspectType) -> CGFloat {
        switch type {
        case .conjunction, .opposition: 1.4
        case .square, .trine: 1.0
        case .sextile: 0.6
        }
    }

    /// Small "℞" marker drawn just outside the planet glyph for any
    /// retrograde planet. Reads as the traditional astrological marker
    /// without crowding the glyph.
    private func drawRetrogradeMarkers(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let markerRadius = radius * 0.78
        for planet in chart.planets where planet.isRetrograde {
            let position = point(longitude: planet.longitude, radius: markerRadius, center: center)
            let marker = Text("℞")
                .font(.system(size: radius * 0.07, weight: .light))
                .foregroundColor(palette.retrogradeMark)
            context.draw(marker, at: position)
        }
    }

    // MARK: - Planet glyph overlay

    private func planetButtons(center: CGPoint, radius: CGFloat) -> some View {
        let placementRadius = radius * 0.66
        // De-cluster conjunct glyphs: planets within a few degrees of each
        // other are stacked at staggered radii so each stays legible and
        // independently tappable instead of landing on the same point.
        let radii = ChartWheelLayout.staggeredRadii(
            longitudes: chart.planets.map(\.longitude),
            placement: placementRadius,
            step: radius * 0.12,
            band: (radius * 0.56)...(radius * 0.76)
        )
        // First wins on duplicate planet names — same guard as `drawAspects`.
        let radiusByPlanet = Dictionary(
            zip(chart.planets.map(\.planet), radii),
            uniquingKeysWith: { first, _ in first }
        )
        return ZStack {
            ForEach(chart.planets, id: \.planet) { planet in
                let glyphRadius = radiusByPlanet[planet.planet] ?? placementRadius
                let pos = point(longitude: planet.longitude, radius: glyphRadius, center: center)
                Button {
                    Haptics.light.play()
                    onTapPlanet?(planet)
                } label: {
                    Text(ChartGlyphs.planetGlyph(planet.planet))
                        .font(.system(size: radius * 0.13))
                        .foregroundStyle(palette.planetGlyph)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .position(pos)
                .accessibilityLabel("\(planet.planet) at \(Int(planet.longitude))°")
            }
        }
    }

    private func midLongitude(from a: Double, to b: Double) -> Double {
        // Walk CCW from a to b; if b < a we wrap once.
        let span = (b - a + 360).truncatingRemainder(dividingBy: 360)
        return (a + span / 2).truncatingRemainder(dividingBy: 360)
    }
}
