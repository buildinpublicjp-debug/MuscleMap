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
        LocalizationManager.shared.currentLanguage == .japanese ? displayNameJA : displayNameEN
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
