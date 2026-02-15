import Foundation
import SwiftUI

// MARK: - 言語設定

enum AppLanguage: String, CaseIterable, Codable {
    case japanese = "ja"
    case english = "en"

    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

// MARK: - LocalizationManager

@MainActor
@Observable
class LocalizationManager {
    static let shared = LocalizationManager()

    private let languageKey = "appLanguage"
    private let appGroupSuiteName = "group.com.buildinpublic.MuscleMap"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
            // ウィジェット用にApp Groupにも保存
            UserDefaults(suiteName: appGroupSuiteName)?.set(currentLanguage.rawValue, forKey: languageKey)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            self.currentLanguage = preferredLanguage.hasPrefix("ja") ? .japanese : .english
        }
        // ウィジェット用にApp Groupにも同期
        UserDefaults(suiteName: appGroupSuiteName)?.set(currentLanguage.rawValue, forKey: languageKey)
    }

    /// ヘルパー: 言語に応じた文字列を返す
    static func localized(_ ja: String, en: String) -> String {
        shared.currentLanguage == .japanese ? ja : en
    }
}

// MARK: - Notification

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - YouTube検索言語設定

enum YouTubeSearchLanguage: String, CaseIterable, Codable {
    case japanese = "ja"
    case english = "en"
    case auto = "auto"

    @MainActor
    var displayName: String {
        switch self {
        case .japanese: return L10n.searchInJapanese
        case .english: return L10n.searchInEnglish
        case .auto: return L10n.followAppLanguage
        }
    }

    /// 実際の検索言語を解決する
    @MainActor
    func resolvedLanguage() -> String {
        switch self {
        case .japanese: return "ja"
        case .english: return "en"
        case .auto:
            return LocalizationManager.shared.currentLanguage.rawValue
        }
    }
}

// MARK: - YouTube URL生成

@MainActor
struct YouTubeSearchHelper {
    static var searchLanguage: YouTubeSearchLanguage {
        let raw = UserDefaults.standard.string(forKey: "youtubeSearchLanguage") ?? "auto"
        return YouTubeSearchLanguage(rawValue: raw) ?? .auto
    }

    static func searchURL(for exercise: ExerciseDefinition) -> URL? {
        let language = searchLanguage.resolvedLanguage()
        let query: String

        if language == "ja" {
            query = "\(exercise.nameJA) フォーム"
        } else {
            query = "\(exercise.nameEN) form"
        }

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://www.youtube.com/results?search_query=\(encoded)")
    }
}

// MARK: - Localized Strings

/// アプリ全体で使用するローカライズ文字列
@MainActor
enum L10n {
    // ヘルパー関数
    private static func loc(_ ja: String, _ en: String) -> String {
        LocalizationManager.localized(ja, en: en)
    }

    // MARK: - 共通
    static var cancel: String { loc("キャンセル", "Cancel") }
    static var ok: String { loc("OK", "OK") }
    static var close: String { loc("閉じる", "Close") }
    static var delete: String { loc("削除", "Delete") }
    static var save: String { loc("保存", "Save") }
    static var next: String { loc("次へ", "Next") }
    static var start: String { loc("始める", "Start") }
    static var skip: String { loc("スキップ", "Skip") }
    static var done: String { loc("完了", "Done") }
    static var edit: String { loc("編集", "Edit") }
    static var add: String { loc("追加", "Add") }
    static var confirm: String { loc("確認", "Confirm") }
    static var error: String { loc("エラー", "Error") }
    static var noData: String { loc("データなし", "No data") }

    // MARK: - タブ
    static var home: String { loc("ホーム", "Home") }
    static var workout: String { loc("ワークアウト", "Workout") }
    static var exerciseLibrary: String { loc("種目辞典", "Exercise Library") }
    static var history: String { loc("履歴", "History") }
    static var settings: String { loc("設定", "Settings") }

    // MARK: - ホーム画面
    static func dayStreak(_ days: Int) -> String {
        loc("\(days)日連続", "\(days) day streak")
    }
    static func weekStreak(_ weeks: Int) -> String {
        loc("\(weeks)週連続", "\(weeks) week streak")
    }
    static var noWorkoutThisWeek: String { loc("今週まだです", "Not yet this week") }
    static var neglectedMuscles: String { loc("未刺激の部位", "Neglected Muscles") }

    // MARK: - ストリークマイルストーン
    static var milestone1Month: String { loc("1ヶ月継続！", "1 Month Streak!") }
    static var milestone3Months: String { loc("3ヶ月継続！", "3 Months Streak!") }
    static var milestone6Months: String { loc("半年継続！", "6 Months Streak!") }
    static var milestone1Year: String { loc("1年継続！", "1 Year Streak!") }
    static func streakCongrats(_ weeks: Int) -> String {
        loc("\(weeks)週間トレーニングを続けています", "You've been training for \(weeks) weeks")
    }
    static var shareAchievement: String { loc("達成をシェア", "Share Achievement") }
    static func milestoneShareText(_ weeks: Int, _ hashtag: String, _ url: String) -> String {
        loc("\(weeks)週連続でトレーニング継続中！\(hashtag)\n\(url)",
            "\(weeks) weeks of consistent training! \(hashtag)\n\(url)")
    }

    // 凡例
    static var highLoad: String { loc("高負荷", "High Load") }
    static var earlyRecovery: String { loc("回復初期", "Early Recovery") }
    static var midRecovery: String { loc("回復中", "Recovering") }
    static var lateRecovery: String { loc("回復後期", "Late Recovery") }
    static var almostRecovered: String { loc("ほぼ回復", "Almost Recovered") }
    static var notStimulated: String { loc("未刺激", "Not Stimulated") }

    // 筋肉マップ
    static var front: String { loc("前面", "Front") }
    static var back: String { loc("背面", "Back") }
    static var viewBack: String { loc("背面を見る", "View Back") }
    static var viewFront: String { loc("前面を見る", "View Front") }

    // MARK: - ワークアウト画面
    static var todayRecommendation: String { loc("今日のおすすめ", "Today's Recommendation") }
    static var favorites: String { loc("お気に入り", "Favorites") }
    static var favoriteExercises: String { loc("お気に入り種目", "Favorite Exercises") }
    static var startFreeWorkout: String { loc("自由にトレーニング開始", "Start Free Workout") }
    static var tapMuscleHint: String { loc("筋肉をタップして関連種目を選択", "Tap a muscle to select related exercises") }
    static var addExercise: String { loc("種目を追加", "Add Exercise") }
    static var addFirstExercise: String { loc("種目を追加して始める", "Add an Exercise to Start") }
    static var emptyWorkoutTitle: String { loc("ワークアウトを始めましょう", "Let's Start Your Workout") }
    static var emptyWorkoutHint: String { loc("上のボタンから種目を追加して、セットを記録していきましょう", "Add exercises from the button above and start recording your sets") }
    static var endWorkout: String { loc("ワークアウト終了", "End Workout") }
    static var recordSet: String { loc("セットを記録", "Record Set") }
    static var recorded: String { loc("記録済み", "Recorded") }
    static var neglected: String { loc("未刺激", "Neglected") }

    static func setNumber(_ n: Int) -> String {
        loc("セット \(n)", "Set \(n)")
    }
    static func setsReps(_ sets: Int, _ reps: Int) -> String {
        loc("\(sets)セット × \(reps)レップ", "\(sets) sets × \(reps) reps")
    }
    static func previousRecord(_ weight: Double, _ reps: Int) -> String {
        loc("前回: \(String(format: "%.1f", weight))kg × \(reps)回",
            "Previous: \(String(format: "%.1f", weight))kg × \(reps) reps")
    }
    static func previousRepsOnly(_ reps: Int) -> String {
        loc("前回: \(reps)回", "Previous: \(reps) reps")
    }
    static func weightReps(_ weight: Double, _ reps: Int) -> String {
        loc("\(String(format: "%.1f", weight))kg × \(reps)回",
            "\(String(format: "%.1f", weight))kg × \(reps) reps")
    }
    static func repsOnly(_ reps: Int) -> String {
        loc("\(reps)回", "\(reps) reps")
    }

    // 自重・加重
    static var bodyweight: String { loc("自重", "Bodyweight") }
    static var addWeight: String { loc("加重する", "Add Weight") }
    static var kgAdditional: String { loc("kg (加重)", "kg (added)") }
    static var kg: String { loc("kg", "kg") }
    static var reps: String { loc("回", "reps") }

    static func tryHeavier(_ current: Double, _ suggested: Double) -> String {
        loc("前回\(String(format: "%.1f", current))kg → \(String(format: "%.1f", suggested))kgに挑戦？",
            "Try \(String(format: "%.1f", suggested))kg? (was \(String(format: "%.1f", current))kg)")
    }

    // 確認ダイアログ
    static var endWorkoutConfirm: String { loc("ワークアウトを終了しますか？", "End workout?") }
    static var saveAndEnd: String { loc("記録を保存して終了", "Save and End") }
    static var discardAndEnd: String { loc("記録を破棄して終了", "Discard and End") }
    static var deleteSetConfirm: String { loc("このセットを削除しますか？", "Delete this set?") }

    // MARK: - 種目選択・種目辞典
    static var selectExercise: String { loc("種目を選択", "Select Exercise") }
    static var all: String { loc("すべて", "All") }
    static var recent: String { loc("最近", "Recent") }
    static var equipment: String { loc("器具", "Equipment") }
    static var searchExercises: String { loc("種目を検索", "Search exercises") }
    static var noFavorites: String { loc("お気に入りがありません", "No favorites") }
    static var addFavoritesHint: String {
        loc("種目詳細画面の☆ボタンで\nお気に入りに追加できます",
            "Tap the ☆ button in exercise detail\nto add favorites")
    }
    static var noRecentExercises: String { loc("最近使った種目がありません", "No recent exercises") }
    static var recentExercisesHint: String {
        loc("ワークアウトで種目を記録すると\nここに表示されます",
            "Exercises you use in workouts\nwill appear here")
    }
    static func exerciseCountLabel(_ count: Int) -> String {
        loc("\(count)種目", "\(count) exercises")
    }

    // 種目リスト バッジ
    static var recommended: String { loc("おすすめ", "Recommended") }
    static var recovering: String { loc("回復中", "Recovering") }
    static var partiallyRecovering: String { loc("一部回復中", "Partially Recovering") }
    static var restSuggested: String { loc("休息推奨", "Rest Suggested") }

    // MARK: - 種目詳細
    static var description: String { loc("説明", "Description") }
    static var formTips: String { loc("フォームのポイント", "Form Tips") }
    static var watchVideo: String { loc("動画で見る", "Watch Video") }
    static var targetMuscles: String { loc("対象筋肉", "Target Muscles") }
    static var stimulationLevel: String { loc("刺激度", "Stimulation Level") }
    static var highStimulation: String { loc("高 (80%+)", "High (80%+)") }
    static var mediumStimulation: String { loc("中 (50-79%)", "Mid (50-79%)") }
    static var lowStimulation: String { loc("低 (1-49%)", "Low (1-49%)") }

    // MARK: - 履歴・統計画面
    static var weekly: String { loc("週間", "Weekly") }
    static var monthly: String { loc("月間", "Monthly") }
    static var thisWeekSummary: String { loc("今週のサマリー", "This Week's Summary") }
    static var thisMonthSummary: String { loc("今月のサマリー", "This Month's Summary") }
    static var sessions: String { loc("セッション", "Sessions") }
    static var totalSets: String { loc("セット数", "Total Sets") }
    static var totalVolume: String { loc("総ボリューム", "Total Volume") }
    static var trainingDays: String { loc("トレ日数", "Training Days") }
    static var groupCoverage: String { loc("部位カバー率", "Group Coverage") }
    static var dailyVolume14Days: String { loc("日別ボリューム（14日間）", "Daily Volume (14 days)") }
    static var groupSetsThisWeek: String { loc("部位別セット数（今週）", "Sets by Group (This Week)") }
    static var topExercises: String { loc("よく行う種目 Top5", "Top 5 Exercises") }
    static var sessionHistory: String { loc("セッション履歴", "Session History") }
    static var noSessionsYet: String { loc("まだセッションがありません", "No sessions yet") }
    static var inProgress: String { loc("進行中", "In Progress") }
    static func minutes(_ min: Int) -> String { loc("\(min)分", "\(min) min") }
    static var lessThanOneMinute: String { loc("<1分", "<1 min") }
    static var andMore: String { loc("他", "more") }
    static func setsLabel(_ count: Int) -> String { loc("\(count)セット", "\(count) sets") }

    // MARK: - 部位詳細画面
    static var highLoadRestNeeded: String { loc("高負荷 — 休息が必要", "High Load — Rest Needed") }
    static var fullyRecoveredTrainable: String { loc("完全回復 — トレーニング可能", "Fully Recovered — Ready to Train") }
    static var neglected7Days: String { loc("未刺激 — 7日以上", "Not Stimulated — 7+ days") }
    static var neglected14Days: String { loc("未刺激 — 14日以上", "Not Stimulated — 14+ days") }
    static func remainingTime(_ hours: Int, _ mins: Int) -> String {
        if hours >= 24 {
            let days = hours / 24
            let h = hours % 24
            return loc("残り\(days)日\(h)時間", "\(days)d \(h)h remaining")
        }
        return loc("残り\(hours)時間", "\(hours)h remaining")
    }
    static var recoveryComplete: String { loc("回復完了", "Fully Recovered") }
    static var lastStimulation: String { loc("最終刺激", "Last Stimulation") }
    static var setCount: String { loc("セット数", "Set Count") }
    static var estimatedRecovery: String { loc("回復予定", "Est. Recovery") }
    static var basicInfo: String { loc("基本情報", "Basic Info") }
    static var muscleGroup: String { loc("グループ", "Group") }
    static var baseRecovery: String { loc("基準回復", "Base Recovery") }
    static var size: String { loc("サイズ", "Size") }
    static var largeMuscle: String { loc("大筋群", "Large") }
    static var mediumMuscle: String { loc("中筋群", "Medium") }
    static var smallMuscle: String { loc("小筋群", "Small") }
    static var relatedExercises: String { loc("関連種目", "Related Exercises") }
    static var recentRecords: String { loc("直近の記録", "Recent Records") }
    static var noRecord: String { loc("記録なし", "No record") }
    static func lastRecordLabel(_ weight: Double, _ reps: Int) -> String {
        loc("前回: \(String(format: "%.0f", weight))kg × \(reps)",
            "Last: \(String(format: "%.0f", weight))kg × \(reps)")
    }
    static func hoursUnit(_ h: Int) -> String { loc("\(h)時間", "\(h) hours") }

    // MARK: - 設定画面
    static var premium: String { loc("プレミアム", "Premium") }
    static var premiumUnlocked: String { loc("全機能がアンロックされています", "All features unlocked") }
    static var upgradeToPremium: String { loc("Premiumにアップグレード", "Upgrade to Premium") }
    static var unlockAllFeatures: String { loc("全機能をアンロック", "Unlock all features") }
    static var restorePurchases: String { loc("購入を復元", "Restore Purchases") }
    static var restoreResult: String { loc("復元結果", "Restore Result") }
    static var purchaseRestored: String { loc("購入が復元されました。", "Purchase restored.") }
    static var noPurchaseFound: String { loc("復元できる購入が見つかりませんでした。", "No purchase found to restore.") }
    static var appSettings: String { loc("アプリ設定", "App Settings") }
    static var hapticFeedback: String { loc("触覚フィードバック", "Haptic Feedback") }
    static var language: String { loc("言語", "Language") }
    static var weightUnit: String { loc("重量単位", "Weight Unit") }
    static var data: String { loc("データ", "Data") }
    static var csvImport: String { loc("CSVインポート", "CSV Import") }
    static var dataExport: String { loc("データエクスポート", "Data Export") }
    static var comingSoon: String { loc("準備中", "Coming Soon") }
    static var registeredExercises: String { loc("登録種目数", "Registered Exercises") }
    static var trackedMuscles: String { loc("追跡筋肉数", "Tracked Muscles") }
    static func exerciseCount(_ count: Int) -> String {
        loc("\(count)種目", "\(count) exercises")
    }
    static func muscleCount(_ count: Int) -> String {
        loc("\(count)部位", "\(count) muscles")
    }
    static var feedback: String { loc("フィードバック", "Feedback") }
    static var appInfo: String { loc("アプリ情報", "About") }
    static var version: String { loc("バージョン", "Version") }
    static var tagline: String {
        loc("MuscleMap — 筋肉の状態が見える。だから、迷わない。",
            "MuscleMap — See your muscles. Train smarter.")
    }
    static var privacyPolicy: String { loc("プライバシーポリシー", "Privacy Policy") }
    static var termsOfService: String { loc("利用規約", "Terms of Service") }

    // MARK: - オンボーディング
    static var onboardingTitle1: String { loc("筋肉の状態が見える", "See Your Muscle Status") }
    static var onboardingSubtitle1: String {
        loc("21の筋肉の回復状態を\nリアルタイムで可視化",
            "Visualize recovery status of\n21 muscles in real-time")
    }
    static var onboardingDetail1: String {
        loc("トレーニング後の筋肉は色で回復度を表示。\n赤→緑へのグラデーションで一目瞭然。",
            "Post-workout muscles show recovery with colors.\nRed to green gradient at a glance.")
    }
    static var onboardingTitle2: String { loc("迷わないメニュー提案", "Smart Menu Suggestions") }
    static var onboardingSubtitle2: String {
        loc("回復データから\n今日のベストメニューを自動提案",
            "Auto-suggest today's best menu\nfrom recovery data")
    }
    static var onboardingDetail2: String {
        loc("ジムで開いた瞬間にスタートできる。\n未刺激の部位も見逃しません。",
            "Start the moment you open at the gym.\nNever miss neglected muscles.")
    }
    static var onboardingTitle3: String { loc("成長を記録・分析", "Track & Analyze Growth") }
    static var onboardingSubtitle3: String {
        loc("80種目のEMGベース刺激マッピングで\n科学的なトレーニング管理",
            "Scientific training with\nEMG-based mapping for 80 exercises")
    }
    static var onboardingDetail3: String {
        loc("セット数・ボリューム・部位カバー率を\nチャートで確認。",
            "View sets, volume, and coverage\nin charts.")
    }
    static var trainingGoalQuestion: String { loc("トレーニングの目標は？", "What's your training goal?") }
    static var goalSuggestionHint: String { loc("あなたに合ったメニューを提案します", "We'll suggest menus tailored for you") }
    static var aboutYouQuestion: String { loc("あなたについて教えてください", "Tell us about yourself") }
    static var nicknameOptional: String { loc("ニックネーム（任意）", "Nickname (optional)") }
    static var nickname: String { loc("ニックネーム", "Nickname") }
    static var trainingExperience: String { loc("トレーニング経験", "Training Experience") }

    // MARK: - ペイウォール
    static var paywallHeadline: String {
        // 「最大化する。」が単独改行されないよう調整
        loc("科学の力で、\nあなたの努力を最大化する。",
            "Maximize your effort\nwith science.")
    }
    static var paywallFeatureRecovery: String {
        loc("EMGベースの回復予測", "EMG-based recovery prediction")
    }
    static var paywallFeatureWidget: String {
        loc("ホームスクリーンウィジェット", "Home screen widget")
    }
    static var paywallFeatureHistory: String {
        loc("無制限の履歴閲覧", "Unlimited history access")
    }
    static var paywallFeatureExport: String {
        loc("データエクスポート（CSV）", "Data export (CSV)")
    }
    static var planMonthly: String { loc("月額", "Monthly") }
    static var planAnnual: String { loc("年額", "Annual") }
    static var planLifetime: String { loc("買い切り", "Lifetime") }
    static var mostPopular: String { loc("一番人気", "Most Popular") }
    static var startFreeTrial: String {
        loc("7日間無料でProを体験する", "Start 7-Day Free Trial")
    }
    static var cancelAnytime: String {
        loc("いつでもキャンセル可能", "Cancel anytime")
    }
    static var proUpgrade: String {
        loc("MuscleMap Proにアップグレード", "Upgrade to MuscleMap Pro")
    }
    static var proActive: String { loc("Pro ✓", "Pro ✓") }
    static var proFeatureLocked: String {
        loc("Proにアップグレード", "Upgrade to Pro")
    }
    static var monthlyPrice: String { loc("¥480/月", "¥480/mo") }
    static var annualPrice: String { loc("¥3,800/年", "¥3,800/yr") }
    static var lifetimePrice: String { loc("¥7,800", "¥7,800") }
    static var lifetimeLabel: String { loc("生涯アクセス", "Lifetime access") }
    static var annualPerMonth: String { loc("月あたり約¥317", "~¥317/month") }
    static var purchaseError: String { loc("購入エラー", "Purchase Error") }
    static var purchaseErrorMessage: String {
        loc("購入を完了できませんでした。しばらく後にお試しください。",
            "Could not complete purchase. Please try again later.")
    }
    static var muscleMaplPremium: String { loc("MuscleMap Pro", "MuscleMap Pro") }
    static var unlockAndOptimize: String {
        loc("全機能をアンロックして\nトレーニングを最適化",
            "Unlock all features\nand optimize your training")
    }
    static var features: String { loc("機能", "Features") }
    static var free: String { loc("Free", "Free") }
    static var premiumLabel: String { loc("Pro", "Pro") }
    static var monthlyPlan: String { loc("月額", "Monthly") }
    static var annualPlan: String { loc("年額", "Annual") }
    static var lifetimePlan: String { loc("買い切り", "Lifetime") }
    static var recommendedBadge: String { loc("おすすめ", "Recommended") }
    static var perMonthPrice: String { loc("月あたり約¥317", "~¥317/month") }
    static var startMonthlyPlan: String { loc("月額プランで始める", "Start Monthly Plan") }
    static var startAnnualPlan: String { loc("年額プランで始める（おすすめ）", "Start Annual Plan (Recommended)") }
    static var purchaseLifetime: String { loc("買い切りプランで購入", "Purchase Lifetime") }
    static var monthlyTrialNote: String {
        loc("7日間の無料トライアル後、¥480/月で自動更新",
            "7-day free trial, then ¥480/month auto-renews")
    }
    static var annualTrialNote: String {
        loc("7日間の無料トライアル後、¥3,800/年で自動更新",
            "7-day free trial, then ¥3,800/year auto-renews")
    }
    static var manageSubscription: String {
        loc("サブスクリプションを管理", "Manage Subscription")
    }
    static var subscriptionDisclosure: String {
        loc("サブスクリプションは確認後にApple IDアカウントに課金されます。無料トライアル期間終了の24時間前までにキャンセルしない限り、自動的に更新されます。アカウント設定から管理・キャンセルできます。",
            "Payment will be charged to your Apple ID account after confirmation. Subscription automatically renews unless canceled at least 24 hours before the end of the free trial period. You can manage and cancel in Account Settings.")
    }

    // ペイウォール機能名
    static var featureMuscleMap2D: String { loc("筋肉マップ（2D）", "Muscle Map (2D)") }
    static var featureWorkoutRecord: String { loc("ワークアウト記録", "Workout Recording") }
    static var featureRecoveryTracking: String { loc("回復トラッキング", "Recovery Tracking") }
    static var featureMenuSuggestion: String { loc("メニュー提案", "Menu Suggestions") }
    static var featureDetailedStats: String { loc("詳細統計", "Detailed Statistics") }
    static var feature3DView: String { loc("3D筋肉ビュー", "3D Muscle View") }
    static var featureMenuSuggestionPlus: String { loc("メニュー提案+", "Menu Suggestions+") }
    static var featureDataExport: String { loc("データエクスポート", "Data Export") }

    // Pro機能ロック
    static var proFeatureRecovery: String {
        loc("EMG回復計算はPro機能です", "EMG recovery calculation is a Pro feature")
    }
    static var proFeatureWidget: String {
        loc("ウィジェットはPro機能です", "Widgets are a Pro feature")
    }
    static var proFeatureUnlimitedHistory: String {
        loc("30日以上の履歴はPro機能です", "History beyond 30 days is a Pro feature")
    }
    static var proFeatureExport: String {
        loc("データエクスポートはPro機能です", "Data export is a Pro feature")
    }

    // MARK: - 部位名（カテゴリ）
    static var categoryChest: String { loc("胸", "Chest") }
    static var categoryBack: String { loc("背中", "Back") }
    static var categoryShoulders: String { loc("肩", "Shoulders") }
    static var categoryArmsBiceps: String { loc("腕（二頭）", "Arms (Biceps)") }
    static var categoryArmsTriceps: String { loc("腕（三頭）", "Arms (Triceps)") }
    static var categoryLegs: String { loc("脚", "Legs") }
    static var categoryCore: String { loc("腹", "Core") }
    static var categoryArms: String { loc("腕", "Arms") }
    static var categoryLowerBody: String { loc("下半身", "Lower Body") }

    // MARK: - 器具名
    static var equipmentBarbell: String { loc("バーベル", "Barbell") }
    static var equipmentDumbbell: String { loc("ダンベル", "Dumbbell") }
    static var equipmentCable: String { loc("ケーブル", "Cable") }
    static var equipmentMachine: String { loc("マシン", "Machine") }
    static var equipmentBodyweight: String { loc("自重", "Bodyweight") }

    // MARK: - 難易度
    static var difficultyBeginner: String { loc("初級", "Beginner") }
    static var difficultyIntermediate: String { loc("中級", "Intermediate") }
    static var difficultyAdvanced: String { loc("上級", "Advanced") }

    // MARK: - YouTube検索
    static var youtubeSearch: String { loc("YouTube検索", "YouTube Search") }
    static var searchLanguage: String { loc("検索言語", "Search Language") }
    static var followAppLanguage: String { loc("アプリの言語に合わせる", "Follow App Language") }
    static var searchInJapanese: String { loc("日本語で検索", "Search in Japanese") }
    static var searchInEnglish: String { loc("英語で検索", "Search in English") }

    // MARK: - メニュー提案理由
    static var letsStartTraining: String { loc("トレーニングを始めましょう", "Let's start training") }
    static var basedOnRecovery: String { loc("回復状態に基づく提案", "Based on recovery status") }
    static var suggestionReason: String { loc("提案理由", "Why this menu") }
    static var suggestedExercises: String { loc("おすすめ種目", "Suggested Exercises") }
    static func groupMostRecovered(_ groupName: String) -> String {
        loc("\(groupName)が最も回復しています", "\(groupName) is most recovered")
    }
    static func muscleNeglectedDays(_ muscleName: String, _ days: Int) -> String {
        loc("。\(muscleName)は\(days)日以上未刺激です", ". \(muscleName) hasn't been trained for \(days)+ days")
    }

    // MARK: - オンボーディング
    static var getStarted: String { loc("はじめる", "Get Started") }
    static var onboardingTagline1: String { loc("鍛えた筋肉が光る。", "Your trained muscles glow.") }
    static var onboardingTagline2: String { loc("回復状態が一目でわかる。", "See recovery at a glance.") }
    static var selectLanguage: String { loc("言語を選択", "Select Language") }
    // 言語名（ネイティブ表記で固定）
    static var languageJapanese: String { "日本語" }
    static var languageEnglish: String { "English" }

    // MARK: - スプラッシュ画面
    static var splashTagline: String { loc("鍛えた筋肉が光る。", "Your trained muscles glow.") }
    static var splashContinue: String { loc("始める", "Get Started") }

    // MARK: - オンボーディングV2
    static var onboardingV2Title1: String { loc("努力を、可視化する。", "Visualize Your Effort.") }
    static var onboardingV2Subtitle1: String {
        loc("鍛えた筋肉が光る。回復状態が一目でわかる。",
            "See your muscles light up. Track recovery at a glance.")
    }
    static var onboardingGoalQuestion: String { loc("主な目標は何ですか？", "What's your primary goal?") }
    static var goalMuscleGain: String { loc("筋力アップ", "Muscle Gain") }
    static var goalFatLoss: String { loc("脂肪燃焼", "Fat Loss") }
    static var goalHealth: String { loc("健康維持", "Stay Healthy") }
    static var continueButton: String { loc("続ける", "Continue") }
    static var onboardingDemoTitle: String { loc("鍛えた部位が光る", "Trained muscles glow") }
    static var onboardingDemoHint: String { loc("筋肉をタップして体験", "Tap muscles to try it out") }

    // MARK: - 価値体験画面（InteractiveDemoPage）
    static var demoPrimaryTitle: String { loc("昨日トレーニングした部位は？", "Which muscles did you train yesterday?") }
    static var demoSubtitle: String { loc("タップして回復状態を確認", "Tap to check recovery status") }
    static func recoveryTimeRemaining(_ hours: Int) -> String {
        loc("回復まであと\(hours)時間", "\(hours)h until recovery")
    }

    // MARK: - 目標設定画面（PersonalizationPage）
    static var goalPageTitle: String { loc("あなたの目標は？", "What's your goal?") }
    static var goalPageSubtitle: String { loc("最適なトレーニングプランを提案します", "We'll suggest the optimal training plan") }
    static var goalMuscleGrowth: String { loc("筋肥大", "Muscle Growth") }
    static var goalMuscleGrowthDesc: String { loc("筋肉を大きく、強く", "Build bigger, stronger muscles") }
    static var goalStrength: String { loc("筋力向上", "Strength") }
    static var goalStrengthDesc: String { loc("パワーを最大化", "Maximize your power") }
    static var goalRecovery: String { loc("回復の最適化", "Optimize Recovery") }
    static var goalRecoveryDesc: String { loc("オーバートレーニングを防ぐ", "Prevent overtraining") }
    static var goalHealthMaintenance: String { loc("健康維持", "Stay Healthy") }
    static var goalHealthMaintenanceDesc: String { loc("無理なく続ける", "Maintain without strain") }

    static var onboardingFeature1: String { loc("21部位の筋肉を可視化", "Visualize 21 muscle groups") }
    static var onboardingFeature1Sub: String { loc("全身の筋肉をリアルタイムで追跡", "Track your entire body in real-time") }
    static var onboardingFeature2: String { loc("無制限のワークアウト記録", "Unlimited workout tracking") }
    static var onboardingFeature2Sub: String { loc("セット・レップ・重量を簡単記録", "Log sets, reps, and weight easily") }
    static var onboardingFeature3: String { loc("EMGベースの回復計算", "EMG-based recovery calculation") }
    static var onboardingFeature3Sub: String { loc("科学的データで最適なタイミングを提案", "Science-backed training timing") }
    static var termsOfUse: String { loc("利用規約", "Terms of Use") }

    // MARK: - 機能紹介画面（CallToActionPage）
    static var ctaPageTitle: String { loc("MuscleMapでできること", "What MuscleMap Can Do") }
    static var ctaFeature1Title: String { loc("筋肉の可視化", "Muscle Visualization") }
    static var ctaFeature1Desc: String { loc("21部位の回復状態をリアルタイムで確認", "Check recovery status of 21 muscles in real-time") }
    static var ctaFeature2Title: String { loc("スマートな記録", "Smart Logging") }
    static var ctaFeature2Desc: String { loc("数タップで完了するワークアウト記録", "Complete workout logging in just a few taps") }
    static var ctaFeature3Title: String { loc("科学的な回復計算", "Scientific Recovery") }
    static var ctaFeature3Desc: String { loc("EMGデータに基づく最適な休息期間", "Optimal rest periods based on EMG data") }

    // MARK: - 通知許可画面
    static var notificationTitle: String { loc("回復したらお知らせ", "Get Notified When Recovered") }
    static var notificationDescription: String {
        loc("筋肉が回復したタイミングで通知を受け取れます",
            "Receive notifications when your muscles are ready to train again")
    }
    static var allowNotifications: String { loc("通知を許可", "Allow Notifications") }
    static var maybeLater: String { loc("あとで", "Maybe Later") }

    // MARK: - CSVインポート
    static var selectCSVFile: String { loc("CSVファイルを選択", "Select CSV File") }
    static var strongHevyFormat: String { loc("Strong/Hevy形式に対応", "Supports Strong/Hevy format") }
    static var fileSelection: String { loc("ファイル選択", "File Selection") }
    static var workoutCount: String { loc("ワークアウト数", "Workout Count") }
    static var unregisteredExercises: String { loc("未登録の種目", "Unregistered Exercises") }
    static var potentialDuplicates: String { loc("重複の可能性", "Potential Duplicates") }
    static var preview: String { loc("プレビュー", "Preview") }
    static var executeImport: String { loc("インポート実行", "Execute Import") }
    static var importComplete: String { loc("インポート完了", "Import Complete") }
    static var result: String { loc("結果", "Result") }
    static var supportedFormat: String { loc("対応フォーマット", "Supported Format") }
    static var help: String { loc("ヘルプ", "Help") }
    static var noAccessPermission: String { loc("ファイルへのアクセス権限がありません", "No permission to access file") }
    static var noWorkoutDataFound: String {
        loc("ワークアウトデータが見つかりませんでした。フォーマットを確認してください。",
            "No workout data found. Please check the format.")
    }
    static func itemCount(_ count: Int) -> String {
        loc("\(count)件", "\(count) items")
    }
    static func fileReadError(_ detail: String) -> String {
        loc("ファイルの読み込みに失敗: \(detail)", "Failed to read file: \(detail)")
    }
    static func fileSelectionError(_ detail: String) -> String {
        loc("ファイル選択エラー: \(detail)", "File selection error: \(detail)")
    }
    static var csvImportFooter: String {
        loc("Strong、HevyなどのアプリからエクスポートしたCSVに対応",
            "Supports CSV exported from apps like Strong, Hevy, etc.")
    }

    // MARK: - ワークアウト完了画面
    static var workoutComplete: String { loc("ワークアウト完了！", "Workout Complete!") }
    static var share: String { loc("シェア", "Share") }
    static var shareTagline: String { loc("筋肉の回復を可視化", "Visualize muscle recovery") }
    static var shareTo: String { loc("シェア先を選択", "Share to") }
    static var shareToInstagramStories: String { loc("Instagram Storiesにシェア", "Share to Instagram Stories") }
    static var shareToOtherApps: String { loc("その他のアプリにシェア", "Share to other apps") }
    static var downloadApp: String { loc("アプリをダウンロード →", "Download the app →") }
    static var todaysWorkout: String { loc("今日のワークアウト", "Today's Workout") }
    static var exercises: String { loc("種目", "Exercises") }
    static var sets: String { loc("セット", "Sets") }
    static var time: String { loc("時間", "Time") }
    static var stimulatedMuscles: String { loc("刺激した筋肉", "Stimulated Muscles") }
    static var exercisesDone: String { loc("実施した種目", "Exercises Done") }
    static var pr: String { loc("PR", "PR") }
    static var volume: String { loc("ボリューム", "Volume") }
    static func andMoreCount(_ count: Int) -> String {
        loc("他\(count)種目", "+\(count) more")
    }

    // MARK: - 追加カテゴリ・器具
    static var categoryArmsForearms: String { loc("腕（前腕）", "Arms (Forearms)") }
    static var categoryFullBody: String { loc("全身", "Full Body") }
    static var equipmentKettlebell: String { loc("ケトルベル", "Kettlebell") }
    static var equipmentTool: String { loc("器具", "Equipment") }

    // MARK: - 翻訳ヘルパー（JSON日本語キー → ローカライズ表示）

    /// カテゴリ名を翻訳
    static func localizedCategory(_ jaKey: String) -> String {
        switch jaKey {
        case "胸": return categoryChest
        case "背中": return categoryBack
        case "肩": return categoryShoulders
        case "腕（二頭）": return categoryArmsBiceps
        case "腕（三頭）": return categoryArmsTriceps
        case "腕（前腕）": return categoryArmsForearms
        case "腕": return categoryArms
        case "体幹": return categoryCore
        case "下半身（四頭筋）": return loc("下半身（四頭筋）", "Legs (Quads)")
        case "下半身（ハムストリングス）": return loc("下半身（ハムストリングス）", "Legs (Hamstrings)")
        case "下半身（臀部）": return loc("下半身（臀部）", "Legs (Glutes)")
        case "下半身（ふくらはぎ）": return loc("下半身（ふくらはぎ）", "Legs (Calves)")
        case "下半身": return categoryLowerBody
        case "全身": return categoryFullBody
        default: return jaKey
        }
    }

    /// 器具名を翻訳
    static func localizedEquipment(_ jaKey: String) -> String {
        switch jaKey {
        case "バーベル": return equipmentBarbell
        case "ダンベル": return equipmentDumbbell
        case "ケーブル": return equipmentCable
        case "マシン": return equipmentMachine
        case "自重": return equipmentBodyweight
        case "ケトルベル": return equipmentKettlebell
        case "器具": return equipmentTool
        default: return jaKey
        }
    }

    /// 難易度を翻訳
    static func localizedDifficulty(_ jaKey: String) -> String {
        switch jaKey {
        case "初級": return difficultyBeginner
        case "中級": return difficultyIntermediate
        case "上級": return difficultyAdvanced
        default: return jaKey
        }
    }

    // MARK: - 全身制覇アチーブメント
    static var fullBodyConquestTitle: String { loc("全身制覇達成！", "Full Body Conquered!") }
    static var fullBodyConquestSubtitle: String { loc("全21部位を刺激しました", "All 21 muscles stimulated") }
    static var allMusclesStimulated: String { loc("全21部位を刺激中", "All 21 muscles active") }
    static var fullBodyConquestAchieved: String { loc("全身制覇達成", "Full Body Conquered") }
    static func fullBodyConquestShareText(_ hashtag: String, _ url: String) -> String {
        loc("全21部位を刺激して全身制覇達成！\(hashtag)\n\(url)",
            "Full body conquered! All 21 muscles stimulated! \(hashtag)\n\(url)")
    }
    static var fullBodyConquestAgain: String { loc("再び全身制覇！", "Full Body Again!") }
    static func conquestCount(_ count: Int) -> String {
        loc("累計\(count)回達成", "\(count) times achieved")
    }

    // MARK: - 週間サマリー
    static var weeklySummary: String { loc("週間サマリー", "Weekly Summary") }
    static var weeklyReport: String { loc("WEEKLY REPORT", "WEEKLY REPORT") }
    static var workouts: String { loc("ワークアウト", "Workouts") }
    static var volumeKg: String { loc("ボリューム(kg)", "Volume (kg)") }
    static var mvpMuscle: String { loc("今週のMVP", "This Week's MVP") }
    static func stimulatedTimes(_ count: Int) -> String {
        loc("\(count)回刺激", "\(count) times stimulated")
    }
    static var noWorkoutThisWeekYet: String { loc("今週はまだワークアウトなし", "No workouts this week yet") }
    static var lazyMuscle: String { loc("来週の宿題", "Next Week's Homework") }
    static var noLazyMuscles: String { loc("サボりなし！", "No slacking!") }
    static var nextWeekHomework: String { loc("来週こそ鍛えよう", "Train these next week") }
    static var currentStreak: String { loc("継続記録", "Current Streak") }
    static var noStreakYet: String { loc("まだ記録なし", "No streak yet") }
    static var noSlacking: String { loc("完璧！", "Perfect!") }
    static var homework: String { loc("宿題", "Homework") }
    static var weeksStreak: String { loc("週連続", "weeks") }
    static func weeklySummaryShareText(_ range: String, _ hashtag: String, _ url: String) -> String {
        loc("今週のトレーニング結果 \(range)\n\(hashtag)\n\(url)",
            "This week's training results \(range)\n\(hashtag)\n\(url)")
    }

    // MARK: - 筋肉バランス診断
    static var muscleBalanceDiagnosis: String { loc("筋肉バランス診断", "Muscle Balance Diagnosis") }
    static var diagnosisCardSubtitle: String { loc("あなたのトレーニングタイプを分析", "Analyze your training type") }
    static var diagnosisDescription: String {
        loc("過去のワークアウトデータを分析し、あなたのトレーニングタイプと筋肉バランスを診断します",
            "Analyze your workout history to diagnose your training type and muscle balance")
    }
    static var startDiagnosis: String { loc("診断を開始", "Start Diagnosis") }
    static var analyzing: String { loc("分析中...", "Analyzing...") }
    static var analyzingSubtitle: String { loc("ワークアウト履歴を解析しています", "Processing your workout history") }
    static var diagnosisResult: String { loc("診断結果", "Diagnosis Result") }
    static var balanceAnalysis: String { loc("バランス分析", "Balance Analysis") }
    static var improvementAdvice: String { loc("改善アドバイス", "Improvement Advice") }
    static var shareResult: String { loc("結果をシェア", "Share Result") }
    static var retryDiagnosis: String { loc("もう一度診断する", "Run Again") }
    static var needMoreData: String { loc("より正確な診断のため、あと少しトレーニングデータが必要です", "More workout data needed for accurate diagnosis") }
    static var currentSessions: String { loc("現在のセッション数", "Current Sessions") }
    static var balanced: String { loc("バランス良好", "Balanced") }
    static func sessionsAnalyzed(_ count: Int) -> String {
        loc("\(count)セッション分析", "\(count) sessions analyzed")
    }
    static var sessionsAnalyzed: String { loc("セッション分析済み", "sessions analyzed") }
    static func balanceDiagnosisShareText(_ typeName: String, _ hashtag: String, _ url: String) -> String {
        loc("私のトレーナータイプは「\(typeName)」でした！\(hashtag)\n\(url)",
            "My trainer type is \"\(typeName)\"! \(hashtag)\n\(url)")
    }

    // バランス軸
    static var upperBody: String { loc("上半身", "Upper Body") }
    static var lowerBody: String { loc("下半身", "Lower Body") }
    static var frontSide: String { loc("前面", "Front") }
    static var backSide: String { loc("背面", "Back") }
    static var pushType: String { loc("プッシュ", "Push") }
    static var pullType: String { loc("プル", "Pull") }
    static var coreType: String { loc("体幹", "Core") }
    static var limbType: String { loc("四肢", "Limbs") }

    // トレーナータイプ名
    static var typeMirrorMuscle: String { loc("ミラーマッスル型", "Mirror Muscle Type") }
    static var typeBalanceMaster: String { loc("バランスマスター型", "Balance Master Type") }
    static var typeLegDayNeverSkip: String { loc("レッグデイ・ネバースキップ型", "Leg Day Never Skip Type") }
    static var typeBackAttack: String { loc("バックアタック型", "Back Attack Type") }
    static var typeCoreMaster: String { loc("体幹番長型", "Core Master Type") }
    static var typeArmDayEveryDay: String { loc("アームデイ・エブリデイ型", "Arm Day Every Day Type") }
    static var typePushCrazy: String { loc("プッシュ狂い型", "Push Crazy Type") }
    static var typeFullBodyConqueror: String { loc("全身制覇型", "Full Body Conqueror Type") }
    static var typeDataInsufficient: String { loc("データ不足", "Data Insufficient") }

    // トレーナータイプ説明
    static var descMirrorMuscle: String {
        loc("胸・肩・腕など、鏡に映る筋肉を重点的に鍛えるタイプです",
            "You focus on muscles visible in the mirror: chest, shoulders, and arms")
    }
    static var descBalanceMaster: String {
        loc("全身をバランスよく鍛えられています。理想的なトレーニングです！",
            "You train your entire body in perfect balance. Ideal training!")
    }
    static var descLegDayNeverSkip: String {
        loc("下半身を重点的に鍛えるタイプです。脚の日を欠かしません！",
            "You emphasize lower body training. Never skip leg day!")
    }
    static var descBackAttack: String {
        loc("背中を重点的に鍛えるタイプです。引く動作が得意です",
            "You focus on back training. Great at pulling movements")
    }
    static var descCoreMaster: String {
        loc("体幹を重点的に鍛えるタイプです。安定性を重視しています",
            "You emphasize core training. Stability is your priority")
    }
    static var descArmDayEveryDay: String {
        loc("腕を重点的に鍛えるタイプです。二頭・三頭が大好き！",
            "You focus on arm training. Love those biceps and triceps!")
    }
    static var descPushCrazy: String {
        loc("押す動作を重点的に行うタイプです。プレス系が得意です",
            "You focus on pushing movements. Great at pressing exercises")
    }
    static var descFullBodyConqueror: String {
        loc("全身をまんべんなく高頻度で鍛えています。素晴らしい！",
            "You train your entire body frequently and evenly. Amazing!")
    }
    static var descDataInsufficient: String {
        loc("診断には10セッション以上のデータが必要です",
            "At least 10 sessions needed for diagnosis")
    }

    // トレーナータイプアドバイス
    static var adviceMirrorMuscle: String {
        loc("背中と下半身のトレーニングを増やすと、より バランスの取れた体を作れます。特にデッドリフトやスクワットがおすすめです。",
            "Add more back and leg training for a balanced physique. Deadlifts and squats are highly recommended.")
    }
    static var adviceBalanceMaster: String {
        loc("このまま続けてください！次のステップとして、弱点部位をさらに強化するか、新しい種目に挑戦してみましょう。",
            "Keep it up! Next step: strengthen any weak points or try new exercises.")
    }
    static var adviceLegDayNeverSkip: String {
        loc("素晴らしい下半身の意識です！上半身、特に背中や胸のトレーニングも取り入れると、さらにバランスが良くなります。",
            "Great lower body focus! Add upper body work, especially back and chest, for better balance.")
    }
    static var adviceBackAttack: String {
        loc("背中の発達は素晴らしい！胸やプッシュ系の種目を追加して、前後のバランスを整えましょう。",
            "Great back development! Add chest and push exercises to balance front and back.")
    }
    static var adviceCoreMaster: String {
        loc("体幹の強さは全ての基礎です。四肢（腕・脚）のトレーニングも増やして、パワーを活かしましょう。",
            "Core strength is fundamental. Add more limb training to utilize that power.")
    }
    static var adviceArmDayEveryDay: String {
        loc("腕の成長には大筋群も重要です。胸・背中・脚のコンパウンド種目を増やすと、腕もさらに発達します。",
            "Big muscles help arm growth. Add compound exercises for chest, back, and legs.")
    }
    static var advicePushCrazy: String {
        loc("プル系（引く動作）を増やしましょう。ローイングやプルダウンで背中を鍛えると、姿勢も良くなります。",
            "Add more pulling movements. Rows and pulldowns will improve your posture too.")
    }
    static var adviceFullBodyConqueror: String {
        loc("完璧なバランスです！さらなる成長のために、各部位のボリュームを徐々に増やしていきましょう。",
            "Perfect balance! For more growth, gradually increase volume for each muscle group.")
    }
    static var adviceDataInsufficient: String {
        loc("もう少しトレーニングを記録してから診断をお試しください。毎回のワークアウトを記録することで、より正確な分析が可能になります。",
            "Record more workouts before trying again. Logging every session enables more accurate analysis.")
    }

    // MARK: - マッスル・ジャーニー
    static var muscleJourney: String { loc("マッスル・ジャーニー", "Muscle Journey") }
    static var journeyCardSubtitle: String { loc("過去と現在を比較", "Compare past and present") }
    static var oneMonthAgo: String { loc("1ヶ月前", "1 month ago") }
    static var threeMonthsAgo: String { loc("3ヶ月前", "3 months ago") }
    static var sixMonthsAgo: String { loc("6ヶ月前", "6 months ago") }
    static var oneYearAgo: String { loc("1年前", "1 year ago") }
    static var customDate: String { loc("カスタム", "Custom") }
    static var now: String { loc("現在", "Now") }
    static var selectDate: String { loc("日付を選択", "Select Date") }
    static var changeSummary: String { loc("変化のサマリー", "Change Summary") }
    static var newlyStimulated: String { loc("新たに刺激した部位", "Newly Stimulated") }
    static var mostImproved: String { loc("最も改善した部位", "Most Improved") }
    static var stillNeglected: String { loc("まだ未刺激の部位", "Still Neglected") }
    static func countParts(_ count: Int) -> String {
        loc("\(count)部位", "\(count) parts")
    }
    static var noDataForPeriod: String { loc("この期間のデータがありません", "No data for this period") }
    static var newMuscles: String { loc("新規部位", "New Muscles") }
    static func journeyShareText(_ progress: String, _ hashtag: String, _ url: String) -> String {
        loc("私の筋肉の成長記録！\(progress)\n\(hashtag)\n\(url)",
            "My muscle growth journey! \(progress)\n\(hashtag)\n\(url)")
    }

    // MARK: - 未刺激警告シェア
    static var shareShame: String { loc("恥を晒す 😱", "Share my shame 😱") }
    static var neglectedShareSubtitle: String { loc("サボってます...", "Slacking off...") }
    static func daysNeglected(_ days: Int) -> String {
        loc("\(days)日放置", "\(days) days neglected")
    }
    static func neglectedShareText(_ muscle: String, _ days: Int, _ hashtag: String, _ url: String) -> String {
        loc("\(muscle)を\(days)日間サボってます...誰か叱ってください 😭 \(hashtag)\n\(url)",
            "I've been neglecting my \(muscle) for \(days) days... someone scold me 😭 \(hashtag)\n\(url)")
    }

    // MARK: - トレーニングヒートマップ
    static var trainingHeatmap: String { loc("トレーニングヒートマップ", "Training Heatmap") }
    static var heatmapCardSubtitle: String { loc("GitHubの草のようにトレーニングを可視化", "Visualize training like GitHub contributions") }
    static var less: String { loc("少ない", "Less") }
    static var more: String { loc("多い", "More") }
    static var trainingDaysLabel: String { loc("トレーニング日数", "Training Days") }
    static var days: String { loc("日", "days") }
    static var longestStreak: String { loc("最長連続", "Longest Streak") }
    static var averagePerWeek: String { loc("週平均", "Weekly Average") }
    static var timesPerWeek: String { loc("回/週", "times/week") }
    static func heatmapShareText(_ trainingDays: Int, _ hashtag: String, _ url: String) -> String {
        loc("\(trainingDays)日間トレーニングを積み重ねています！\(hashtag)\n\(url)",
            "I've trained for \(trainingDays) days! \(hashtag)\n\(url)")
    }

    // MARK: - 統計・分析メニュー
    static var analyticsMenu: String { loc("統計・分析", "Analytics") }
    static var viewStats: String { loc("統計を見る", "View Stats") }
    static var weeklySummaryDescription: String { loc("今週のトレーニング成果を確認", "Review this week's training results") }
    static var balanceDiagnosis: String { loc("筋肉バランス診断", "Balance Diagnosis") }
    static var balanceDiagnosisDescription: String { loc("部位ごとの刺激バランスをチェック", "Check stimulation balance by muscle group") }
    static var startFirstWorkout: String { loc("最初のワークアウトを記録しよう！", "Start Your First Workout!") }
    static var startWorkout: String { loc("ワークアウトを開始", "Start Workout") }
    static var firstWorkoutHint: String { loc("トレーニングを記録すると、ここに統計が表示されます", "Record a workout to see your stats here") }

    // MARK: - 種目プレビュー
    static var exerciseInfo: String { loc("種目情報", "Exercise Info") }
    static var primaryTarget: String { loc("メインターゲット", "Primary Target") }
    static var secondaryTarget: String { loc("サブターゲット", "Secondary Target") }
    static var watchFormVideo: String { loc("フォームを動画で確認", "Watch Form Video") }
    static var openInYouTube: String { loc("YouTubeで開く", "Open in YouTube") }
    static var addThisExercise: String { loc("この種目を追加", "Add This Exercise") }
}
