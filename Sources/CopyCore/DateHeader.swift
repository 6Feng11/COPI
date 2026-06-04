import Foundation

public enum DateHeader {
    private static let weekdayNames = [
        "周日",
        "周一",
        "周二",
        "周三",
        "周四",
        "周五",
        "周六"
    ]

    public static func title(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let weekdayName = weekdayNames[max(0, min(weekdayNames.count - 1, weekday - 1))]
        return "\(month)月\(day)日 \(weekdayName)"
    }
}
