import SwiftUI

// MARK: - カラーパレット（バイオモニター × G-SHOCK）ライト/ダーク対応

extension Color {
    // MARK: - 背景（アダプティブ）

    static let mmBgPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#121212")
            : UIColor(hex: "#F5F5F7")
    })

    static let mmBgSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#1E1E1E")
            : UIColor(hex: "#EBEBF0")
    })

    static let mmBgCard = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#2A2A2A")
            : UIColor(hex: "#FFFFFF")
    })

    // MARK: - テキスト（アダプティブ）

    static let mmTextPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(hex: "#1C1C1E")
    })

    static let mmTextSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#B0B0B0")
            : UIColor(hex: "#6C6C70")
    })

    // MARK: - アクセント（Light/Dark共通で視認性十分）

    static let mmAccentPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#00FFB3")    // バイオグリーン
            : UIColor(hex: "#00CC8F")    // 少し暗めのグリーン（白背景用）
    })

    static let mmAccentSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#00D4FF")    // 電光ブルー
            : UIColor(hex: "#00A8CC")    // 少し暗めのブルー（白背景用）
    })

    // MARK: - ブランドカラー

    static let mmBrandPurple = Color(hex: "#A020F0")

    // MARK: - 筋肉状態（3段階に簡素化）— 彩度を抑えた落ち着いたトーン（Light/Dark共通）

    static let mmMuscleFatigued = Color(hex: "#E57373")   // 疲労（0-20%）= 落ち着いたコーラル
    static let mmMuscleModerate = Color(hex: "#FFD54F")   // 中間（20-80%）= 落ち着いたゴールド
    static let mmMuscleRecovered = Color(hex: "#81C784")  // 回復済み（80-100%）= 落ち着いたセージ
    static let mmMuscleInactive = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#3D3D42")
            : UIColor(hex: "#E5E5EA")
    })
    static let mmMuscleNeglected = Color(hex: "#B388D4")  // 紫（7日+未刺激）

    // MARK: - 境界線（アダプティブ）

    static let mmBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#808080")
            : UIColor(hex: "#C7C7CC")
    })

    static let mmMuscleActiveBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(hex: "#1C1C1E")
    })

    // MARK: - 旧名との互換エイリアス

    static let mmMuscleCoral = mmMuscleFatigued
    static let mmMuscleAmber = mmMuscleModerate
    static let mmMuscleYellow = mmMuscleModerate
    static let mmMuscleLime = mmMuscleRecovered
    static let mmMuscleBioGreen = mmMuscleRecovered
    static let mmMuscleBorder = mmBorder
    static let mmMuscleJustWorked = mmMuscleFatigued
}

// MARK: - Color Hex初期化

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
            a = 1.0
        case 8:
            r = Double((int >> 24) & 0xFF) / 255.0
            g = Double((int >> 16) & 0xFF) / 255.0
            b = Double((int >> 8) & 0xFF) / 255.0
            a = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0; a = 1.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - UIColor Hex初期化

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255.0
        let g = CGFloat((int >> 8) & 0xFF) / 255.0
        let b = CGFloat(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - 色補間

extension Color {
    /// 2色間を線形補間
    static func interpolate(from: Color, to: Color, t: Double) -> Color {
        let t = min(1.0, max(0.0, t))
        let fromComponents = from.rgbaComponents
        let toComponents = to.rgbaComponents
        return Color(
            .sRGB,
            red: fromComponents.r + (toComponents.r - fromComponents.r) * t,
            green: fromComponents.g + (toComponents.g - fromComponents.g) * t,
            blue: fromComponents.b + (toComponents.b - fromComponents.b) * t,
            opacity: fromComponents.a + (toComponents.a - fromComponents.a) * t
        )
    }

    /// RGBA成分を取得（iOS 17+）
    var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
