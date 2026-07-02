@testable import Lumina
import XCTest

/// Privacy regression coverage: the onboarding resume snapshot (name +
/// full birth data) must be removable, and `OnboardingStorage.clear()`
/// must reset the store to the pristine default. `persistAndComplete()`
/// in `OnboardingFlowView` calls it after the birth data reaches
/// `UserBirthDataStore`, which is what makes the Privacy dashboard's
/// "Onboarding state: Cleared" row reachable.
final class OnboardingStorageClearTests: XCTestCase {
    @MainActor
    func testClearRemovesPersistedSnapshot() {
        let storage = OnboardingStorage.inMemory()
        let state = OnboardingState(storage: storage)
        state.name = "Anna"
        state.birthDate = Date(timeIntervalSince1970: 0)
        state.applyResolvedPlace(
            name: "Stockholm, Sweden",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
        state.persist()
        XCTAssertEqual(storage.load().name, "Anna", "precondition: snapshot persisted")

        storage.clear()

        let cleared = storage.load()
        XCTAssertEqual(cleared.currentStep, .brandPromise)
        XCTAssertTrue(cleared.name.isEmpty)
        XCTAssertNil(cleared.birthDate)
        XCTAssertTrue(cleared.birthPlaceName.isEmpty)
        XCTAssertNil(cleared.birthLatitude)
        XCTAssertNil(cleared.birthLongitude)
        XCTAssertNil(cleared.birthTimeZoneIdentifier)
    }

    func testClearOnEmptyStorageIsHarmless() {
        let storage = OnboardingStorage.inMemory()
        storage.clear()
        XCTAssertTrue(storage.load().name.isEmpty)
        XCTAssertEqual(storage.load().currentStep, .brandPromise)
    }

    @MainActor
    func testFreshStateAfterClearStartsOver() {
        let storage = OnboardingStorage.inMemory()
        let first = OnboardingState(storage: storage)
        first.name = "Anna"
        first.currentStep = .birthPlace
        first.persist()
        storage.clear()

        let second = OnboardingState(storage: storage)
        XCTAssertEqual(second.currentStep, .brandPromise)
        XCTAssertTrue(second.name.isEmpty)
    }
}
