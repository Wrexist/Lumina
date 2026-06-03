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
    let chart: NatalChart
    var onTapPlanet: ((NatalChart.PlanetPosition) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let radius = size / 2

            ZStack {
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
            with: .color(LuminaColors.inkBlack.opacity(0.6)),
            lineWidth: 1
        )
        context.stroke(
            Path { path in path.addArc(center: center, radius: inner, startAngle: .zero, endAngle: .degrees(360), clockwise: false) },
            with: .color(LuminaColors.inkBlack.opacity(0.4)),
            lineWidth: 1
        )

        // 12 dividers at every 30°
        for i in 0..<12 {
            let cuspLongitude = Double(i) * 30
            let p1 = point(longitude: cuspLongitude, radius: inner, center: center)
            let p2 = point(longitude: cuspLongitude, radius: outer, center: center)
            context.stroke(
                Path { path in path.move(to: p1); path.addLine(to: p2) },
                with: .color(LuminaColors.inkBlack.opacity(0.35)),
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
                .foregroundColor(LuminaColors.mutedGold)
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
            with: .color(LuminaColors.inkBlack.opacity(0.25)),
            lineWidth: 1
        )

        // Cusp dividers — Asc/Desc/MC/IC slightly heavier
        for (index, cusp) in houses.cusps.enumerated() {
            let isAngular = index == 0 || index == 3 || index == 6 || index == 9
            let p1 = point(longitude: cusp, radius: inner, center: center)
            let p2 = point(longitude: cusp, radius: outer, center: center)
            context.stroke(
                Path { path in path.move(to: p1); path.addLine(to: p2) },
                with: .color(LuminaColors.inkBlack.opacity(isAngular ? 0.6 : 0.2)),
                lineWidth: isAngular ? 1.5 : 0.8
            )

            // House numerals just inside the cusp's mid-sector
            let nextCusp = houses.cusps[(index + 1) % 12]
            let mid = midLongitude(from: cusp, to: nextCusp)
            let labelPos = point(longitude: mid, radius: inner * 0.92, center: center)
            let numeralText = Text("\(index + 1)")
                .font(.system(size: radius * 0.06, weight: .light, design: .monospaced))
                .foregroundColor(LuminaColors.inkBlack.opacity(0.55))
            context.draw(numeralText, at: labelPos)
        }
    }

    private func drawAspects(in context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let aspectRadius = radius * 0.50
        let positions = Dictionary(
            uniqueKeysWithValues: chart.planets.map { ($0.planet, $0.longitude) }
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

    private func aspectColor(_ type: AspectType) -> Color {
        switch type {
        case .conjunction: LuminaColors.mutedGold.opacity(0.6)
        case .sextile, .trine: LuminaColors.celestialBlue.opacity(0.45)
        case .square, .opposition: LuminaColors.blush.opacity(0.65)
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
                .foregroundColor(LuminaColors.mutedGold)
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
        let radiusByPlanet = Dictionary(
            uniqueKeysWithValues: zip(chart.planets.map(\.planet), radii)
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
                        .foregroundStyle(LuminaColors.inkBlack)
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
