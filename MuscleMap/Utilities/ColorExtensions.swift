import SwiftUI

// MARK: - カラーパレット（バイオモニター × G-SHOCK）

extension Color {
    // 背景
    static let mmBgPrimary = Color(hex: "#121212")
    static let mmBgSecondary = Color(hex: "#1E1E1E")
    static let mmBgCard = Color(hex: "#2A2A2A")

    // テキスト
    static let mmTextPrimary = Color.white
    static let mmTextSecondary = Color(hex: "#9E9E9E")

    // アクセント
    static let mmAccentPrimary = Color(hex: "#00FFB3")    // バイオグリーン
    static let mmAccentSecondary = Color(hex: "#00D4FF")  // 電光ブルー

    // 筋肉状態（バイオルミネッセンス6段階）
    static let mmMuscleJustWorked = Color(hex: "#E94560")  // 深紅（回復0-10%）
    static let mmMuscleCoral = Color(hex: "#F4845F")       // コーラル（10-30%）
    static let mmMuscleAmber = Color(hex: "#F4A261")       // アンバー（30-50%）
    static let mmMuscleMint = Color(hex: "#7EC8A0")        // ミント（50-70%）
    static let mmMuscleBioGreen = Color(hex: "#00FFB3")    // バイオグリーン（70-99%）
    static let mmMuscleNeglected = Color(hex: "#9B59B6")   // 紫（7日+未刺激）
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
