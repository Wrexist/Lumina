@testable import Lumina
import XCTest

/// Tests for the chart-wheel glyph de-clustering maths
/// (`ChartWheelLayout`). Guards the conjunction-overlap fix: planets within
/// a few degrees of each other must stack at staggered radii rather than
/// render on the same point. See `docs/AUDIT-2026-06-03.md` (R5).
final class ChartWheelLayoutTests: XCTestCase {
    private let placement: CGFloat = 100
    private let step: CGFloat = 10
    private let band: ClosedRange<CGFloat> = 50...150

    // MARK: - Degenerate inputs

    func testEmptyInputReturnsEmpty() {
        XCTAssertTrue(staggered([]).isEmpty)
        XCTAssertTrue(ChartWheelLayout.clusters(longitudes: []).isEmpty)
    }

    func testSinglePlanetSitsOnPlacement() {
        XCTAssertEqual(staggered([42]), [placement])
        XCTAssertEqual(ChartWheelLayout.clusters(longitudes: [42]), [[0]])
    }

    // MARK: - No clustering for well-separated planets

    func testFarApartPlanetsBothStayOnPlacement() {
        XCTAssertEqual(staggered([10, 200]), [placement, placement])
    }

    func testEveryRadiusIsReturnedInInputOrder() {
        // 200° is isolated (stays on placement); 10°/14° are conjunct.
        let radii = staggered([200, 10, 14])
        XCTAssertEqual(radii.count, 3)
        XCTAssertEqual(radii[0], placement, "the isolated planet keeps the nominal radius")
        XCTAssertNotEqual(radii[1], radii[2], "conjunct planets must not share a radius")
    }

    // MARK: - Conjunction stacking

    func testConjunctPairStaggersSymmetricallyAroundPlacement() {
        let radii = staggered([10, 15])
        XCTAssertEqual(radii[0], placement - step / 2)
        XCTAssertEqual(radii[1], placement + step / 2)
        // Mean stays on the nominal band centre.
        XCTAssertEqual((radii[0] + radii[1]) / 2, placement, accuracy: 0.0001)
    }

    func testConjunctionAcrossZeroAriesIsOneCluster() {
        // 358° and 2° are 4° apart across the 0°/360° seam — the gap-cut must
        // treat them as conjunct, not as the two most distant points.
        let groups = ChartWheelLayout.clusters(longitudes: [358, 2])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.count, 2)

        let radii = staggered([358, 2])
        XCTAssertNotEqual(radii[0], radii[1])
    }

    func testStelliumStaysWithinBand() {
        // Four planets 4° apart near the band's upper edge; the fan-out must
        // clamp so no glyph overruns the surrounding rings.
        let radii = ChartWheelLayout.staggeredRadii(
            longitudes: [10, 14, 18, 22],
            placement: 145,
            step: 20,
            band: band
        )
        for radius in radii {
            XCTAssertGreaterThanOrEqual(radius, band.lowerBound)
            XCTAssertLessThanOrEqual(radius, band.upperBound)
        }
    }

    // MARK: - Helpers

    private func staggered(_ longitudes: [Double]) -> [CGFloat] {
        ChartWheelLayout.staggeredRadii(
            longitudes: longitudes,
            placement: placement,
            step: step,
            band: band
        )
    }
}
