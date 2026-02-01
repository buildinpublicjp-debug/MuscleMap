import Foundation

// MARK: - アプリ全体の状態管理

@MainActor
@Observable
class AppState {
    static let shared = AppState()

    // オンボーディング完了フラグ
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // ユーザー設定
    var isHapticEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isHapticEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isHapticEnabled") }
    }

    var isNotificationEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isNotificationEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isNotificationEnabled") }
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
