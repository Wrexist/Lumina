@testable import Lumina
import XCTest

/// Tests for the (pure) parts of the daily reflection reminder: the
/// repeating trigger's date components, the stable-identifier contract, and
/// the userInfo deep link that routes a tap to the Reflect tab — following
/// `TransitNotificationPlannerTests`' pure-logic-only approach (no
/// `UNUserNotificationCenter` involved).
final class ReflectReminderSchedulerTests: XCTestCase {
    func testTriggerComponentsMatchChosenTimeOnly() {
        let components = ReflectReminderScheduler.triggerComponents(hour: 21, minute: 30)
        XCTAssertEqual(components.hour, 21)
        XCTAssertEqual(components.minute, 30)
        // Only hour + minute may be set: any date field (year/month/day)
        // would stop the calendar trigger from repeating daily.
        XCTAssertNil(components.year)
        XCTAssertNil(components.month)
        XCTAssertNil(components.day)
        XCTAssertNil(components.second)
    }

    func testTriggerComponentsFollowTheChosenTime() {
        let components = ReflectReminderScheduler.triggerComponents(hour: 7, minute: 5)
        XCTAssertEqual(components.hour, 7)
        XCTAssertEqual(components.minute, 5)
    }

    @MainActor
    func testIdentifierIsStableAndOutsideTheTransitNamespace() {
        XCTAssertEqual(ReflectReminderScheduler.identifier, "lumina.reflect.reminder")
        // `TransitNotificationScheduler.cancelAll()` removes everything under
        // "lumina.transit." — the reminder must never be swept up by it.
        XCTAssertFalse(ReflectReminderScheduler.identifier.hasPrefix("lumina.transit."))
    }

    @MainActor
    func testUserInfoDeepLinkRoundTripsToTheReflectTab() throws {
        let userInfo: [AnyHashable: Any] = [
            NotificationDeepLink.userInfoKey: NotificationDeepLink.reflect,
        ]
        let url = try XCTUnwrap(NotificationDeepLink.url(from: userInfo))
        let link = LuminaDeepLink.from(url: url)
        XCTAssertEqual(link, .reflect(entryID: nil))
        XCTAssertEqual(link?.tab, .reflect)
    }

    func testUnrelatedUserInfoYieldsNoDeepLink() {
        XCTAssertNil(NotificationDeepLink.url(from: [:]))
        XCTAssertNil(NotificationDeepLink.url(from: ["someOtherKey": "lumina://reflect"]))
    }
}
