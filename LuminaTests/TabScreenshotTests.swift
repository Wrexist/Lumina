@testable import Lumina
import SwiftUI
import UIKit
import XCTest

/// Renders each tab to a full-screen PNG under `LuminaTests/__Screenshots__/`
/// so the whole app can be reviewed without a Mac. Uses `TabPreviews`
/// compositions over the real components + sample data.
@MainActor
final class TabScreenshotTests: XCTestCase {
    func testTabChart() throws {
        try render(TabPreviews.chart(BirthChartViewModel.sampleChart()), named: "tab-chart")
    }

    func testTabToday() throws {
        let transits = TodayViewModel.sampleTransits()
        let lines = TodayViewModel.todayLines(from: transits)
        let view = TabPreviews.today(
            chart: BirthChartViewModel.sampleChart(),
            headline: lines.headline,
            secondary: lines.secondary,
            reading: DailyReading.compose(from: transits)
        )
        try render(view, named: "tab-today")
    }

    func testTabPeople() throws { try render(TabPreviews.people(), named: "tab-people") }
    func testTabReflect() throws { try render(TabPreviews.reflect(), named: "tab-reflect") }

    /// The onboarding rating screen, five stars tapped — the state the "Send
    /// in" button reacts to. Rendered rather than described: a screen that
    /// leads into Apple's rating card is not one anybody should have to take
    /// on trust, least of all whoever has to defend it under Guideline 1.1.7.
    func testOnboardingExcitement() throws {
        let screen = OnboardingScreens.Excitement(rating: .constant(5), name: "Sam")
            .padding(.vertical, LuminaSpacing.lg)
        try render(screen, named: "onboarding-excitement")
    }

    /// Only rendered when the tab is actually reachable. `tab-palm.png` is
    /// uploaded as a CI artifact and is the image people reach for when they
    /// want to see the app — producing one for a tab that isn't in the build
    /// is how a screenshot of an unshipped feature ends up somewhere it
    /// shouldn't be.
    func testTabPalm() throws {
        try XCTSkipUnless(LuminaTab.visible.contains(.palm),
                          "the Palm tab is not in this build — no screenshot of it should exist")
        try render(TabPreviews.palm(), named: "tab-palm")
    }

    private func render(_ view: some View, named name: String) throws {
        let framed = view
            .frame(width: 393, alignment: .topLeading)
            .background(LuminaColors.parchment)
            .environment(GlossaryStore.shared)
        let renderer = ImageRenderer(content: framed)
        renderer.scale = 2
        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("ImageRenderer produced no image for \(name)")
            return
        }
        let directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__Screenshots__")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent("\(name).png"))
        XCTAssertGreaterThan(data.count, 1_000, "\(name).png suspiciously small")
    }
}
