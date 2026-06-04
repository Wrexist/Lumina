@testable import Lumina
import SwiftUI
import UIKit
import XCTest

/// Renders key screens to PNGs under `LuminaTests/__Screenshots__/` so CI can
/// upload them as build artifacts — the no-Mac way to actually *see* the UI
/// (there is no local simulator; the app isn't on TestFlight yet).
///
/// Uses the native `ImageRenderer` — no snapshot-library dependency, no
/// reference-image dance. Brand fonts (PP Editorial New / Söhne) fall back to
/// system faces in CI until their licenses land, so type here is indicative,
/// not final. Tests are ordered (`A`, `B`, …) so the simplest, most reliable
/// render writes its file first.
@MainActor
final class ScreenshotTests: XCTestCase {
    func testARenderChartWheel() throws {
        let view = ChartWheelView(chart: BirthChartViewModel.sampleChart())
            .padding(LuminaSpacing.md)
            .frame(width: 393, height: 393)
            .background(LuminaColors.parchment)
        try render(view, named: "chart-wheel")
    }

    func testBRenderTodayHeadline() throws {
        let lines = TodayViewModel.todayLines(from: TodayViewModel.sampleTransits())
        let view = todayComposition(lines: lines)
            .frame(width: 393)
            .background(LuminaColors.parchment)
        try render(view, named: "today")
    }

    func testCRenderSynastry() throws {
        let aspects = [
            SynastryAspect(planetA: "Venus", planetB: "Mars", type: .conjunction, exactAngle: 0, orb: 1.1),
            SynastryAspect(planetA: "Sun", planetB: "Moon", type: .trine, exactAngle: 120, orb: 1.6),
            SynastryAspect(planetA: "Moon", planetB: "Venus", type: .sextile, exactAngle: 60, orb: 2.0),
            SynastryAspect(planetA: "Mars", planetB: "Saturn", type: .square, exactAngle: 90, orb: 2.4),
        ]
        let view = synastryComposition(aspects: aspects)
            .frame(width: 393)
            .background(LuminaColors.parchment)
        try render(view, named: "synastry")
    }

    func testDRenderPlanetReading() throws {
        let view = planetReadingComposition()
            .frame(width: 393)
            .background(LuminaColors.parchment)
        try render(view, named: "planet-reading")
    }

    // MARK: - Composition

    /// Reassembles the Today loaded layout from the real components + sample
    /// transit data (the live view loads asynchronously, which `ImageRenderer`
    /// won't drive).
    private func todayComposition(lines: (headline: String?, secondary: [String])) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text("TUESDAY · JUN 3")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text("Your sky today")
                    .font(LuminaTypography.display)
            }
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text(lines.headline ?? "A quiet sky today.")
                        .font(LuminaTypography.heading)
                    Text("Tap any planet on the Chart tab to learn more about your placements.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("WHAT'S HAPPENING")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                ForEach(lines.secondary, id: \.self) { line in
                    HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                        Text("•").font(LuminaTypography.body)
                        Text(line).font(LuminaTypography.body)
                    }
                }
            }
        }
        .padding(LuminaSpacing.lg)
    }

    /// Mirrors the People-tab "Between your charts" card with sample synastry.
    private func synastryComposition(aspects: [SynastryAspect]) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text("REFLECTION ON")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text("Sam")
                    .font(LuminaTypography.display)
            }
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text("Between your charts")
                        .font(LuminaTypography.heading)
                    Text("The real chart-to-chart contacts between you.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    ForEach(aspects) { aspect in
                        HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                            Text("•").font(LuminaTypography.body)
                            Text(SynastryPhrasing.sentence(for: aspect)).font(LuminaTypography.body)
                        }
                    }
                }
            }
        }
        .padding(LuminaSpacing.lg)
    }

    /// Mirrors the Planet-detail sheet: real glyph + summary + the real
    /// grounded `PlacementInterpreter` reading for Venus in Gemini, 9th house.
    private func planetReadingComposition() -> some View {
        let longitude = 75.0
        return VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            HStack(spacing: LuminaSpacing.md) {
                Text(ChartGlyphs.planetGlyph("Venus"))
                    .font(.system(size: 64))
                    .foregroundStyle(LuminaColors.mutedGold)
                Text(ChartGlyphs.summary(planet: "Venus", longitude: longitude, house: 9))
                    .font(LuminaTypography.heading)
                Spacer()
            }
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text("What this means")
                        .font(LuminaTypography.heading)
                    Text(PlacementInterpreter.interpretation(
                        planet: "Venus", longitude: longitude, house: 9, isRetrograde: false
                    ))
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
                }
            }
        }
        .padding(LuminaSpacing.lg)
    }

    // MARK: - Render helper

    private func render(_ view: some View, named name: String) throws {
        let renderer = ImageRenderer(content: view.environment(GlossaryStore.shared))
        renderer.scale = 2
        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("ImageRenderer produced no image for \(name)")
            return
        }
        let directory = Self.screenshotDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent("\(name).png"))
        XCTAssertGreaterThan(data.count, 1_000, "\(name).png is suspiciously small")
    }

    private static func screenshotDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__Screenshots__")
    }
}
