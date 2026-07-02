import SwiftUI

/// Planet-tap detail: degree, sign, house, retrograde flag, and a grounded
/// interpretation of the placement (`PlacementInterpreter`). A richer narrated
/// reading layers on later, server-side, without changing this surface.
struct PlanetDetailSheet: View {
    let planet: NatalChart.PlanetPosition
    let chart: NatalChart

    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var glyphSize: CGFloat = 64

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    header
                    factsCard
                    interpretationCard
                }
                .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle(planet.planet)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: recordDiscovery)
    }

    /// Chart discovery: opening a placement's reading counts as meeting it.
    /// One success haptic marks a first meeting — once per placement, ever.
    private func recordDiscovery() {
        if ChartDiscovery.shared.markExplored(planet.planet) {
            Haptics.success.play()
        }
    }

    private var header: some View {
        HStack(spacing: LuminaSpacing.md) {
            Text(ChartGlyphs.planetGlyph(planet.planet))
                .font(.system(size: glyphSize))
                .foregroundStyle(LuminaColors.mutedGold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text(ChartGlyphs.summary(planet: planet.planet, longitude: planet.longitude, house: house))
                    .font(LuminaTypography.heading)
                if planet.isRetrograde {
                    LuminaBadge(title: "Retrograde", tone: .neutral)
                }
            }
            Spacer()
        }
    }

    private var factsCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                row("Sign", value: ChartGlyphs.sign(forLongitude: planet.longitude))
                row("Degree", value: degreeString)
                if let house {
                    row("House", value: "\(house)")
                }
                row("Retrograde", value: planet.isRetrograde ? "Yes" : "No")
            }
        }
    }

    private var interpretationCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("What this means")
                    .font(LuminaTypography.heading)
                Text(PlacementInterpreter.interpretation(
                    planet: planet.planet,
                    longitude: planet.longitude,
                    house: house,
                    isRetrograde: planet.isRetrograde
                ))
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
            }
        }
    }

    private var degreeString: String {
        let degrees = Int(planet.longitude.truncatingRemainder(dividingBy: 30))
        let minutes = Int((planet.longitude.truncatingRemainder(dividingBy: 1)) * 60)
        return "\(degrees)° \(minutes)′"
    }

    /// House number (1–12) given the chart's cusps. Returns nil when the
    /// chart has no houses (unknown birth time).
    private var house: Int? {
        // A natal chart always carries exactly 12 cusps; guard so a malformed
        // payload can never drive `cusps[(index + 1) % 12]` out of bounds.
        guard let houses = chart.houses, houses.cusps.count == 12 else { return nil }
        let lon = (planet.longitude.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        for (index, cusp) in houses.cusps.enumerated() {
            let next = houses.cusps[(index + 1) % 12]
            if isLongitude(lon, between: cusp, and: next) {
                return index + 1
            }
        }
        return nil
    }

    private func row(_ key: String, value: String) -> some View {
        HStack {
            Text(key.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Spacer()
            Text(value)
                .font(LuminaTypography.body)
        }
    }

    private func isLongitude(_ lon: Double, between start: Double, and end: Double) -> Bool {
        if start <= end {
            return lon >= start && lon < end
        }
        // Wraps over 0°
        return lon >= start || lon < end
    }
}
