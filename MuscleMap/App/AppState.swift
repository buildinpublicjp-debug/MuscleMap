import Foundation

// MARK: - アプリ全体の状態管理

@MainActor
@Observable
class AppState {
    static let shared = AppState()

    // オンボーディング完了フラグ
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    // ユーザー設定
    var isHapticEnabled: Bool = (UserDefaults.standard.object(forKey: "isHapticEnabled") as? Bool) ?? true {
        didSet { UserDefaults.standard.set(isHapticEnabled, forKey: "isHapticEnabled") }
    }

    var isNotificationEnabled: Bool = UserDefaults.standard.bool(forKey: "isNotificationEnabled") {
        didSet { UserDefaults.standard.set(isNotificationEnabled, forKey: "isNotificationEnabled") }
    }

    // ユーザープロフィール
    var userProfile: UserProfile = UserProfile.load() {
        didSet { userProfile.save() }
    }

    // 初回デモアニメーション表示済みフラグ
    var hasSeenDemoAnimation: Bool = UserDefaults.standard.bool(forKey: "hasSeenDemoAnimation") {
        didSet { UserDefaults.standard.set(hasSeenDemoAnimation, forKey: "hasSeenDemoAnimation") }
    }

    // オンボーディング後のPaywall表示済みフラグ（レガシー、現在は初回ワークアウト後に表示）
    var hasSeenPostOnboardingPaywall: Bool = UserDefaults.standard.bool(forKey: "hasSeenPostOnboardingPaywall") {
        didSet { UserDefaults.standard.set(hasSeenPostOnboardingPaywall, forKey: "hasSeenPostOnboardingPaywall") }
    }

    // 初回ワークアウト完了フラグ
    var hasCompletedFirstWorkout: Bool = UserDefaults.standard.bool(forKey: "hasCompletedFirstWorkout") {
        didSet { UserDefaults.standard.set(hasCompletedFirstWorkout, forKey: "hasCompletedFirstWorkout") }
    }

    // 初回ワークアウト後のPaywall表示済みフラグ
    var hasSeenFirstWorkoutPaywall: Bool = UserDefaults.standard.bool(forKey: "hasSeenFirstWorkoutPaywall") {
        didSet { UserDefaults.standard.set(hasSeenFirstWorkoutPaywall, forKey: "hasSeenFirstWorkoutPaywall") }
    }

    // 全身制覇達成フラグ
    var hasAchievedFullBodyConquest: Bool = UserDefaults.standard.bool(forKey: "hasAchievedFullBodyConquest") {
        didSet { UserDefaults.standard.set(hasAchievedFullBodyConquest, forKey: "hasAchievedFullBodyConquest") }
    }

    // 初回全身制覇達成日
    var fullBodyConquestDate: Date? {
        get { UserDefaults.standard.object(forKey: "fullBodyConquestDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "fullBodyConquestDate") }
    }

    // 全身制覇達成回数
    var fullBodyConquestCount: Int = UserDefaults.standard.integer(forKey: "fullBodyConquestCount") {
        didSet { UserDefaults.standard.set(fullBodyConquestCount, forKey: "fullBodyConquestCount") }
    }

    // アプリバージョン
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private init() {}
}
