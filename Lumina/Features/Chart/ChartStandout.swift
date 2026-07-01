import Foundation

/// The single most *notable* thing in a chart — a stellium or an unaspected
/// planet. The curiosity-gap dopamine hook ("wait, that's rare?") and a highly
/// screenshot-worthy fact about the user specifically. Pure and unit-testable
/// (see `docs/VIRALITY.md`).
struct ChartStandout: Equatable, Sendable {
    let headline: String
    let detail: String
}

enum ChartStandoutFinder {
    /// The most interesting standout, or nil when the chart is unremarkable.
    /// A stellium (3+ planets in one sign) beats a lone unaspected planet.
    static func find(in chart: NatalChart) -> ChartStandout? {
        stellium(in: chart) ?? unaspected(in: chart)
    }

    // MARK: - Standouts

    private static func stellium(in chart: NatalChart) -> ChartStandout? {
        var bySign: [String: Int] = [:]
        for planet in chart.planets {
            bySign[ChartGlyphs.sign(forLongitude: planet.longitude), default: 0] += 1
        }
        // First sign (canonical order) with the most planets, needing 3+.
        var bestSign: String?
        var bestCount = 2
        for sign in ChartGlyphs.signOrder where (bySign[sign] ?? 0) > bestCount {
            bestCount = bySign[sign] ?? 0
            bestSign = sign
        }
        guard let bestSign else { return nil }
        return ChartStandout(
            headline: "Your \(bestSign) stellium",
            detail: "\(bestCount) planets stacked in \(bestSign) — a rare, concentrated intensity most "
                + "charts don't have. That energy runs loud in your life."
        )
    }

    private static func unaspected(in chart: NatalChart) -> ChartStandout? {
        // Degenerate charts (no aspects at all) shouldn't call every planet lonely.
        let aspected = Set(chart.aspects.flatMap { [$0.planet1, $0.planet2] })
        guard !aspected.isEmpty else { return nil }
        let present = Set(chart.planets.map(\.planet))
        let lone = ChartGlyphs.planetOrder.first { present.contains($0) && !aspected.contains($0) }
        guard let lone else { return nil }
        return ChartStandout(
            headline: "Your \(lone) stands alone",
            detail: "\(lone) makes no major aspects in your chart — unaspected, it works on its own terms, "
                + "hard to integrate but unmistakably yours."
        )
    }
}
