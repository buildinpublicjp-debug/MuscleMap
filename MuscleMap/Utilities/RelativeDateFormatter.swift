import Foundation

// MARK: - 相対日付フォーマット
// 種目詳細画面の「過去のあなた」セクション等で使う。

/// 「今日 / 昨日 / N日前 / 約N週間前 / 約Nヶ月前」のローカライズ済み相対日付。
@MainActor
enum RelativeDate {
    /// `date` を `now` に対する相対日付文字列に変換する。
    /// 日数差は両方の日付を startOfDay に正規化してから .day 差分を取る (時刻差の影響を受けない)。
    static func string(from date: Date, to now: Date = Date()) -> String {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        let startOfNow = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0

        if days <= 0 {
            return today
        }
        if days == 1 {
            return yesterday
        }
        if days <= 7 {
            return nDaysAgo(days)
        }
        if days <= 14 {
            return nWeeksAgo(1)
        }
        if days <= 21 {
            return nWeeksAgo(2)
        }
        if days <= 30 {
            return nWeeksAgo(3)
        }
        if days <= 60 {
            return nMonthsAgo(1)
        }
        if days <= 90 {
            return nMonthsAgo(2)
        }
        let months = days / 30
        return nMonthsAgo(months)
    }

    // MARK: - L10n ヘルパー (LocalizationManager 経由で日英切替)

    private static var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private static var today: String {
        isJapanese ? "今日" : "today"
    }

    private static var yesterday: String {
        isJapanese ? "昨日" : "yesterday"
    }

    private static func nDaysAgo(_ n: Int) -> String {
        isJapanese ? "\(n)日前" : "\(n) days ago"
    }

    private static func nWeeksAgo(_ n: Int) -> String {
        if isJapanese {
            return "約\(n)週間前"
        }
        return n == 1 ? "about 1 week ago" : "about \(n) weeks ago"
    }

    private static func nMonthsAgo(_ n: Int) -> String {
        if isJapanese {
            return "約\(n)ヶ月前"
        }
        return n == 1 ? "about 1 month ago" : "about \(n) months ago"
    }
}
