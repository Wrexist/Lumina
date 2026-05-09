@testable import Lumina
import XCTest

/// Phase-2 onboarding state machine tests. Validation rules and resume-on-
/// kill persistence ride CI on every push so a regression to the flow
/// fails the merge.
final class OnboardingTests: XCTestCase {
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
        state.birthPlaceName = "Stockholm"
        state.advance()
        XCTAssertEqual(state.currentStep, .chartReveal)
        state.chartReady = true
        state.advance()
        XCTAssertEqual(state.currentStep, .whatNext)
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
        first.birthPlaceName = "Stockholm"
        first.currentStep = .birthPlace
        first.persist()

        let second = OnboardingState(storage: storage)
        XCTAssertEqual(second.currentStep, .birthPlace)
        XCTAssertEqual(second.motivation, .relationships)
        XCTAssertEqual(second.name, "Anna")
        XCTAssertEqual(second.birthDate, Date(timeIntervalSince1970: 0))
        XCTAssertTrue(second.birthTimeUnknown)
        XCTAssertEqual(second.birthPlaceName, "Stockholm")
    }

    @MainActor
    func testStepTotalCountMatchesEightScreenFlow() {
        XCTAssertEqual(OnboardingState.Step.totalCount, 8)
    }
}
