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
}
