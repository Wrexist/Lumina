@testable import Lumina
import XCTest

/// Extends `NavigationTests`' universal-link coverage for the host-matching
/// fix: `www.lumina.app` and case-variant hosts must parse identically to
/// `lumina.app`, look-alike hosts must stay rejected, and
/// `LuminaDeepLink.isLuminaURL` must classify our schemes/hosts (and only
/// ours) so `RootView.onOpenURL` can fall back to `.today` safely.
final class UniversalLinkHostTests: XCTestCase {
    func testWWWHostParsesLikeBareHost() {
        XCTAssertEqual(parse("https://www.lumina.app/today"), .today)
        XCTAssertEqual(parse("https://www.lumina.app/chart/planet/Mars"), .chart(planet: "Mars"))
        XCTAssertEqual(parse("https://www.lumina.app/palm/scan"), .palmScan)
        XCTAssertEqual(parse("https://www.lumina.app/settings"), .settings)
    }

    func testHostMatchingIsCaseInsensitive() {
        XCTAssertEqual(parse("https://Lumina.App/today"), .today)
        XCTAssertEqual(parse("https://LUMINA.APP/chart"), .chart(planet: nil))
        XCTAssertEqual(parse("https://WWW.LUMINA.APP/chart/planet/Mars"), .chart(planet: "Mars"))
        XCTAssertEqual(parse("https://wWw.LuMiNa.aPp/help/billing"), .help(topicID: "billing"))
    }

    func testLookAlikeHostsStayRejected() {
        XCTAssertNil(parse("https://evil.lumina.app/chart"))
        XCTAssertNil(parse("https://xlumina.app/chart"))
        XCTAssertNil(parse("https://lumina.app.evil.com/chart"))
        XCTAssertNil(parse("https://wwwlumina.app/chart"))
        XCTAssertNil(parse("https://www.evil.lumina.app/chart"))
    }

    func testIsLuminaURLAcceptsOurSchemesAndHosts() {
        XCTAssertTrue(LuminaDeepLink.isLuminaURL(makeURL("lumina://not-a-real-route")))
        XCTAssertTrue(LuminaDeepLink.isLuminaURL(makeURL("https://lumina.app")))
        XCTAssertTrue(LuminaDeepLink.isLuminaURL(makeURL("https://www.lumina.app/unknown/path")))
        XCTAssertTrue(LuminaDeepLink.isLuminaURL(makeURL("https://WWW.Lumina.App/oops")))
    }

    func testIsLuminaURLRejectsForeignURLs() {
        XCTAssertFalse(LuminaDeepLink.isLuminaURL(makeURL("https://example.com/today")))
        XCTAssertFalse(LuminaDeepLink.isLuminaURL(makeURL("https://evil.lumina.app/today")))
        XCTAssertFalse(LuminaDeepLink.isLuminaURL(makeURL("http://lumina.app/today")))
        XCTAssertFalse(LuminaDeepLink.isLuminaURL(makeURL("mailto:hi@lumina.app")))
    }

    func testBareHostWithoutPathStillDoesNotParseToARoute() {
        // Kept in sync with `NavigationTests.testForeignSchemeReturnsNil`:
        // a path-less link is not a route — the `.today` fallback happens in
        // `RootView.onOpenURL` via `isLuminaURL`, not inside the parser.
        XCTAssertNil(parse("https://lumina.app"))
        XCTAssertNil(parse("https://www.lumina.app"))
    }

    // MARK: - Helpers

    private func parse(_ raw: String) -> LuminaDeepLink? {
        LuminaDeepLink.from(url: makeURL(raw))
    }

    private func makeURL(_ raw: String) -> URL {
        URL(string: raw) ?? URL(fileURLWithPath: "/")
    }
}
