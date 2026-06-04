import Foundation

public struct WeekdayCalendarDay: Equatable, Sendable {
    public let number: Int
    public let isSelected: Bool

    public init(number: Int, isSelected: Bool) {
        self.number = number
        self.isSelected = isSelected
    }
}

public enum WeekdayCalendar {
    public static func days(selectedWeekday: Int) -> [WeekdayCalendarDay] {
        (1...7).map { number in
            WeekdayCalendarDay(number: number, isSelected: number == selectedWeekday)
        }
    }

    public static func currentWeekdayNumber(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let systemWeekday = calendar.component(.weekday, from: date)
        return ((systemWeekday + 5) % 7) + 1
    }
}
