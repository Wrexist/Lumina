@testable import Lumina
import XCTest

/// Tests for the transit-tied Reflect prompt: the strongest-transit selection,
/// the tone mapping, and the generator's transit-aware fallback to the date
/// pool. All pure — no backend.
final class TransitPromptTests: XCTestCase {
    func testStrongestPrefersTheTightestApplyingContact() {
        // Input tightest-first: a tighter *separating* trine, then an applying
        // square. The applying one wins even though it's looser.
        let transits = [
            transit("Moon", .trine, "Sun", orb: 0.5, applying: false),
            transit("Mars", .square, "Venus", orb: 1.0, applying: true),
        ]
        XCTAssertEqual(TransitPrompt.strongest(in: transits)?.natal, "Venus")
    }

    func testStrongestFallsBackToTightestWhenNoneApplying() {
        let transits = [
            transit("Moon", .trine, "Sun", orb: 0.5, applying: false),
            transit("Mars", .square, "Venus", orb: 1.0, applying: false),
        ]
        XCTAssertEqual(TransitPrompt.strongest(in: transits)?.natal, "Sun")
    }

    func testStrongestIsNilForNoTransits() {
        XCTAssertNil(TransitPrompt.strongest(in: []))
    }

    func testPromptToneVariesByAspect() {
        let flowing = TransitPrompt.prompt(for: transit("Jupiter", .trine, "Venus"))
        let frictional = TransitPrompt.prompt(for: transit("Saturn", .square, "Venus"))
        let charged = TransitPrompt.prompt(for: transit("Sun", .conjunction, "Venus"))
        XCTAssertTrue(flowing.contains("ease"))
        XCTAssertTrue(frictional.contains("pressing"))
        XCTAssertTrue(charged.contains("charge"))
        // All three key on the natal planet's life area.
        for text in [flowing, frictional, charged] {
            XCTAssertTrue(text.contains("your relationships and values"))
        }
    }

    func testPromptFallsBackForAnUnmappedNatalPoint() {
        let text = TransitPrompt.prompt(for: transit("Mars", .square, "Chiron"))
        XCTAssertTrue(text.contains("something in you"))
    }

    func testKeyEncodesTheTransitTriple() {
        XCTAssertEqual(TransitPrompt.key(for: transit("Mars", .square, "Venus")), "transit:Mars-square-Venus")
    }

    func testGeneratorUsesTheTransitPromptWhenPresent() {
        let top = transit("Mars", .square, "Venus")
        XCTAssertEqual(
            JournalPromptGenerator.shared.prompt(forTransits: [top], on: .now),
            TransitPrompt.prompt(for: top)
        )
    }

    func testGeneratorFallsBackToTheDatePoolWhenNoTransits() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(
            JournalPromptGenerator.shared.prompt(forTransits: [], on: date),
            JournalPromptGenerator.shared.prompt(for: date)
        )
        XCTAssertEqual(
            JournalPromptGenerator.shared.transitKey(forTransits: [], on: date),
            JournalPromptGenerator.shared.transitKey(for: date)
        )
    }

    // MARK: - Helpers

    private func transit(
        _ transiting: String,
        _ type: AspectType,
        _ natal: String,
        orb: Double = 1,
        applying: Bool = true
    ) -> TransitReading {
        TransitReading(transiting: transiting, natal: natal, type: type, exactAngle: 0, orb: orb, applying: applying)
    }
}
