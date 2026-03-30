import SwiftUI

// MARK: - アプリテーマ

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayNameJA: String {
        switch self {
        case .system: return "システム"
        case .light: return "ライト"
        case .dark: return "ダーク"
        }
    }

    var displayNameEN: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    @MainActor
    var displayName: String {
        switch self {
        case .system: return LocalizationManager.localized(ja: "システム", en: "System", zhHans: "系统", ko: "시스템", es: "Sistema", fr: "Système", de: "System")
        case .light: return LocalizationManager.localized(ja: "ライト", en: "Light", zhHans: "浅色", ko: "라이트", es: "Claro", fr: "Clair", de: "Hell")
        case .dark: return LocalizationManager.localized(ja: "ダーク", en: "Dark", zhHans: "深色", ko: "다크", es: "Oscuro", fr: "Sombre", de: "Dunkel")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - テーママネージャー

@Observable
class ThemeManager {
    static let shared = ThemeManager()

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? "dark"
        self.currentTheme = AppTheme(rawValue: saved) ?? .dark
    }
}
