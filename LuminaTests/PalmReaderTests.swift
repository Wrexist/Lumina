@testable import Lumina
import XCTest

/// Tests for the (pure) palmistry engine — the four classical hand types from
/// real geometry, plus the landmark→features math. No Vision, no device.
final class PalmReaderTests: XCTestCase {
    func testSquarePalmShortFingersIsEarth() {
        // width/length = 0.9 (square), fingers/length = 0.8 (short).
        let features = PalmFeatures(palmWidth: 9, palmLength: 10, averageFingerLength: 8)
        XCTAssertEqual(PalmReader.handType(from: features), .earth)
    }

    func testSquarePalmLongFingersIsAir() {
        let features = PalmFeatures(palmWidth: 9, palmLength: 10, averageFingerLength: 10)
        XCTAssertEqual(PalmReader.handType(from: features), .air)
    }

    func testLongPalmShortFingersIsFire() {
        let features = PalmFeatures(palmWidth: 7, palmLength: 10, averageFingerLength: 8)
        XCTAssertEqual(PalmReader.handType(from: features), .fire)
    }

    func testLongPalmLongFingersIsWater() {
        let features = PalmFeatures(palmWidth: 7, palmLength: 10, averageFingerLength: 10)
        XCTAssertEqual(PalmReader.handType(from: features), .water)
    }

    func testDegeneratePalmLengthFallsBackToEarth() {
        let features = PalmFeatures(palmWidth: 0, palmLength: 0, averageFingerLength: 0)
        XCTAssertEqual(PalmReader.handType(from: features), .earth)
    }

    func testReadingIsNonEmptyAndNamesTheElementForEveryType() {
        for type in HandType.allCases {
            XCTAssertFalse(type.reading.isEmpty)
            XCTAssertTrue(type.reading.contains(type.element), "\(type.element) hand reading omits its element")
            XCTAssertEqual(type.title, "\(type.element) hand")
        }
    }

    func testExtractorComputesSpansFromLandmarks() {
        // A simple synthetic hand: bases on the y=10 line, tips 8 above them,
        // wrist at the origin straight below the middle base.
        let landmarks = HandLandmarks(
            wrist: .zero,
            indexMCP: CGPoint(x: -4, y: 10),
            indexTip: CGPoint(x: -4, y: 18),
            middleMCP: CGPoint(x: 0, y: 10),
            middleTip: CGPoint(x: 0, y: 18),
            ringMCP: CGPoint(x: 2, y: 10),
            ringTip: CGPoint(x: 2, y: 18),
            littleMCP: CGPoint(x: 4, y: 10),
            littleTip: CGPoint(x: 4, y: 18)
        )
        let features = PalmFeatureExtractor.features(from: landmarks)
        XCTAssertEqual(features.palmWidth, 8, accuracy: 0.0001)      // -4 → 4
        XCTAssertEqual(features.palmLength, 10, accuracy: 0.0001)    // (0,0) → (0,10)
        XCTAssertEqual(features.averageFingerLength, 8, accuracy: 0.0001)
        // width/length 0.8 (long) + fingers/length 0.8 (short) → Fire.
        XCTAssertEqual(PalmReader.handType(from: features), .fire)
    }
}
