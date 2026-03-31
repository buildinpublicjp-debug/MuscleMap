import StoreKit
import SwiftUI

/// App Store レビュー要求を管理するマネージャー
/// トリガー条件:
/// 1. ワークアウト完了2回目
/// 2. ホーム画面で筋肉マップを5回タップ
/// 一度表示したら以降は出さない（Appleが年3回まで制限しているが、こちらでも制御）
@MainActor
enum ReviewManager {

    // MARK: - UserDefaults Keys

    private static let completedWorkoutsKey = "reviewManager_completedWorkouts"
    private static let muscleTapCountKey = "reviewManager_muscleTapCount"
    private static let hasRequestedReviewKey = "reviewManager_hasRequestedReview"
    private static let lastReviewRequestDateKey = "reviewManager_lastReviewRequestDate"

    // MARK: - Thresholds

    /// ワークアウト完了何回目でレビューを求めるか
    static let workoutCompletionThreshold = 2
    /// 筋肉マップ何タップでレビューを求めるか
    static let muscleTapThreshold = 5
    /// 最低インターバル（日数）— 同じトリガーで連続表示しない
    private static let minimumDaysBetweenRequests = 90

    // MARK: - State

    private static var completedWorkouts: Int {
        get { UserDefaults.standard.integer(forKey: completedWorkoutsKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedWorkoutsKey) }
    }

    private static var muscleTapCount: Int {
        get { UserDefaults.standard.integer(forKey: muscleTapCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: muscleTapCountKey) }
    }

    private static var hasRequestedReview: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedReviewKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedReviewKey) }
    }

    private static var lastReviewRequestDate: Date? {
        get { UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastReviewRequestDateKey) }
    }

    // MARK: - Public API

    /// ワークアウト完了時に呼ぶ。条件を満たせばレビューダイアログを表示。
    static func recordWorkoutCompletion() {
        completedWorkouts += 1
        if completedWorkouts == workoutCompletionThreshold {
            requestReviewIfEligible()
        }
    }

    /// ホーム画面で筋肉マップタップ時に呼ぶ。条件を満たせばレビューダイアログを表示。
    static func recordMuscleTap() {
        muscleTapCount += 1
        if muscleTapCount == muscleTapThreshold {
            requestReviewIfEligible()
        }
    }

    // MARK: - Private

    private static func requestReviewIfEligible() {
        // 既に一度出している & 90日以内ならスキップ
        if hasRequestedReview,
           let lastDate = lastReviewRequestDate,
           Date().timeIntervalSince(lastDate) < Double(minimumDaysBetweenRequests * 86400) {
            return
        }

        // レビュー要求
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        // 少し遅延させて自然なタイミングにする
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            SKStoreReviewController.requestReview(in: scene)
            hasRequestedReview = true
            lastReviewRequestDate = Date()
        }
    }
}
