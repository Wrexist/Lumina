import XCTest
@testable import Lumina

final class LuminaTests: XCTestCase {
    func testSpacingTokensAreOnEightPointGrid() {
        XCTAssertEqual(LuminaSpacing.xs, 4)
        XCTAssertEqual(LuminaSpacing.sm, 8)
        XCTAssertEqual(LuminaSpacing.md, 16)
        XCTAssertEqual(LuminaSpacing.lg, 24)
        XCTAssertEqual(LuminaSpacing.xl, 32)
        XCTAssertEqual(LuminaSpacing.xxl, 48)
    }

    func testHouseSystemDefaultIncludesPlacidus() {
        XCTAssertTrue(HouseSystem.allCases.contains(.placidus))
    }

    func testEphemerisServiceStubThrowsNotImplemented() async {
        let service = EphemerisService(infoPlist: [:])
        let birthData = BirthData(
            birthDate: Date(timeIntervalSince1970: 0),
            birthTime: nil,
            placeName: "Stockholm",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
        do {
            _ = try await service.chart(for: birthData)
            XCTFail("expected ServiceError.notImplemented")
        } catch EphemerisService.ServiceError.notImplemented {
            // expected
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }
}
