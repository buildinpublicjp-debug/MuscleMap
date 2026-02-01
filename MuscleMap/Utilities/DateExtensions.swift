import Foundation

// MARK: - Date拡張

extension Date {
    /// 指定時間前のDateを返す
    func hoursAgo(_ hours: Double) -> Date {
        addingTimeInterval(-hours * 3600)
    }

    /// 指定日前のDateを返す
    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
}
