import Foundation

// MARK: - 重量単位

enum WeightUnit: String, CaseIterable {
    case kg = "kg"
    case lb = "lb"

    var displayName: String {
        switch self {
        case .kg: return "kg"
        case .lb: return "lb"
        }
    }

    /// kg値を現在の単位に変換
    func convert(fromKg kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lb: return kg * 2.20462
        }
    }

    /// 現在の単位からkg値に変換
    func convertToKg(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lb: return value / 2.20462
        }
    }

    /// フォーマット済み文字列（例: "60 kg" or "132 lb"）
    func formatted(_ kg: Double) -> String {
        let value = convert(fromKg: kg)
        if value == floor(value) {
            return "\(Int(value)) \(displayName)"
        } else {
            return String(format: "%.1f %@", value, displayName)
        }
    }
}

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

    // 重量単位設定（kg/lb）- 言語に基づくデフォルト
    var weightUnit: WeightUnit = {
        // ユーザーが明示的に設定済みの場合はその値を使用
        if let rawValue = UserDefaults.standard.string(forKey: "weightUnit"),
           let unit = WeightUnit(rawValue: rawValue) {
            return unit
        }
        // 未設定の場合は言語に基づいてデフォルトを決定
        // 日本語 → kg、英語 → lb
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        return preferredLanguage.hasPrefix("ja") ? .kg : .lb
    }() {
        didSet { UserDefaults.standard.set(weightUnit.rawValue, forKey: "weightUnit") }
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

    // タブ選択（クロスビュー遷移用、永続化不要）
    var selectedTab: Int = 0

    // 初回ワークアウト完了フラグ
    var hasCompletedFirstWorkout: Bool = UserDefaults.standard.bool(forKey: "hasCompletedFirstWorkout") {
        didSet { UserDefaults.standard.set(hasCompletedFirstWorkout, forKey: "hasCompletedFirstWorkout") }
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
