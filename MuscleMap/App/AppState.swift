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

    // アプリバージョン
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private init() {}
}
