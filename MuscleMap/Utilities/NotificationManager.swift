import UserNotifications

// MARK: - ローカル通知マネージャー

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - 回復完了リマインダー

    /// ワークアウト完了時に、最も遅い回復完了時刻で通知をスケジュール
    func scheduleRecoveryReminder(nextPartName: String, recoveryDate: Date) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["recovery_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "回復完了！"
        content.body = "\(nextPartName)の日です 💪"
        content.sound = .default

        let interval = max(recoveryDate.timeIntervalSinceNow, 60)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "recovery_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - サボり防止リマインダー

    /// 直近ワークアウトから3日後の朝9時に通知をスケジュール
    func scheduleInactivityReminder(lastWorkoutDate: Date, neglectedMuscleName: String?) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["inactivity_reminder"])

        let threeDaysLater = lastWorkoutDate.addingTimeInterval(3 * 24 * 3600)
        guard threeDaysLater > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "トレーニングの時間"
        if let muscle = neglectedMuscleName {
            content.body = "\(muscle)が待ってるぞ 🔥"
        } else {
            content.body = "3日空いたよ。今日やろう 🔥"
        }
        content.sound = .default

        // 3日後の朝9時
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: threeDaysLater)
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "inactivity_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 週間サマリー

    /// 毎週月曜朝8時に先週のトレーニング回数を通知
    func scheduleWeeklySummary(workoutCount: Int) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])

        let content = UNMutableNotificationContent()
        content.title = "週間サマリー"
        content.body = "先週は\(workoutCount)回トレーニング。今週も頑張ろう！"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // 月曜
        dateComponents.hour = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_summary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
