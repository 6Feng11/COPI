import Foundation

public enum ClipboardTimeFormatter {
    public static func timestampDisplayString(
        for date: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return timeString(for: date, calendar: calendar)
        }

        let startOfDate = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: now)
        let dayDistance = calendar.dateComponents(
            [.day],
            from: startOfDate,
            to: startOfToday
        ).day

        switch dayDistance {
        case 1:
            return "昨天"
        case 2:
            return "前天"
        default:
            let year = calendar.component(.year, from: date)
            let currentYear = calendar.component(.year, from: now)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            if year == currentYear {
                return "\(month)月\(day)日"
            }
            return "\(year)年\(month)月\(day)日"
        }
    }

    public static func timeString(
        for date: Date,
        calendar: Calendar = .current
    ) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        return String(format: "%02d:%02d:%02d", hour, minute, second)
    }
}
