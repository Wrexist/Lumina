@testable import Lumina
import XCTest

/// Tests that `lumina://chart/planet/<name>` round-trips through
/// `LuminaDeepLink` parsing and lands on `AppRouter.pendingPresentation`
/// in a shape `ChartHubView` can consume. The actual sheet presentation
/// is exercised by hand on a simulator — these tests cover the routing
/// contract.
final class DeepLinkRoutingTests: XCTestCase {
    @MainActor
    func testChartPlanetDeepLinkSelectsChartTabAndStashesPresentation() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()

        let url = URL(string: "lumina://chart/planet/Mars")
        let link = url.flatMap(LuminaDeepLink.from(url:))
        XCTAssertEqual(link, .chart(planet: "Mars"))

        guard let link else { return }
        router.handle(deepLink: link)
        XCTAssertEqual(router.selectedTab, .chart)
        XCTAssertEqual(router.pendingPresentation, .chart(planet: "Mars"))
    }

    @MainActor
    func testBareChartLinkSelectsTabWithoutPlanet() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()

        guard let link = LuminaDeepLink.from(url: URL(string: "lumina://chart") ?? URL(fileURLWithPath: "/")) else {
            XCTFail("expected chart deep link to parse")
            return
        }
        router.handle(deepLink: link)
        XCTAssertEqual(router.selectedTab, .chart)
        XCTAssertEqual(router.pendingPresentation, .chart(planet: nil))
    }

    @MainActor
    func testChartPlanetUniversalLinkSelectsChartTabAndStashesPresentation() {
        // Same contract as the `lumina://` test above, but via the
        // `https://lumina.app/...` universal link shape.
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()

        let url = URL(string: "https://lumina.app/chart/planet/Mars")
        let link = url.flatMap(LuminaDeepLink.from(url:))
        XCTAssertEqual(link, .chart(planet: "Mars"))

        guard let link else { return }
        router.handle(deepLink: link)
        XCTAssertEqual(router.selectedTab, .chart)
        XCTAssertEqual(router.pendingPresentation, .chart(planet: "Mars"))
    }

    // MARK: - Unconsumed links leave no stale pending

    /// `.palmScan` has no consumer (capture isn't shipped). It must switch to
    /// the Palm tab and leave `pendingPresentation` nil, and a repeat of the
    /// exact same link must re-switch the tab — never silently no-op because a
    /// stale value was left behind.
    @MainActor
    func testUnconsumedPalmScanSwitchesTabAndLeavesNoStalePending() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()

        router.selectedTab = .today
        router.handle(deepLink: .palmScan)
        XCTAssertEqual(router.selectedTab, .palm)
        XCTAssertNil(router.pendingPresentation)

        // Repeat the same link from a different tab — it must re-switch.
        router.selectedTab = .today
        router.handle(deepLink: .palmScan)
        XCTAssertEqual(router.selectedTab, .palm)
        XCTAssertNil(router.pendingPresentation)
    }

    /// A payload-bearing but unconsumed link (`.people(friendID:)`) is
    /// tab-switch-only too: switch to People, strand nothing.
    @MainActor
    func testUnconsumedPeopleFriendIDLinkSwitchesTabAndLeavesNoStalePending() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()

        let id = UUID()
        router.selectedTab = .today
        router.handle(deepLink: .people(friendID: id))
        XCTAssertEqual(router.selectedTab, .people)
        XCTAssertNil(router.pendingPresentation)

        router.selectedTab = .today
        router.handle(deepLink: .people(friendID: id))
        XCTAssertEqual(router.selectedTab, .people)
        XCTAssertNil(router.pendingPresentation)
    }

    /// A prior consumed link (`.chart`) leaves a pending value; handling an
    /// unconsumed link afterward must clear it, not inherit it.
    @MainActor
    func testUnconsumedLinkClearsPendingLeftByAConsumedLink() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()

        router.handle(deepLink: .chart(planet: "Mars"))
        XCTAssertEqual(router.pendingPresentation, .chart(planet: "Mars"))

        router.handle(deepLink: .reflect(entryID: nil))
        XCTAssertEqual(router.selectedTab, .reflect)
        XCTAssertNil(router.pendingPresentation)
    }
}
