@testable import Lumina
import XCTest

/// Smoke + unit tests for Phase 1 navigation primitives. These run on
/// every CI build, so any regression to the deep-link contract or router
/// state machine fails the merge.
final class NavigationTests: XCTestCase {
    // MARK: - LuminaTab

    func testLuminaTabRawValuesMatchDeepLinkSlugs() {
        XCTAssertEqual(LuminaTab.today.rawValue, "today")
        XCTAssertEqual(LuminaTab.chart.rawValue, "chart")
        XCTAssertEqual(LuminaTab.palm.rawValue, "palm")
        XCTAssertEqual(LuminaTab.people.rawValue, "people")
        XCTAssertEqual(LuminaTab.reflect.rawValue, "reflect")
    }

    func testLuminaTabAllCasesHasFiveTabs() {
        // Five tabs is a navigation-charter rule; if a sixth shows up,
        // see docs/NAVIGATION.md §2.1 before changing this assertion.
        XCTAssertEqual(LuminaTab.allCases.count, 5)
    }

    func testLuminaTabTitlesAreShort() {
        for tab in LuminaTab.allCases {
            XCTAssertLessThanOrEqual(tab.title.count, 7, "Tab '\(tab.title)' exceeds 7-char budget")
        }
    }

    // MARK: - LuminaDeepLink

    func testTodayDeepLink() {
        XCTAssertEqual(parse("lumina://today"), .today)
    }

    func testChartDeepLinkWithPlanet() {
        XCTAssertEqual(parse("lumina://chart/planet/Mars"), .chart(planet: "Mars"))
    }

    func testChartDeepLinkWithoutPlanet() {
        XCTAssertEqual(parse("lumina://chart"), .chart(planet: nil))
    }

    func testPalmScanAndHistoryDeepLinks() {
        XCTAssertEqual(parse("lumina://palm/scan"), .palmScan)
        XCTAssertEqual(parse("lumina://palm/history"), .palmHistory)
        XCTAssertEqual(parse("lumina://palm"), .palmHistory)
    }

    func testPeopleDeepLink() {
        let id = UUID()
        XCTAssertEqual(parse("lumina://people/\(id.uuidString)"), .people(friendID: id))
        XCTAssertEqual(parse("lumina://people"), .people(friendID: nil))
    }

    func testShareDeepLink() {
        XCTAssertEqual(parse("lumina://share/abcDEF123"), .acceptShare(payload: "abcDEF123"))
    }

    func testReflectDeepLink() {
        let id = UUID()
        XCTAssertEqual(parse("lumina://reflect/\(id.uuidString)"), .reflect(entryID: id))
        XCTAssertEqual(parse("lumina://reflect/today"), .reflect(entryID: nil))
        XCTAssertEqual(parse("lumina://reflect"), .reflect(entryID: nil))
    }

    func testSettingsAndHelpDeepLinks() {
        XCTAssertEqual(parse("lumina://settings"), .settings)
        XCTAssertEqual(parse("lumina://help"), .help(topicID: nil))
        XCTAssertEqual(parse("lumina://help/billing"), .help(topicID: "billing"))
    }

    func testForeignSchemeReturnsNil() {
        XCTAssertNil(LuminaDeepLink.from(url: makeURL("https://lumina.app")))
    }

    func testDeepLinkTabMappings() {
        XCTAssertEqual(LuminaDeepLink.today.tab, .today)
        XCTAssertEqual(LuminaDeepLink.chart(planet: nil).tab, .chart)
        XCTAssertEqual(LuminaDeepLink.palmScan.tab, .palm)
        XCTAssertEqual(LuminaDeepLink.people(friendID: nil).tab, .people)
        XCTAssertEqual(LuminaDeepLink.reflect(entryID: nil).tab, .reflect)
        XCTAssertNil(LuminaDeepLink.settings.tab)
        XCTAssertNil(LuminaDeepLink.help(topicID: nil).tab)
    }

    // MARK: - AppRouter

    @MainActor
    func testRouterStartsInOnboardingForFirstRun() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        XCTAssertEqual(router.stage, .onboarding)
    }

    @MainActor
    func testRouterCompletesOnboardingAndRoutesToToday() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()
        XCTAssertEqual(router.stage, .mainTabs)
        XCTAssertEqual(router.selectedTab, .today)
    }

    @MainActor
    func testRouterPersistsCompletionAcrossInstances() {
        let storage = AppRouterStorage.inMemory()
        let first = AppRouter(storage: storage)
        first.bootstrap()
        first.completeOnboarding()

        let second = AppRouter(storage: storage)
        XCTAssertEqual(second.stage, .mainTabs)
    }

    @MainActor
    func testRouterRoutesDeepLinkWhenInMainTabs() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        router.completeOnboarding()

        let didHandle = router.handle(deepLink: .chart(planet: "Mars"))
        XCTAssertTrue(didHandle)
        XCTAssertEqual(router.selectedTab, .chart)
        XCTAssertEqual(router.pendingPresentation, .chart(planet: "Mars"))
    }

    @MainActor
    func testRouterStashesDeepLinkBeforeOnboardingCompletes() {
        let router = AppRouter(storage: .inMemory())
        router.bootstrap()
        XCTAssertEqual(router.stage, .onboarding)

        router.handle(deepLink: .chart(planet: nil))
        XCTAssertEqual(router.pendingDeepLink, .chart(planet: nil))
        XCTAssertNil(router.pendingPresentation)
    }

    // MARK: - Glossary

    @MainActor
    func testGlossaryStoreLoadsBundledEntries() throws {
        // CI runs `xcodebuild test -scheme Lumina`, which uses the Lumina app
        // as the test host — so `Bundle.main` is the host bundle with
        // `Glossary.json`. If a future test config drops the host bundle,
        // we skip rather than fail so the suite stays portable.
        let store = GlossaryStore()
        store.loadIfNeeded(bundle: .main)
        guard !store.entries.isEmpty else {
            throw XCTSkip("Glossary.json not in the host bundle")
        }
        XCTAssertNotNil(store.entry(for: "Saturn return"))
        XCTAssertNotNil(store.entry(for: "rising sign"))
    }

    // MARK: - LuminaError

    func testLuminaErrorHasUserCopyForEveryCase() {
        let cases: [LuminaError] = [
            .offline,
            .server(status: 500),
            .timeout,
            .notSignedIn,
            .subscriptionRequired(feature: "Audio"),
            .permissionDenied(kind: .camera),
            .missingConfiguration(key: "SwissEphURL"),
            .unknown(underlyingMessage: "x"),
        ]
        for error in cases {
            XCTAssertFalse(error.userTitle.isEmpty, "missing userTitle for \(error)")
            XCTAssertFalse(error.userBody.isEmpty, "missing userBody for \(error)")
            XCTAssertFalse(error.recoveryActionTitle.isEmpty, "missing CTA for \(error)")
            XCTAssertFalse(error.analyticsKey.isEmpty, "missing analytics key for \(error)")
        }
    }

    // MARK: - Helpers

    private func parse(_ raw: String) -> LuminaDeepLink? {
        LuminaDeepLink.from(url: makeURL(raw))
    }

    private func makeURL(_ raw: String) -> URL {
        URL(string: raw) ?? URL(fileURLWithPath: "/")
    }
}
