@testable import Lumina
import XCTest

/// Guards the 2026-07 "chart goes stale after a birth-info edit" fix.
/// `BirthChartViewModel.loadIfNeeded()` used to early-return on `.ready`
/// forever, so a Settings edit never refreshed the Chart tab (or the widget)
/// until relaunch. It must now reload whenever the store revision moves,
/// exactly like `TodayViewModel`.
final class BirthChartFreshnessTests: XCTestCase {
    @MainActor
    func testLoadIfNeededReloadsAfterBirthDataChanges() async {
        let suiteName = "BirthChartFreshnessTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("could not create an isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserBirthDataStore(defaults: defaults)
        store.save(Self.sampleBirth)

        // No Swiss-Eph URL is configured in the test host, so the DEBUG
        // sample-chart fallback lands us in `.ready`.
        let viewModel = BirthChartViewModel(store: store)
        await viewModel.loadIfNeeded()
        guard case .ready = viewModel.state else {
            return XCTFail("expected a ready chart, got \(viewModel.state)")
        }

        // A Settings edit that clears birth data bumps the revision. The old
        // code stayed `.ready`; the fix reloads because the revision moved —
        // and now there is no birth data to compute against.
        store.clear()
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .missingBirthData)
    }

    private static let sampleBirth = BirthData(
        birthDate: Date(timeIntervalSince1970: 645_400_000),
        birthTime: Date(timeIntervalSince1970: 645_400_000),
        placeName: "Stockholm, Sweden",
        latitude: 59.3293,
        longitude: 18.0686,
        timeZoneIdentifier: "Europe/Stockholm"
    )
}
