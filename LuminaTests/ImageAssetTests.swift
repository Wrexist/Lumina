@testable import Lumina
import UIKit
import XCTest

/// The generated art is only as good as its wiring: an asset renamed in
/// `assets/`, a `.imageset` the build script didn't write, or a case whose
/// raw value drifted from the catalog all fail the same way at runtime — a
/// silent blank space where a planet should be. These run on the simulator
/// against the real compiled catalog, so they catch every one of those.
final class ImageAssetTests: XCTestCase {
    func testEveryAssetResolvesInTheBundle() {
        for asset in LuminaImageAsset.allCases {
            XCTAssertNotNil(asset.uiImage, "missing image asset: \(asset.rawValue)")
        }
    }

    /// 10 planets · 12 constellations · 3 illustrations · 1 texture. A drop
    /// here means art fell out of the catalog without anyone noticing.
    func testTheSetIsComplete() {
        XCTAssertEqual(LuminaImageAsset.allCases.count, 26)
        let names = Set(LuminaImageAsset.allCases.map(\.rawValue))
        XCTAssertEqual(names.count, LuminaImageAsset.allCases.count, "duplicate asset name")
    }

    /// Every body the chart plots gets a sphere — except the Moon, which is
    /// rendered live from the real phase and must *not* have a static image
    /// (see `MoonSphere3DView`).
    func testEveryChartBodyExceptTheMoonHasASphere() {
        for planet in ChartGlyphs.planetOrder where planet != "Moon" {
            XCTAssertNotNil(LuminaImageAsset.planet(planet), "no sphere for \(planet)")
        }
        XCTAssertNil(LuminaImageAsset.planet("Moon"))
    }

    /// Earth isn't a chart placement, so it's absent from `planetOrder` — but
    /// the transparency sheet uses it to say where the positions are measured
    /// from, so the mapping has to know it.
    func testEarthResolvesEvenThoughItIsNotAChartPlacement() {
        XCTAssertFalse(ChartGlyphs.planetOrder.contains("Earth"))
        XCTAssertEqual(LuminaImageAsset.planet("Earth"), .planetEarth)
    }

    func testUnknownBodyFallsBackRatherThanGuessing() {
        XCTAssertNil(LuminaImageAsset.planet("Chiron"))
        XCTAssertNil(LuminaImageAsset.planet(""))
        XCTAssertNil(LuminaImageAsset.constellation(sign: "Ophiuchus"))
    }

    /// The People avatars key off `ChartGlyphs.signOrder` spellings; a
    /// mismatch would silently drop a whole sign back to its monogram.
    func testEverySignHasAConstellation() {
        let assets = ChartGlyphs.signOrder.compactMap { LuminaImageAsset.constellation(sign: $0) }
        XCTAssertEqual(assets.count, 12)
        XCTAssertEqual(Set(assets).count, 12, "two signs share one constellation")
    }

    // MARK: - Sun sign from a date alone

    /// The boundaries `CompatibilityScorer` has always scored against, now
    /// shared with the People avatars — pinned here so the two can't drift.
    func testSunSignBoundaries() {
        XCTAssertEqual(sign(month: 3, day: 20), "Pisces")
        XCTAssertEqual(sign(month: 3, day: 21), "Aries")
        XCTAssertEqual(sign(month: 4, day: 19), "Aries")
        XCTAssertEqual(sign(month: 4, day: 20), "Taurus")
        XCTAssertEqual(sign(month: 12, day: 21), "Sagittarius")
        XCTAssertEqual(sign(month: 12, day: 22), "Capricorn")
        // The one range that wraps the year end.
        XCTAssertEqual(sign(month: 1, day: 19), "Capricorn")
        XCTAssertEqual(sign(month: 1, day: 20), "Aquarius")
    }

    /// Every day of a leap year lands on exactly one of the twelve signs —
    /// no gap at a cusp, no day answering with something `signOrder` (and so
    /// the constellation lookup) doesn't know.
    func testEveryDayOfTheYearMapsToAKnownSign() {
        var calendar = Calendar(identifier: .gregorian)
        guard let utc = TimeZone(identifier: "UTC") else {
            XCTFail("no UTC zone")
            return
        }
        calendar.timeZone = utc
        let known = Set(ChartGlyphs.signOrder)

        var seen = Set<String>()
        for dayOfYear in 1...366 {
            var components = DateComponents()
            components.year = 2024
            components.day = dayOfYear
            components.hour = 12
            guard let date = calendar.date(from: components) else {
                XCTFail("could not build day \(dayOfYear)")
                return
            }
            let sign = ChartGlyphs.sunSign(for: date, calendar: calendar)
            XCTAssertTrue(known.contains(sign), "unknown sign \(sign) on day \(dayOfYear)")
            seen.insert(sign)
        }
        XCTAssertEqual(seen.count, 12, "a sign never comes up across a full year")
    }

    /// A cusp birth read in the wrong zone is a different sign; the People
    /// list passes the friend's own birth zone for exactly this reason.
    func testSunSignIsReadInTheGivenZone() {
        guard
            let utc = TimeZone(identifier: "UTC"),
            let auckland = TimeZone(identifier: "Pacific/Auckland")
        else {
            XCTFail("missing time zones")
            return
        }

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utc
        var aucklandCalendar = Calendar(identifier: .gregorian)
        aucklandCalendar.timeZone = auckland

        // 2024-03-20 22:00 UTC is already 2024-03-21 in Auckland (UTC+13).
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 20
        components.hour = 22
        guard let instant = utcCalendar.date(from: components) else {
            XCTFail("could not build the cusp instant")
            return
        }

        XCTAssertEqual(ChartGlyphs.sunSign(for: instant, calendar: utcCalendar), "Pisces")
        XCTAssertEqual(ChartGlyphs.sunSign(for: instant, calendar: aucklandCalendar), "Aries")
    }

    private func sign(month: Int, day: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        if let utc = TimeZone(identifier: "UTC") {
            calendar.timeZone = utc
        }
        var components = DateComponents()
        components.year = 2024
        components.month = month
        components.day = day
        components.hour = 12
        guard let date = calendar.date(from: components) else { return "" }
        return ChartGlyphs.sunSign(for: date, calendar: calendar)
    }
}
