@testable import Lumina
import XCTest

/// Tests for the (pure) transit-notification planner: it must stay kind and
/// quiet — skip the Moon, drop past slots, cap the count, and deliver at a
/// humane hour with honest copy.
final class TransitNotificationPlannerTests: XCTestCase {
    func testPlanSkipsMoonAndPastAndKeepsUpcoming() {
        let now = date("2026-06-05T12:00:00Z")
        let forecast = ForecastResult(
            calculatedAt: now,
            from: now,
            days: 30,
            events: [
                event("Mars", .trine, "Venus", at: date("2026-06-10T15:00:00Z")),       // kept
                event("Moon", .square, "Sun", at: date("2026-06-11T15:00:00Z")),        // skip: Moon
                event("Saturn", .square, "Sun", at: date("2026-06-01T10:00:00Z")),      // skip: past
                event("Sun", .conjunction, "Mercury", at: date("2026-06-05T15:00:00Z")), // skip: 9am slot passed
                event("Jupiter", .sextile, "Mars", at: date("2026-06-20T08:00:00Z")),   // kept
            ]
        )
        let planned = TransitNotificationPlanner.plan(from: forecast, now: now, calendar: utc())
        XCTAssertEqual(planned.count, 2)
        XCTAssertEqual(planned.first?.title, "Mars trine your Venus")
        XCTAssertTrue(planned.first?.body.contains("easeful") == true)
    }

    func testPlanDeliversAtNineAMOnTheTransitDay() {
        let now = date("2026-06-05T00:00:00Z")
        let forecast = ForecastResult(
            calculatedAt: now,
            from: now,
            days: 30,
            events: [event("Mars", .trine, "Venus", at: date("2026-06-10T15:00:00Z"))]
        )
        let components = TransitNotificationPlanner.plan(from: forecast, now: now, calendar: utc()).first?.fireDateComponents
        XCTAssertEqual(components?.hour, 9)
        XCTAssertEqual(components?.minute, 0)
        XCTAssertEqual(components?.day, 10)
        XCTAssertEqual(components?.month, 6)
    }

    func testPlanCapsAtTheLimit() {
        let now = date("2026-06-05T00:00:00Z")
        let events = (6...15).map { day in
            event("Mars", .trine, "Venus", at: date(String(format: "2026-06-%02dT15:00:00Z", day)))
        }
        let forecast = ForecastResult(calculatedAt: now, from: now, days: 30, events: events)
        XCTAssertEqual(TransitNotificationPlanner.plan(from: forecast, now: now, limit: 3, calendar: utc()).count, 3)
    }

    func testBodyReflectsAspectTone() {
        let now = date("2026-06-05T00:00:00Z")
        func plannedBody(_ type: AspectType) -> String? {
            let forecast = ForecastResult(
                calculatedAt: now,
                from: now,
                days: 30,
                events: [event("Saturn", type, "Sun", at: date("2026-06-10T15:00:00Z"))]
            )
            return TransitNotificationPlanner.plan(from: forecast, now: now, calendar: utc()).first?.body
        }
        XCTAssertTrue(plannedBody(.square)?.contains("friction") == true)
        XCTAssertTrue(plannedBody(.conjunction)?.contains("charge") == true)
        XCTAssertTrue(plannedBody(.trine)?.contains("easeful") == true)
    }

    // MARK: - Helpers

    private func event(_ transiting: String, _ type: AspectType, _ natal: String, at: Date) -> ForecastEvent {
        ForecastEvent(transiting: transiting, natal: natal, type: type, exactAngle: 0, exactAt: at)
    }

    private func utc() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso) ?? Date(timeIntervalSince1970: 0)
    }
}
