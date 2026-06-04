import XCTest
@testable import CopyCore

final class DateHeaderTests: XCTestCase {
    func testChineseDateTitleUsesMonthDayAndWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try XCTUnwrap(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 6,
            day: 4
        ).date)

        let title = DateHeader.title(for: date, calendar: calendar)

        XCTAssertEqual(title, "6月4日 周四")
    }
}
