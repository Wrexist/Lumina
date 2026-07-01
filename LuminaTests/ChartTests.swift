@testable import Lumina
import XCTest

/// Phase-4 chart tests. Glyph mapping, sample-chart shape, and
/// `BirthChartViewModel` state transitions ride CI on every push.
final class ChartTests: XCTestCase {
    // MARK: - ChartGlyphs

    func testSignForLongitudeWrapsAt360() {
        XCTAssertEqual(ChartGlyphs.sign(forLongitude: 0), "Aries")
        XCTAssertEqual(ChartGlyphs.sign(forLongitude: 29.99), "Aries")
        XCTAssertEqual(ChartGlyphs.sign(forLongitude: 30), "Taurus")
        XCTAssertEqual(ChartGlyphs.sign(forLongitude: 359.9), "Pisces")
        XCTAssertEqual(ChartGlyphs.sign(forLongitude: 360), "Aries")
        XCTAssertEqual(ChartGlyphs.sign(forLongitude: 720), "Aries")
        XCTAssertEqual(ChartGlyphs.sign(forLongitude: -30), "Pisces")
    }

    func testPlanetGlyphsCoverFullSet() {
        for name in ChartGlyphs.planetOrder {
            XCTAssertNotEqual(ChartGlyphs.planetGlyph(name), "•", "no glyph for \(name)")
        }
    }

    func testSignOrderHasTwelveSigns() {
        XCTAssertEqual(ChartGlyphs.signOrder.count, 12)
    }

    func testGlyphsForceMonochromeTextPresentation() {
        // Zodiac signs (U+2648–2653) default to colour-emoji; we append the
        // text-presentation selector (U+FE0E) so they render as premium
        // monochrome type in the brand colour. Guard against regressing.
        let textPresentation: Unicode.Scalar = "\u{FE0E}"
        for sign in ChartGlyphs.signOrder {
            XCTAssertTrue(
                ChartGlyphs.signGlyph(sign).unicodeScalars.contains(textPresentation),
                "\(sign) glyph must carry the text-presentation selector (no emoji)"
            )
        }
        for planet in ChartGlyphs.planetOrder {
            XCTAssertTrue(
                ChartGlyphs.planetGlyph(planet).unicodeScalars.contains(textPresentation),
                "\(planet) glyph must carry the text-presentation selector (no emoji)"
            )
        }
    }

    // MARK: - BirthChartViewModel.sampleChart

    @MainActor
    func testSampleChartHasAllTenPlanets() {
        let chart = BirthChartViewModel.sampleChart()
        XCTAssertEqual(chart.planets.count, 10)
        for name in ChartGlyphs.planetOrder {
            XCTAssertNotNil(
                chart.planets.first(where: { $0.planet == name }),
                "sample chart missing \(name)"
            )
        }
    }

    @MainActor
    func testSampleChartHasHouses() {
        let chart = BirthChartViewModel.sampleChart()
        XCTAssertNotNil(chart.houses)
        XCTAssertEqual(chart.houses?.cusps.count, 12)
    }

    // MARK: - UserBirthDataStore

    func testBirthDataRoundTrip() {
        let suite = "lumina.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = UserBirthDataStore(defaults: defaults)
        let birthData = BirthData(
            birthDate: Date(timeIntervalSince1970: 0),
            birthTime: Date(timeIntervalSince1970: 1_000),
            placeName: "Stockholm",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
        store.save(birthData)
        let loaded = store.load()
        XCTAssertEqual(loaded?.placeName, "Stockholm")
        XCTAssertEqual(loaded?.latitude ?? 0, 59.3293, accuracy: 0.001)
        XCTAssertEqual(loaded?.timeZoneIdentifier, "Europe/Stockholm")

        store.clear()
        XCTAssertNil(store.load())
    }

    // MARK: - PaywallTracker

    @MainActor
    func testPaywallTrackerInitialOfferAndRescue() {
        let suite = "lumina.tests.paywall.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let tracker = PaywallTracker(defaults: defaults)
        XCTAssertFalse(tracker.hasSeenInitialOffer)
        XCTAssertFalse(tracker.hasShownRescue)
        XCTAssertFalse(tracker.shouldShowRescue())

        tracker.recordInitialOfferSeen()
        XCTAssertTrue(tracker.hasSeenInitialOffer)
        XCTAssertTrue(tracker.shouldShowRescue())

        tracker.recordRescueShown()
        XCTAssertFalse(
            tracker.shouldShowRescue(),
            "rescue should fire at most once per install"
        )
    }
}
