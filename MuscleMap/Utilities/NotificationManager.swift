import UserNotifications

// MARK: - ローカル通知マネージャー

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    // MARK: - 回復完了リマインダー（筋肉グループ別）

    /// ワークアウト完了時に、刺激した筋肉ごとに回復完了通知をスケジュール
    /// 同時刻（±1時間）の筋肉をグループ化し、最大2通知に制限
    func scheduleRecoveryReminders(
        stimulatedMuscles: [(muscle: Muscle, recoveryDate: Date)],
        nextPartName: String?
    ) {
        let center = UNUserNotificationCenter.current()

        // 既存の回復通知を全削除
        center.removePendingNotificationRequests(withIdentifiers: [
            "recovery_reminder", "recovery_group_0", "recovery_group_1",
        ])

        guard !stimulatedMuscles.isEmpty else { return }

        // 回復時刻順にソートし、±1時間の筋肉をグループ化
        var grouped: [(muscles: [Muscle], date: Date)] = []
        for item in stimulatedMuscles.sorted(by: { $0.recoveryDate < $1.recoveryDate }) {
            if let lastIndex = grouped.indices.last,
               abs(grouped[lastIndex].date.timeIntervalSince(item.recoveryDate)) < 3600 {
                grouped[lastIndex].muscles.append(item.muscle)
            } else {
                grouped.append((muscles: [item.muscle], date: item.recoveryDate))
            }
        }

        // 最大2通知
        for (index, group) in grouped.prefix(2).enumerated() {
            let muscleNames = group.muscles.prefix(3).map {
                isJapanese ? $0.japaneseName : $0.englishName
            }.joined(separator: "・")

            let content = UNMutableNotificationContent()
            content.title = L10n.notifRecoveryComplete(muscleNames)

            if let nextPart = nextPartName {
                content.body = L10n.notifNextPart(nextPart)
            } else {
                content.body = L10n.notifTrainRecoveredMuscles
            }
            content.sound = .default

            let interval = max(group.date.timeIntervalSinceNow, 60)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "recovery_group_\(index)",
                content: content,
                trigger: trigger
            )

            checkPermissionAndSchedule(request)
        }
    }

    /// 後方互換ラッパー（WorkoutCompletionView既存呼び出し用）
    func scheduleRecoveryReminder(nextPartName: String, recoveryDate: Date) {
        // 旧インターフェース: 単一の回復日で1通知
        let content = UNMutableNotificationContent()
        content.title = L10n.notifRecoveryCompleteShort
        content.body = L10n.notifNextPart(nextPartName)
        content.sound = .default

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["recovery_reminder"])

        let interval = max(recoveryDate.timeIntervalSinceNow, 60)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "recovery_reminder",
            content: content,
            trigger: trigger
        )

        checkPermissionAndSchedule(request)
    }

    // MARK: - サボり防止リマインダー

    /// 直近ワークアウトから2日後の朝9時に通知をスケジュール
    func scheduleInactivityReminder(lastWorkoutDate: Date, neglectedMuscleName: String?) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["inactivity_reminder"])

        let twoDaysLater = lastWorkoutDate.addingTimeInterval(2 * 24 * 3600)
        guard twoDaysLater > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.notifTimeToTrain
        if let muscle = neglectedMuscleName {
            content.body = L10n.notifMuscleWaiting(muscle)
        } else {
            content.body = L10n.notifTwoDaysOff
        }
        content.sound = .default

        // 2日後の朝9時
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: twoDaysLater)
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "inactivity_reminder",
            content: content,
            trigger: trigger
        )

        checkPermissionAndSchedule(request)
    }

    // MARK: - 週間サマリー

    /// 毎週月曜朝8時に先週のトレーニング回数を通知
    func scheduleWeeklySummary(workoutCount: Int) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["weekly_summary"])

        let content = UNMutableNotificationContent()
        content.title = L10n.notifWeeklySummary
        content.body = L10n.notifWeeklyBody(workoutCount)
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // 月曜
        dateComponents.hour = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )

        checkPermissionAndSchedule(request)
    }

    // MARK: - 通知許可チェック

    /// 通知許可が付与されている場合のみスケジュール
    private func checkPermissionAndSchedule(_ request: UNNotificationRequest) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            UNUserNotificationCenter.current().add(request)
        }
    }
}
