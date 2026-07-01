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
}
