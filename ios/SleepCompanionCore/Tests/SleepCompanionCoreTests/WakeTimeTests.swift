import XCTest
@testable import SleepCompanionCore

final class WakeTimeTests: XCTestCase {
    func testNextOccurrenceUsesSameDayWhenWakeTimeIsInTheFuture() throws {
        let calendar = utcCalendar()
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 24, hour: 22, minute: 15)))
        let wakeTime = WakeTime(hour: 23, minute: 5)

        let occurrence = try XCTUnwrap(wakeTime.nextOccurrence(after: now, calendar: calendar))

        XCTAssertEqual(calendar.component(.day, from: occurrence), 24)
        XCTAssertEqual(calendar.component(.hour, from: occurrence), 23)
        XCTAssertEqual(calendar.component(.minute, from: occurrence), 5)
    }

    func testNextOccurrenceRollsToTomorrowWhenWakeTimeAlreadyPassed() throws {
        let calendar = utcCalendar()
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 24, hour: 23, minute: 15)))
        let wakeTime = WakeTime(hour: 7, minute: 0)

        let occurrence = try XCTUnwrap(wakeTime.nextOccurrence(after: now, calendar: calendar))

        XCTAssertEqual(calendar.component(.day, from: occurrence), 25)
        XCTAssertEqual(calendar.component(.hour, from: occurrence), 7)
        XCTAssertEqual(calendar.component(.minute, from: occurrence), 0)
    }

    func testNextOccurrenceRollsToTomorrowWhenWakeTimeIsExactlyNow() throws {
        let calendar = utcCalendar()
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 4, day: 24, hour: 7, minute: 0)))
        let wakeTime = WakeTime(hour: 7, minute: 0)

        let occurrence = try XCTUnwrap(wakeTime.nextOccurrence(after: now, calendar: calendar))

        XCTAssertEqual(calendar.component(.day, from: occurrence), 25)
        XCTAssertEqual(calendar.component(.hour, from: occurrence), 7)
        XCTAssertEqual(calendar.component(.minute, from: occurrence), 0)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
