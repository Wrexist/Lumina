import SwiftUI

/// Sun / Moon / Rising — the three placements every casual user can name.
/// Each cell is tappable: Sun and Moon open the full placement reading, Rising
/// opens the ascendant reading. Sits at the top of the Chart and Today tabs so
/// first-time users see something they recognise — and can act on — before the
/// full wheel decoder-ring sets in.
struct BigThreeBand: View {
    let chart: NatalChart
    @State private var selection: Selection?
    @ScaledMetric private var glyphSize: CGFloat = 36

    /// What the user tapped — a planet placement or the (non-planet) ascendant.
    private enum Selection: Identifiable {
        case planet(NatalChart.PlanetPosition)
        case ascendant(Double)

        var id: String {
            switch self {
            case .planet(let planet): planet.planet
            case .ascendant: "Ascendant"
            }
        }
    }

    var body: some View {
        HStack(spacing: LuminaSpacing.md) {
            planetCell("Sun")
            planetCell("Moon")
            risingCell
        }
        .sheet(item: $selection, content: detailSheet)
    }

    // MARK: - Cells

    @ViewBuilder
    private func planetCell(_ name: String) -> some View {
        if let planet = chart.planets.first(where: { $0.planet == name }) {
            Button {
                Haptics.light.play()
                selection = .planet(planet)
            } label: {
                cell(label: name, longitude: planet.longitude)
            }
            .buttonStyle(.plain)
        } else {
            cell(label: name, longitude: nil)
        }
    }

    @ViewBuilder
    private var risingCell: some View {
        if let ascendant = chart.houses?.ascendant {
            Button {
                Haptics.light.play()
                selection = .ascendant(ascendant)
            } label: {
                cell(label: "Rising", longitude: ascendant)
            }
            .buttonStyle(.plain)
        } else {
            cell(label: "Rising", longitude: nil)
        }
    }

    @ViewBuilder
    private func detailSheet(_ selection: Selection) -> some View {
        switch selection {
        case .planet(let planet):
            PlanetDetailSheet(planet: planet, chart: chart)
        case .ascendant(let longitude):
            AscendantDetailSheet(ascendant: longitude)
        }
    }

    // MARK: - Cell rendering

    private func cell(label: String, longitude: Double?) -> some View {
        LuminaCard(padding: LuminaSpacing.sm) {
            VStack(spacing: LuminaSpacing.xs) {
                Text(label.uppercased())
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(longitude.map(signGlyph) ?? "—")
                    .font(.system(size: glyphSize))
                    .foregroundStyle(LuminaColors.mutedGold)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(longitude.map(signName) ?? "Hidden")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func signGlyph(_ longitude: Double) -> String {
        ChartGlyphs.signGlyph(ChartGlyphs.sign(forLongitude: longitude))
    }

    private func signName(_ longitude: Double) -> String {
        ChartGlyphs.sign(forLongitude: longitude)
    }
}
