import Foundation

// MARK: - Watch用ローカライズ文字列
// iPhone側のL10nの軽量版。UserDefaultsから同期された言語設定を参照
// 日本語・英語の2言語対応

enum WatchL10n {

    // MARK: - 言語判定ヘルパー

    /// 現在の言語が日本語かどうか
    private static var isJapanese: Bool {
        let lang = UserDefaults.standard.string(forKey: WatchSyncKeys.language) ?? "ja"
        return lang.hasPrefix("ja")
    }

    /// 日英切り替えヘルパー
    private static func loc(_ ja: String, _ en: String) -> String {
        isJapanese ? ja : en
    }

    // MARK: - ナビゲーション・セクション

    /// 最近使った種目
    static var recentExercises: String { loc("最近の種目", "Recent") }

    /// お気に入り
    static var favorites: String { loc("お気に入り", "Favorites") }

    /// すべての種目
    static var allExercises: String { loc("すべての種目", "All Exercises") }

    // MARK: - ワークアウト操作

    /// セット番号（例: "セット 1" / "Set 1"）
    static func set(number: Int) -> String {
        loc("セット \(number)", "Set \(number)")
    }

    /// 記録ボタン
    static var record: String { loc("記録", "Record") }

    /// ワークアウト終了
    static var endWorkout: String { loc("ワークアウト終了", "End Workout") }

    // MARK: - セット入力画面

    /// 前回の記録
    static var previous: String { loc("前回", "Previous") }

    /// レスト（休憩）
    static var rest: String { loc("レスト", "Rest") }

    /// 次のセット
    static var nextSet: String { loc("次のセット", "Next Set") }

    /// 種目を変更
    static var changeExercise: String { loc("種目を変更", "Change Exercise") }

    // MARK: - 単位

    /// キログラム
    static var kg: String { "kg" }

    /// ポンド
    static var lb: String { "lb" }

    /// レップ数
    static var reps: String { loc("回", "reps") }

    /// 現在の重量単位を返す
    static var currentWeightUnit: String {
        let unit = UserDefaults.standard.string(forKey: WatchSyncKeys.weightUnit) ?? "kg"
        return unit == "lb" ? lb : kg
    }

    // MARK: - カテゴリ名

    /// 胸
    static var categoryChest: String { loc("胸", "Chest") }

    /// 背中
    static var categoryBack: String { loc("背中", "Back") }

    /// 肩
    static var categoryShoulders: String { loc("肩", "Shoulders") }

    /// 腕
    static var categoryArms: String { loc("腕", "Arms") }

    /// 体幹
    static var categoryCore: String { loc("体幹", "Core") }

    /// 下半身
    static var categoryLowerBody: String { loc("下半身", "Lower Body") }

    /// カテゴリのJSONキーからローカライズ名に変換
    static func localizedCategory(_ jaKey: String) -> String {
        switch jaKey {
        case "胸": return categoryChest
        case "背中": return categoryBack
        case "肩": return categoryShoulders
        case "腕", "腕（二頭）", "腕（三頭）", "腕（前腕）":
            return categoryArms
        case "体幹": return categoryCore
        case "下半身", "下半身（四頭筋）", "下半身（ハムストリングス）",
             "下半身（臀部）", "下半身（ふくらはぎ）":
            return categoryLowerBody
        case "全身": return loc("全身", "Full Body")
        default: return jaKey
        }
    }

    // MARK: - その他

    /// ワークアウト開始
    static var startWorkout: String { loc("ワークアウト開始", "Start Workout") }

    /// キャンセル
    static var cancel: String { loc("キャンセル", "Cancel") }

    /// 確認
    static var confirm: String { loc("確認", "Confirm") }

    /// 終了確認メッセージ
    static var endWorkoutConfirm: String { loc("ワークアウトを終了しますか？", "End workout?") }

    /// 種目を選択
    static var selectExercise: String { loc("種目を選択", "Select Exercise") }

    /// データなし
    static var noData: String { loc("データなし", "No data") }

    /// セッションなし
    static var noActiveSession: String { loc("セッションなし", "No active session") }

    /// 前回の記録フォーマット（例: "前回: 60.0kg x 10回"）
    static func previousRecord(weight: Double, reps: Int) -> String {
        let unit = currentWeightUnit
        return loc(
            "前回: \(String(format: "%.1f", weight))\(unit) x \(reps)回",
            "Prev: \(String(format: "%.1f", weight))\(unit) x \(reps) reps"
        )
    }

    /// エクササイズ名のローカライズ
    static func exerciseName(nameJA: String, nameEN: String) -> String {
        isJapanese ? nameJA : nameEN
    }

    /// オーバータイム表示
    static var overtime: String { loc("超過", "Over") }
}
