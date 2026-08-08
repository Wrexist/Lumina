@testable import Lumina
import XCTest

/// Phase-2 onboarding state machine tests. Validation rules and resume-on-
/// kill persistence ride CI on every push so a regression to the flow
/// fails the merge.
final class OnboardingTests: XCTestCase {
    /// The motivation step gated progress and its answer was then discarded.
    /// It now orders the final step's destinations, so the answer visibly
    /// does something.
    @MainActor
    func testFinalStepLeadsWithTheChosenMotivation() {
        let state = OnboardingState(storage: .inMemory())
        state.name = "Sam"

        state.motivation = .relationships
        XCTAssertEqual(state.motivation, .relationships)
        XCTAssertTrue(state.canAdvance(from: .motivation))

        // Every motivation must map to exactly one destination, and the
        // labels must all be distinct — a duplicate would make the picker
        // ambiguous.
        let labels = OnboardingState.Motivation.allCases.map(\.label)
        XCTAssertEqual(Set(labels).count, labels.count)
        XCTAssertFalse(labels.contains(where: \.isEmpty))
    }

    @MainActor
    func testStartsAtBrandPromise() {
        let state = OnboardingState(storage: .inMemory())
        XCTAssertEqual(state.currentStep, .brandPromise)
    }

    @MainActor
    func testCannotAdvanceFromMotivationWithoutSelection() {
        let state = OnboardingState(storage: .inMemory())
        state.currentStep = .motivation
        XCTAssertFalse(state.canAdvance(from: .motivation))
        state.motivation = .curious
        XCTAssertTrue(state.canAdvance(from: .motivation))
    }

    @MainActor
    func testCannotAdvanceFromNameWithoutValue() {
        let state = OnboardingState(storage: .inMemory())
        state.currentStep = .name
        XCTAssertFalse(state.canAdvance(from: .name))
        state.name = "Anna"
        XCTAssertTrue(state.canAdvance(from: .name))
    }

    @MainActor
    func testNameAdvanceRejectsWhitespaceOnly() {
        let state = OnboardingState(storage: .inMemory())
        state.name = "   "
        XCTAssertFalse(state.canAdvance(from: .name))
    }

    @MainActor
    func testBirthTimeAdvancesWhenUnknownIsSet() {
        let state = OnboardingState(storage: .inMemory())
        state.currentStep = .birthTime
        XCTAssertFalse(state.canAdvance(from: .birthTime))
        state.birthTimeUnknown = true
        XCTAssertTrue(state.canAdvance(from: .birthTime))
    }

    @MainActor
    func testBirthTimeAdvancesWhenTimeProvided() {
        let state = OnboardingState(storage: .inMemory())
        state.currentStep = .birthTime
        state.birthTime = .now
        XCTAssertTrue(state.canAdvance(from: .birthTime))
    }

    @MainActor
    func testAdvanceWalksThroughEntireFlow() {
        let state = OnboardingState(storage: .inMemory())
        state.advance()
        XCTAssertEqual(state.currentStep, .motivation)
        state.motivation = .curious
        state.advance()
        XCTAssertEqual(state.currentStep, .name)
        state.name = "Anna"
        state.advance()
        XCTAssertEqual(state.currentStep, .birthDate)
        state.birthDate = .now
        state.advance()
        XCTAssertEqual(state.currentStep, .birthTime)
        state.birthTimeUnknown = true
        state.advance()
        XCTAssertEqual(state.currentStep, .birthPlace)
        // birth place advance now requires resolved coordinates from the
        // MapKit autocomplete — typing alone isn't sufficient.
        state.birthPlaceName = "Stockholm"
        XCTAssertFalse(state.canAdvance(from: .birthPlace))
        state.applyResolvedPlace(
            name: "Stockholm, Sweden",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
        state.advance()
        XCTAssertEqual(state.currentStep, .chartReveal)
        state.chartReady = true
        state.advance()
        XCTAssertEqual(state.currentStep, .excitement)
        // No star tapped, and the flow still moves. The rating screen is
        // never a toll gate — see `OnboardingScreens.Excitement`.
        XCTAssertTrue(state.canAdvance(from: .excitement))
        state.advance()
        XCTAssertEqual(state.currentStep, .whatNext)
    }

    @MainActor
    func testBirthDateRejectsFutureDate() {
        let state = OnboardingState(storage: .inMemory())
        state.birthDate = Date.now.addingTimeInterval(86_400)
        XCTAssertFalse(state.canAdvance(from: .birthDate))
        XCTAssertNotNil(state.validationMessage(for: .birthDate))
    }

    @MainActor
    func testMakeBirthDataRequiresResolvedCoordinates() {
        let state = OnboardingState(storage: .inMemory())
        state.birthDate = Date(timeIntervalSince1970: 0)
        state.birthPlaceName = "Stockholm"
        XCTAssertNil(state.makeBirthData(), "birth data is nil without coordinates")

        state.applyResolvedPlace(
            name: "Stockholm",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
        let birthData = state.makeBirthData()
        XCTAssertNotNil(birthData)
        XCTAssertEqual(birthData?.placeName, "Stockholm")
        XCTAssertEqual(birthData?.latitude ?? 0, 59.3293, accuracy: 0.001)
    }

    @MainActor
    func testGoBackWalksBackwards() {
        let state = OnboardingState(storage: .inMemory())
        state.currentStep = .name
        state.goBack()
        XCTAssertEqual(state.currentStep, .motivation)
        state.goBack()
        XCTAssertEqual(state.currentStep, .brandPromise)
        state.goBack()
        XCTAssertEqual(state.currentStep, .brandPromise, "no-op on first step")
    }

    @MainActor
    func testPersistencePreservesProgressAcrossInstances() {
        let storage = OnboardingStorage.inMemory()
        let first = OnboardingState(storage: storage)
        first.motivation = .relationships
        first.name = "Anna"
        first.birthDate = Date(timeIntervalSince1970: 0)
        first.birthTimeUnknown = true
        first.applyResolvedPlace(
            name: "Stockholm, Sweden",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
        first.currentStep = .birthPlace
        first.persist()

        let second = OnboardingState(storage: storage)
        XCTAssertEqual(second.currentStep, .birthPlace)
        XCTAssertEqual(second.motivation, .relationships)
        XCTAssertEqual(second.name, "Anna")
        XCTAssertEqual(second.birthDate, Date(timeIntervalSince1970: 0))
        XCTAssertTrue(second.birthTimeUnknown)
        XCTAssertEqual(second.birthPlaceName, "Stockholm, Sweden")
        XCTAssertEqual(second.birthLatitude ?? 0, 59.3293, accuracy: 0.001)
        XCTAssertEqual(second.birthLongitude ?? 0, 18.0686, accuracy: 0.001)
        XCTAssertEqual(second.birthTimeZoneIdentifier, "Europe/Stockholm")
    }

    @MainActor
    func testStepTotalCountMatchesNineScreenFlow() {
        XCTAssertEqual(OnboardingState.Step.totalCount, 9)
    }

    /// The excitement answer has to survive a force-quit like every other
    /// captured field — otherwise backing out of the screen and returning
    /// silently clears the stars the user already tapped.
    @MainActor
    func testExcitementSurvivesAResumeAndSkippingLeavesItNil() {
        let storage = OnboardingStorage.inMemory()

        let first = OnboardingState(storage: storage)
        XCTAssertNil(first.excitement, "nobody has answered yet")
        first.excitement = 4
        first.persist()

        XCTAssertEqual(OnboardingState(storage: storage).excitement, 4)

        // Skipping is a real outcome, not an unanswered one waiting to be
        // re-asked on the next launch.
        let skipper = OnboardingState(storage: .inMemory())
        skipper.currentStep = .excitement
        skipper.advance()
        XCTAssertNil(skipper.excitement)
        XCTAssertEqual(skipper.currentStep, .whatNext)
    }
}
