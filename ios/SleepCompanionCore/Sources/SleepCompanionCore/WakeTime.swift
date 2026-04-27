import Foundation

public struct WakeTime: Codable, Equatable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(23, max(0, hour))
        self.minute = min(59, max(0, minute))
    }

    public func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var wakeComponents = DateComponents()
        wakeComponents.calendar = calendar
        wakeComponents.timeZone = calendar.timeZone
        wakeComponents.year = components.year
        wakeComponents.month = components.month
        wakeComponents.day = components.day
        wakeComponents.hour = hour
        wakeComponents.minute = minute
        wakeComponents.second = 0

        guard let today = calendar.date(from: wakeComponents) else {
            return nil
        }

        if today > date {
            return today
        }

        return calendar.date(byAdding: .day, value: 1, to: today)
    }
}
