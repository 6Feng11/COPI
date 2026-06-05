import XCTest
@testable import CopyCore

final class ClipboardTimeFormatterTests: XCTestCase {
    func testFormatsTimeWithHourMinuteSecond() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try XCTUnwrap(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 4,
            hour: 9,
            minute: 8,
            second: 7
        ).date)

        let time = ClipboardTimeFormatter.timeString(for: date, calendar: calendar)

        XCTAssertEqual(time, "09:08:07")
    }

    func testTimestampDisplayShowsTimeOnlyForToday() throws {
        let calendar = Self.gregorianCalendar
        let now = try Self.date(year: 2026, month: 6, day: 5, hour: 12, minute: 0, second: 0, calendar: calendar)
        let today = try Self.date(year: 2026, month: 6, day: 5, hour: 9, minute: 8, second: 7, calendar: calendar)

        XCTAssertEqual(
            ClipboardTimeFormatter.timestampDisplayString(for: today, now: now, calendar: calendar),
            "09:08:07"
        )
    }

    func testTimestampDisplayShowsYesterdayAndDayBeforeYesterday() throws {
        let calendar = Self.gregorianCalendar
        let now = try Self.date(year: 2026, month: 6, day: 5, hour: 12, minute: 0, second: 0, calendar: calendar)
        let yesterday = try Self.date(year: 2026, month: 6, day: 4, hour: 23, minute: 59, second: 59, calendar: calendar)
        let dayBeforeYesterday = try Self.date(year: 2026, month: 6, day: 3, hour: 0, minute: 0, second: 1, calendar: calendar)

        XCTAssertEqual(
            ClipboardTimeFormatter.timestampDisplayString(for: yesterday, now: now, calendar: calendar),
            "昨天"
        )
        XCTAssertEqual(
            ClipboardTimeFormatter.timestampDisplayString(for: dayBeforeYesterday, now: now, calendar: calendar),
            "前天"
        )
    }

    func testTimestampDisplayShowsDateForOlderItems() throws {
        let calendar = Self.gregorianCalendar
        let now = try Self.date(year: 2026, month: 6, day: 5, hour: 12, minute: 0, second: 0, calendar: calendar)
        let olderSameYear = try Self.date(year: 2026, month: 6, day: 2, hour: 23, minute: 59, second: 59, calendar: calendar)
        let olderPreviousYear = try Self.date(year: 2025, month: 12, day: 31, hour: 23, minute: 59, second: 59, calendar: calendar)

        XCTAssertEqual(
            ClipboardTimeFormatter.timestampDisplayString(for: olderSameYear, now: now, calendar: calendar),
            "6月2日"
        )
        XCTAssertEqual(
            ClipboardTimeFormatter.timestampDisplayString(for: olderPreviousYear, now: now, calendar: calendar),
            "2025年12月31日"
        )
    }

    private static var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        calendar: Calendar
    ) throws -> Date {
        try XCTUnwrap(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        ).date)
    }
}
