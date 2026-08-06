@testable import Lumina
import SwiftUI
import UIKit
import XCTest

/// Renders submission-ready App Store screenshots at exactly the 6.9" size
/// Apple requires — 1320 × 2868 — into `LuminaTests/__AppStoreShots__/`.
///
/// Why this exists: `LAUNCH-STEPS.md` Step 8 was the only part of the release
/// path that still needed a Mac. The TestFlight lane already archives and
/// uploads from CI, so screenshots were the last manual step, and "take six
/// screenshots by hand" is exactly the task that gets done once and then goes
/// stale two releases later. These regenerate on every run.
///
/// 440 × 956 points at scale 3 is 1320 × 2868 pixels — the iPhone 16 Pro Max
/// / 17 Pro Max canvas. Apple scales that set down for every smaller iPhone,
/// so this one set is all a submission needs.
///
/// Captions come from `docs/aso/SCREENSHOTS.md` and are part of the store
/// listing: they carry real keywords (Apple OCRs screenshot text) and each
/// one describes what its own frame actually shows.
///
/// **One frame from that storyboard isn't here.** The 3D moon is a SceneKit
/// `UIViewRepresentable`, which `ImageRenderer` cannot drive. Capture it by
/// hand on a simulator, or ship five — five honest screenshots beat six with
/// one blank frame.
@MainActor
final class AppStoreShotTests: XCTestCase {
    private static let canvas = CGSize(width: 440, height: 956)
    private static let contentWidth: CGFloat = 393

    func testTodayShot() throws {
        let transits = TodayViewModel.sampleTransits()
        let lines = TodayViewModel.todayLines(from: transits)
        let today = TabPreviews.today(
            chart: BirthChartViewModel.sampleChart(),
            headline: lines.headline,
            secondary: lines.secondary,
            reading: DailyReading.compose(from: transits)
        )
        try shot(today,
                 caption: "Your daily horoscope,\nfrom real transits",
                 named: "01-today")
    }

    func testChartShot() throws {
        try shot(TabPreviews.chart(BirthChartViewModel.sampleChart()),
                 caption: "Your birth chart,\ncomputed — not guessed",
                 named: "02-birth-chart")
    }

    func testPeopleShot() throws {
        try shot(TabPreviews.people(),
                 caption: "Synastry for the people\nyou add",
                 named: "03-synastry")
    }

    func testReflectShot() throws {
        try shot(TabPreviews.reflect(),
                 caption: "A private journal that\nnever leaves your iPhone",
                 named: "05-reflect")
    }

    /// `HumanDesignActivation.compute(from:)` is pure, so this frame shows the
    /// real calculation rather than a drawing of one — which is what lets it
    /// be generated at all.
    func testHumanDesignShot() throws {
        try shot(TabPreviews.humanDesign(BirthChartViewModel.sampleChart()),
                 caption: "Your Human Design bodygraph,\nfrom the same birth data",
                 named: "04-human-design")
    }

    /// Every shot must land on Apple's exact pixel dimensions — App Store
    /// Connect rejects the upload otherwise, and finding that out during
    /// submission costs a round trip.
    func testEveryShotIsExactlyTheRequiredSize() throws {
        let directory = Self.directory()
        let files = (try? FileManager.default.contentsOfDirectory(at: directory,
                                                                  includingPropertiesForKeys: nil)) ?? []
        let shots = files.filter { $0.pathExtension == "png" }
        guard !shots.isEmpty else {
            throw XCTSkip("no shots rendered yet — the render tests populate this directory")
        }
        for url in shots {
            let image = try XCTUnwrap(UIImage(data: Data(contentsOf: url)), url.lastPathComponent)
            let pixels = CGSize(width: image.size.width * image.scale,
                                height: image.size.height * image.scale)
            XCTAssertEqual(pixels.width, 1320, accuracy: 1, "\(url.lastPathComponent) width")
            XCTAssertEqual(pixels.height, 2868, accuracy: 1, "\(url.lastPathComponent) height")
        }
    }

    // MARK: - Rendering

    private func shot(_ content: some View, caption: String, named name: String) throws {
        let page = VStack(spacing: LuminaSpacing.lg) {
            Text(caption)
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.parchment)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, LuminaSpacing.lg)
                .padding(.top, LuminaSpacing.xl)

            // The real screen, at its real width, on a card — cropped at the
            // bottom rather than squashed, so nothing in the frame is a
            // rendering that the app can't produce.
            content
                .frame(width: Self.contentWidth, alignment: .topLeading)
                .background(LuminaColors.parchment)
                .luminaCornerRadius(LuminaRadii.lg)
                .frame(maxHeight: .infinity, alignment: .top)
                .clipped()
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height, alignment: .top)
        .background(LuminaColors.midnight)
        .environment(GlossaryStore.shared)

        let renderer = ImageRenderer(content: page)
        renderer.scale = 3
        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("ImageRenderer produced no image for \(name)")
            return
        }

        let directory = Self.directory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent("\(name).png"))
        XCTAssertGreaterThan(data.count, 10_000, "\(name).png suspiciously small")
    }

    private static func directory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__AppStoreShots__")
    }
}
