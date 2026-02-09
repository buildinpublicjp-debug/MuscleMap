import SwiftUI

// MARK: - カラーパレット（バイオモニター × G-SHOCK）

extension Color {
    // 背景
    static let mmBgPrimary = Color(hex: "#121212")
    static let mmBgSecondary = Color(hex: "#1E1E1E")
    static let mmBgCard = Color(hex: "#2A2A2A")

    // テキスト（WCAG AA準拠）
    static let mmTextPrimary = Color.white
    static let mmTextSecondary = Color(hex: "#B0B0B0")    // コントラスト比 7.4:1

    // アクセント
    static let mmAccentPrimary = Color(hex: "#00FFB3")    // バイオグリーン
    static let mmAccentSecondary = Color(hex: "#00D4FF")  // 電光ブルー

    // ブランドカラー
    static let mmBrandPurple = Color(hex: "#A020F0")

    // 筋肉状態（3段階に簡素化）
    static let mmMuscleFatigued = Color(hex: "#FF6B6B")   // 疲労（0-20%）= 赤
    static let mmMuscleModerate = Color(hex: "#FFEE58")   // 中間（20-80%）= 黄
    static let mmMuscleRecovered = Color(hex: "#00E676")  // 回復済み（80-100%）= 緑
    static let mmMuscleInactive = Color(hex: "#3D3D42")   // 記録なし/完全回復
    static let mmMuscleNeglected = Color(hex: "#B388D4")  // 紫（7日+未刺激）コントラスト比 5.3:1

    // 境界線（WCAG準拠）
    static let mmBorder = Color(hex: "#808080")           // コントラスト比 4.1:1
    static let mmMuscleActiveBorder = Color(hex: "#FFFFFF")

    // 旧名との互換エイリアス（移行期間中のみ）
    static let mmMuscleCoral = mmMuscleFatigued
    static let mmMuscleAmber = mmMuscleModerate
    static let mmMuscleYellow = mmMuscleModerate
    static let mmMuscleLime = mmMuscleRecovered
    static let mmMuscleBioGreen = mmMuscleRecovered
    static let mmMuscleBorder = mmBorder
    static let mmMuscleJustWorked = mmMuscleFatigued
}

// MARK: - Hex初期化

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
