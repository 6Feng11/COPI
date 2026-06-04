import XCTest
@testable import CopyCore

final class WeekdayCalendarTests: XCTestCase {
    func testMapsMondayToOneAndSundayToSeven() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = try XCTUnwrap(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 1
        ).date)
        let sunday = try XCTUnwrap(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 7
        ).date)

        XCTAssertEqual(WeekdayCalendar.currentWeekdayNumber(for: monday, calendar: calendar), 1)
        XCTAssertEqual(WeekdayCalendar.currentWeekdayNumber(for: sunday, calendar: calendar), 7)
    }

    func testDaysSelectsCurrentWeekday() {
        let days = WeekdayCalendar.days(selectedWeekday: 4)

        XCTAssertEqual(days.map(\.number), [1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(days.filter(\.isSelected).map(\.number), [4])
    }
}
