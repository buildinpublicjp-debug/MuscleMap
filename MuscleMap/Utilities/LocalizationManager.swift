import Foundation
import SwiftUI

// MARK: - 言語設定

enum AppLanguage: String, CaseIterable, Codable {
    case japanese = "ja"
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"

    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        case .korean: return "한국어"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
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
            self.currentLanguage = Self.detectLanguage(from: preferredLanguage)
        }
        // ウィジェット用にApp Groupにも同期
        UserDefaults(suiteName: appGroupSuiteName)?.set(currentLanguage.rawValue, forKey: languageKey)
    }

    /// システム言語から AppLanguage を検出
    private static func detectLanguage(from preferredLanguage: String) -> AppLanguage {
        if preferredLanguage.hasPrefix("ja") { return .japanese }
        if preferredLanguage.hasPrefix("zh-Hans") || preferredLanguage.hasPrefix("zh_Hans") { return .chineseSimplified }
        if preferredLanguage.hasPrefix("ko") { return .korean }
        if preferredLanguage.hasPrefix("es") { return .spanish }
        if preferredLanguage.hasPrefix("fr") { return .french }
        if preferredLanguage.hasPrefix("de") { return .german }
        return .english
    }

    /// ヘルパー: 言語に応じた文字列を返す（7言語対応）
    static func localized(
        ja: String,
        en: String,
        zhHans: String? = nil,
        ko: String? = nil,
        es: String? = nil,
        fr: String? = nil,
        de: String? = nil
    ) -> String {
        switch shared.currentLanguage {
        case .japanese: return ja
        case .english: return en
        case .chineseSimplified: return zhHans ?? en
        case .korean: return ko ?? en
        case .spanish: return es ?? en
        case .french: return fr ?? en
        case .german: return de ?? en
        }
    }

    /// 旧API互換（日英のみ）
    static func localized(_ ja: String, en: String) -> String {
        localized(ja: ja, en: en)
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
    // ヘルパー関数（7言語対応）
    private static func loc(
        _ ja: String,
        _ en: String,
        zhHans: String? = nil,
        ko: String? = nil,
        es: String? = nil,
        fr: String? = nil,
        de: String? = nil
    ) -> String {
        LocalizationManager.localized(ja: ja, en: en, zhHans: zhHans, ko: ko, es: es, fr: fr, de: de)
    }

    // MARK: - 共通
    static var cancel: String { loc("キャンセル", "Cancel", zhHans: "取消", ko: "취소", es: "Cancelar", fr: "Annuler", de: "Abbrechen") }
    static var ok: String { loc("OK", "OK", zhHans: "确定", ko: "확인", es: "Aceptar", fr: "OK", de: "OK") }
    static var close: String { loc("閉じる", "Close", zhHans: "关闭", ko: "닫기", es: "Cerrar", fr: "Fermer", de: "Schließen") }
    static var delete: String { loc("削除", "Delete", zhHans: "删除", ko: "삭제", es: "Eliminar", fr: "Supprimer", de: "Löschen") }
    static var save: String { loc("保存", "Save", zhHans: "保存", ko: "저장", es: "Guardar", fr: "Enregistrer", de: "Speichern") }
    static var next: String { loc("次へ", "Next", zhHans: "下一步", ko: "다음", es: "Siguiente", fr: "Suivant", de: "Weiter") }
    static var start: String { loc("始める", "Start", zhHans: "开始", ko: "시작", es: "Iniciar", fr: "Commencer", de: "Starten") }
    static var skip: String { loc("スキップ", "Skip", zhHans: "跳过", ko: "건너뛰기", es: "Omitir", fr: "Passer", de: "Überspringen") }
    static var done: String { loc("完了", "Done", zhHans: "完成", ko: "완료", es: "Hecho", fr: "Terminé", de: "Fertig") }
    static var edit: String { loc("編集", "Edit", zhHans: "编辑", ko: "편집", es: "Editar", fr: "Modifier", de: "Bearbeiten") }
    static var editSet: String { loc("セットを編集", "Edit Set", zhHans: "编辑组数", ko: "세트 편집", es: "Editar serie", fr: "Modifier série", de: "Satz bearbeiten") }
    static var add: String { loc("追加", "Add", zhHans: "添加", ko: "추가", es: "Añadir", fr: "Ajouter", de: "Hinzufügen") }
    static var confirm: String { loc("確認", "Confirm", zhHans: "确认", ko: "확인", es: "Confirmar", fr: "Confirmer", de: "Bestätigen") }
    static var error: String { loc("エラー", "Error", zhHans: "错误", ko: "오류", es: "Error", fr: "Erreur", de: "Fehler") }
    static var noData: String { loc("データなし", "No data", zhHans: "无数据", ko: "데이터 없음", es: "Sin datos", fr: "Aucune donnée", de: "Keine Daten") }

    // MARK: - タブ
    static var home: String { loc("ホーム", "Home", zhHans: "首页", ko: "홈", es: "Inicio", fr: "Accueil", de: "Start") }
    static var workout: String { loc("ワークアウト", "Workout", zhHans: "训练", ko: "운동", es: "Entrenamiento", fr: "Entraînement", de: "Training") }
    static var exerciseLibrary: String { loc("種目辞典", "Exercise Library", zhHans: "动作库", ko: "운동 도감", es: "Biblioteca", fr: "Bibliothèque", de: "Übungsbibliothek") }
    static var history: String { loc("履歴", "History", zhHans: "历史", ko: "기록", es: "Historial", fr: "Historique", de: "Verlauf") }
    static var settings: String { loc("設定", "Settings", zhHans: "设置", ko: "설정", es: "Ajustes", fr: "Réglages", de: "Einstellungen") }

    // MARK: - ホーム画面
    static func dayStreak(_ days: Int) -> String {
        loc("\(days)日連続", "\(days) day streak", zhHans: "连续\(days)天", ko: "\(days)일 연속", es: "\(days) días seguidos", fr: "\(days) jours consécutifs", de: "\(days) Tage in Folge")
    }
    static func weekStreak(_ weeks: Int) -> String {
        loc("\(weeks)週連続", "\(weeks) week streak", zhHans: "连续\(weeks)周", ko: "\(weeks)주 연속", es: "\(weeks) semanas seguidas", fr: "\(weeks) semaines consécutives", de: "\(weeks) Wochen in Folge")
    }
    static var noWorkoutThisWeek: String { loc("今週まだです", "Not yet this week", zhHans: "本周还没有", ko: "이번 주 아직", es: "Aún no esta semana", fr: "Pas encore cette semaine", de: "Diese Woche noch nicht") }
    static var neglectedMuscles: String { loc("未刺激の部位", "Neglected Muscles", zhHans: "未锻炼部位", ko: "미자극 부위", es: "Músculos descuidados", fr: "Muscles négligés", de: "Vernachlässigte Muskeln") }

    // MARK: - ストリークマイルストーン
    static var milestone1Month: String { loc("1ヶ月継続！", "1 Month Streak!", zhHans: "坚持1个月！", ko: "1개월 연속!", es: "¡1 mes seguido!", fr: "1 mois consécutif !", de: "1 Monat am Stück!") }
    static var milestone3Months: String { loc("3ヶ月継続！", "3 Months Streak!", zhHans: "坚持3个月！", ko: "3개월 연속!", es: "¡3 meses seguidos!", fr: "3 mois consécutifs !", de: "3 Monate am Stück!") }
    static var milestone6Months: String { loc("半年継続！", "6 Months Streak!", zhHans: "坚持半年！", ko: "6개월 연속!", es: "¡6 meses seguidos!", fr: "6 mois consécutifs !", de: "6 Monate am Stück!") }
    static var milestone1Year: String { loc("1年継続！", "1 Year Streak!", zhHans: "坚持1年！", ko: "1년 연속!", es: "¡1 año seguido!", fr: "1 an consécutif !", de: "1 Jahr am Stück!") }
    static func streakCongrats(_ weeks: Int) -> String {
        loc("\(weeks)週間トレーニングを続けています", "You've been training for \(weeks) weeks", zhHans: "您已连续训练\(weeks)周", ko: "\(weeks)주 동안 훈련을 계속하고 있습니다", es: "Has estado entrenando durante \(weeks) semanas", fr: "Vous vous entraînez depuis \(weeks) semaines", de: "Sie trainieren seit \(weeks) Wochen")
    }
    static var shareAchievement: String { loc("達成をシェア", "Share Achievement", zhHans: "分享成就", ko: "달성 공유", es: "Compartir logro", fr: "Partager la réussite", de: "Erfolg teilen") }
    static func milestoneShareText(_ weeks: Int, _ hashtag: String, _ url: String) -> String {
        loc("\(weeks)週連続でトレーニング継続中！\(hashtag)\n\(url)",
            "\(weeks) weeks of consistent training! \(hashtag)\n\(url)",
            zhHans: "连续训练\(weeks)周！\(hashtag)\n\(url)",
            ko: "\(weeks)주 연속 트레이닝 중! \(hashtag)\n\(url)",
            es: "¡\(weeks) semanas de entrenamiento constante! \(hashtag)\n\(url)",
            fr: "\(weeks) semaines d'entraînement consécutives ! \(hashtag)\n\(url)",
            de: "\(weeks) Wochen durchgehendes Training! \(hashtag)\n\(url)")
    }

    // 凡例
    static var highLoad: String { loc("高負荷", "High Load", zhHans: "高负荷", ko: "고부하", es: "Alta carga", fr: "Charge élevée", de: "Hohe Last") }
    static var earlyRecovery: String { loc("回復初期", "Early Recovery", zhHans: "恢复初期", ko: "회복 초기", es: "Recuperación inicial", fr: "Début de récupération", de: "Frühe Erholung") }
    static var midRecovery: String { loc("回復中", "Recovering", zhHans: "恢复中", ko: "회복 중", es: "Recuperando", fr: "En récupération", de: "Erholend") }
    static var lateRecovery: String { loc("回復後期", "Late Recovery", zhHans: "恢复后期", ko: "회복 후기", es: "Recuperación tardía", fr: "Fin de récupération", de: "Späte Erholung") }
    static var almostRecovered: String { loc("ほぼ回復", "Almost Recovered", zhHans: "接近恢复", ko: "거의 회복", es: "Casi recuperado", fr: "Presque récupéré", de: "Fast erholt") }
    static var notStimulated: String { loc("未刺激", "Not Stimulated", zhHans: "未锻炼", ko: "미자극", es: "Sin estimular", fr: "Non stimulé", de: "Nicht stimuliert") }

    // 筋肉マップ
    static var front: String { loc("前面", "Front", zhHans: "正面", ko: "전면", es: "Frontal", fr: "Avant", de: "Vorne") }
    static var back: String { loc("背面", "Back", zhHans: "背面", ko: "후면", es: "Posterior", fr: "Arrière", de: "Hinten") }
    static var viewBack: String { loc("背面を見る", "View Back", zhHans: "查看背面", ko: "후면 보기", es: "Ver posterior", fr: "Voir l'arrière", de: "Rückseite anzeigen") }
    static var viewFront: String { loc("前面を見る", "View Front", zhHans: "查看正面", ko: "전면 보기", es: "Ver frontal", fr: "Voir l'avant", de: "Vorderseite anzeigen") }

    // MARK: - ワークアウト画面
    static var todayRecommendation: String { loc("今日のおすすめ", "Today's Recommendation", zhHans: "今日推荐", ko: "오늘의 추천", es: "Recomendación de hoy", fr: "Recommandation du jour", de: "Heutige Empfehlung") }
    static var favorites: String { loc("お気に入り", "Favorites", zhHans: "收藏", ko: "즐겨찾기", es: "Favoritos", fr: "Favoris", de: "Favoriten") }
    static var favoriteExercises: String { loc("お気に入り種目", "Favorite Exercises", zhHans: "收藏动作", ko: "즐겨찾기 운동", es: "Ejercicios favoritos", fr: "Exercices favoris", de: "Lieblingsübungen") }
    static var startFreeWorkout: String { loc("自由にトレーニング開始", "Start Free Workout", zhHans: "开始自由训练", ko: "자유 운동 시작", es: "Iniciar entrenamiento libre", fr: "Commencer entraînement libre", de: "Freies Training starten") }
    static var tapMuscleHint: String { loc("筋肉をタップして関連種目を選択", "Tap a muscle to select related exercises", zhHans: "点击肌肉选择相关动作", ko: "근육을 탭하여 관련 운동 선택", es: "Toca un músculo para seleccionar ejercicios relacionados", fr: "Touchez un muscle pour sélectionner les exercices associés", de: "Tippen Sie auf einen Muskel, um verwandte Übungen auszuwählen") }
    static var addExercise: String { loc("種目を追加", "Add Exercise", zhHans: "添加动作", ko: "운동 추가", es: "Añadir ejercicio", fr: "Ajouter exercice", de: "Übung hinzufügen") }
    static var addFirstExercise: String { loc("種目を追加して始める", "Add an Exercise to Start", zhHans: "添加动作以开始", ko: "운동을 추가하여 시작", es: "Añade un ejercicio para empezar", fr: "Ajoutez un exercice pour commencer", de: "Fügen Sie eine Übung hinzu, um zu beginnen") }
    static var emptyWorkoutTitle: String { loc("ワークアウトを始めましょう", "Let's Start Your Workout", zhHans: "开始训练吧", ko: "운동을 시작합시다", es: "¡Comencemos tu entrenamiento!", fr: "Commençons votre entraînement", de: "Lass uns dein Training beginnen") }
    static var emptyWorkoutHint: String { loc("上のボタンから種目を追加して、セットを記録していきましょう", "Add exercises from the button above and start recording your sets", zhHans: "从上方按钮添加动作，开始记录组数", ko: "위 버튼에서 운동을 추가하고 세트를 기록하세요", es: "Añade ejercicios desde el botón de arriba y comienza a registrar tus series", fr: "Ajoutez des exercices depuis le bouton ci-dessus et commencez à enregistrer vos séries", de: "Fügen Sie Übungen über die Schaltfläche oben hinzu und beginnen Sie mit der Aufzeichnung Ihrer Sätze") }
    static var endWorkout: String { loc("ワークアウト終了", "End Workout", zhHans: "结束训练", ko: "운동 종료", es: "Finalizar entrenamiento", fr: "Terminer l'entraînement", de: "Training beenden") }
    static var recordSet: String { loc("セットを記録", "Record Set", zhHans: "记录组数", ko: "세트 기록", es: "Registrar serie", fr: "Enregistrer série", de: "Satz aufzeichnen") }
    static var recorded: String { loc("記録済み", "Recorded", zhHans: "已记录", ko: "기록됨", es: "Registrado", fr: "Enregistré", de: "Aufgezeichnet") }
    static var neglected: String { loc("未刺激", "Neglected", zhHans: "未锻炼", ko: "미자극", es: "Descuidado", fr: "Négligé", de: "Vernachlässigt") }

    static func setNumber(_ n: Int) -> String {
        loc("セット \(n)", "Set \(n)", zhHans: "第\(n)组", ko: "세트 \(n)", es: "Serie \(n)", fr: "Série \(n)", de: "Satz \(n)")
    }
    static func setsReps(_ sets: Int, _ reps: Int) -> String {
        loc("\(sets)セット × \(reps)レップ", "\(sets) sets × \(reps) reps", zhHans: "\(sets)组 × \(reps)次", ko: "\(sets)세트 × \(reps)회", es: "\(sets) series × \(reps) reps", fr: "\(sets) séries × \(reps) reps", de: "\(sets) Sätze × \(reps) Wdh")
    }
    static func previousRecord(_ weight: Double, _ reps: Int) -> String {
        loc("前回: \(String(format: "%.1f", weight))kg × \(reps)回",
            "Previous: \(String(format: "%.1f", weight))kg × \(reps) reps",
            zhHans: "上次: \(String(format: "%.1f", weight))kg × \(reps)次",
            ko: "이전: \(String(format: "%.1f", weight))kg × \(reps)회",
            es: "Anterior: \(String(format: "%.1f", weight))kg × \(reps) reps",
            fr: "Précédent: \(String(format: "%.1f", weight))kg × \(reps) reps",
            de: "Vorherig: \(String(format: "%.1f", weight))kg × \(reps) Wdh")
    }
    static func previousRepsOnly(_ reps: Int) -> String {
        loc("前回: \(reps)回", "Previous: \(reps) reps", zhHans: "上次: \(reps)次", ko: "이전: \(reps)회", es: "Anterior: \(reps) reps", fr: "Précédent: \(reps) reps", de: "Vorherig: \(reps) Wdh")
    }
    static func weightReps(_ weight: Double, _ reps: Int) -> String {
        loc("\(String(format: "%.1f", weight))kg × \(reps)回",
            "\(String(format: "%.1f", weight))kg × \(reps) reps",
            zhHans: "\(String(format: "%.1f", weight))kg × \(reps)次",
            ko: "\(String(format: "%.1f", weight))kg × \(reps)회",
            es: "\(String(format: "%.1f", weight))kg × \(reps) reps",
            fr: "\(String(format: "%.1f", weight))kg × \(reps) reps",
            de: "\(String(format: "%.1f", weight))kg × \(reps) Wdh")
    }
    static func repsOnly(_ reps: Int) -> String {
        loc("\(reps)回", "\(reps) reps", zhHans: "\(reps)次", ko: "\(reps)회", es: "\(reps) reps", fr: "\(reps) reps", de: "\(reps) Wdh")
    }

    // 自重・加重
    static var bodyweight: String { loc("自重", "Bodyweight", zhHans: "自重", ko: "맨몸", es: "Peso corporal", fr: "Poids du corps", de: "Körpergewicht") }
    static var addWeight: String { loc("加重する", "Add Weight", zhHans: "负重", ko: "중량 추가", es: "Añadir peso", fr: "Ajouter du poids", de: "Gewicht hinzufügen") }
    static var kgAdditional: String { loc("kg (加重)", "kg (added)", zhHans: "kg（负重）", ko: "kg (추가)", es: "kg (añadido)", fr: "kg (ajouté)", de: "kg (zusätzlich)") }
    static var kg: String { loc("kg", "kg", zhHans: "kg", ko: "kg", es: "kg", fr: "kg", de: "kg") }
    static var reps: String { loc("回", "reps", zhHans: "次", ko: "회", es: "reps", fr: "reps", de: "Wdh") }

    static func tryHeavier(_ current: Double, _ suggested: Double) -> String {
        loc("前回\(String(format: "%.1f", current))kg → \(String(format: "%.1f", suggested))kgに挑戦？",
            "Try \(String(format: "%.1f", suggested))kg? (was \(String(format: "%.1f", current))kg)",
            zhHans: "上次\(String(format: "%.1f", current))kg → 挑战\(String(format: "%.1f", suggested))kg？",
            ko: "이전 \(String(format: "%.1f", current))kg → \(String(format: "%.1f", suggested))kg 도전?",
            es: "¿Probar \(String(format: "%.1f", suggested))kg? (antes \(String(format: "%.1f", current))kg)",
            fr: "Essayer \(String(format: "%.1f", suggested))kg ? (avant \(String(format: "%.1f", current))kg)",
            de: "\(String(format: "%.1f", suggested))kg versuchen? (vorher \(String(format: "%.1f", current))kg)")
    }

    // 確認ダイアログ
    static var endWorkoutConfirm: String { loc("ワークアウトを終了しますか？", "End workout?", zhHans: "结束训练？", ko: "운동을 종료하시겠습니까?", es: "¿Finalizar entrenamiento?", fr: "Terminer l'entraînement ?", de: "Training beenden?") }
    static var saveAndEnd: String { loc("記録を保存して終了", "Save and End", zhHans: "保存并结束", ko: "저장하고 종료", es: "Guardar y finalizar", fr: "Enregistrer et terminer", de: "Speichern und beenden") }
    static var discardAndEnd: String { loc("記録を破棄して終了", "Discard and End", zhHans: "放弃并结束", ko: "삭제하고 종료", es: "Descartar y finalizar", fr: "Abandonner et terminer", de: "Verwerfen und beenden") }
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
        loc("\(count)種目", "\(count) exercises", zhHans: "\(count)个动作", ko: "\(count)종목", es: "\(count) ejercicios", fr: "\(count) exercices", de: "\(count) Übungen")
    }

    // 種目リスト バッジ
    static var recommended: String { loc("おすすめ", "Recommended") }
    static var recovering: String { loc("回復中", "Recovering") }
    static var partiallyRecovering: String { loc("一部回復中", "Partially Recovering") }
    static var restSuggested: String { loc("休息推奨", "Rest Suggested") }

    // MARK: - 種目詳細
    static var description: String { loc("説明", "Description", zhHans: "说明", ko: "설명", es: "Descripción", fr: "Description", de: "Beschreibung") }
    static var formTips: String { loc("フォームのポイント", "Form Tips", zhHans: "姿势要点", ko: "자세 팁", es: "Consejos de forma", fr: "Conseils de forme", de: "Formtipps") }
    static var watchVideo: String { loc("動画で見る", "Watch Video", zhHans: "观看视频", ko: "동영상 보기", es: "Ver video", fr: "Voir la vidéo", de: "Video ansehen") }
    static var targetMuscles: String { loc("対象筋肉", "Target Muscles", zhHans: "目标肌肉", ko: "대상 근육", es: "Músculos objetivo", fr: "Muscles ciblés", de: "Zielmuskeln") }
    static var stimulationLevel: String { loc("刺激度", "Stimulation Level", zhHans: "刺激度", ko: "자극도", es: "Nivel de estimulación", fr: "Niveau de stimulation", de: "Stimulationsstufe") }
    static var highStimulation: String { loc("高 (80%+)", "High (80%+)", zhHans: "高 (80%+)", ko: "높음 (80%+)", es: "Alto (80%+)", fr: "Élevé (80%+)", de: "Hoch (80%+)") }
    static var mediumStimulation: String { loc("中 (50-79%)", "Mid (50-79%)", zhHans: "中 (50-79%)", ko: "중간 (50-79%)", es: "Medio (50-79%)", fr: "Moyen (50-79%)", de: "Mittel (50-79%)") }
    static var lowStimulation: String { loc("低 (1-49%)", "Low (1-49%)", zhHans: "低 (1-49%)", ko: "낮음 (1-49%)", es: "Bajo (1-49%)", fr: "Faible (1-49%)", de: "Niedrig (1-49%)") }

    // MARK: - 履歴・統計画面
    static var weekly: String { loc("週間", "Weekly", zhHans: "每周", ko: "주간", es: "Semanal", fr: "Hebdomadaire", de: "Wöchentlich") }
    static var monthly: String { loc("月間", "Monthly", zhHans: "每月", ko: "월간", es: "Mensual", fr: "Mensuel", de: "Monatlich") }
    static var thisWeekSummary: String { loc("今週のサマリー", "This Week's Summary", zhHans: "本周总结", ko: "이번 주 요약", es: "Resumen de esta semana", fr: "Résumé de la semaine", de: "Zusammenfassung dieser Woche") }
    static var thisMonthSummary: String { loc("今月のサマリー", "This Month's Summary", zhHans: "本月总结", ko: "이번 달 요약", es: "Resumen de este mes", fr: "Résumé du mois", de: "Zusammenfassung dieses Monats") }
    static var sessions: String { loc("セッション", "Sessions", zhHans: "训练次数", ko: "세션", es: "Sesiones", fr: "Séances", de: "Sitzungen") }
    static var totalSets: String { loc("セット数", "Total Sets", zhHans: "总组数", ko: "총 세트", es: "Series totales", fr: "Séries totales", de: "Gesamtsätze") }
    static var totalVolume: String { loc("総ボリューム", "Total Volume", zhHans: "总训练量", ko: "총 볼륨", es: "Volumen total", fr: "Volume total", de: "Gesamtvolumen") }
    static var trainingDays: String { loc("トレ日数", "Training Days", zhHans: "训练天数", ko: "훈련 일수", es: "Días de entreno", fr: "Jours d'entraînement", de: "Trainingstage") }
    static var groupCoverage: String { loc("部位カバー率", "Group Coverage", zhHans: "部位覆盖率", ko: "부위 커버율", es: "Cobertura de grupos", fr: "Couverture des groupes", de: "Gruppenabdeckung") }
    static var dailyVolume14Days: String { loc("日別ボリューム（14日間）", "Daily Volume (14 days)", zhHans: "每日训练量（14天）", ko: "일별 볼륨 (14일)", es: "Volumen diario (14 días)", fr: "Volume quotidien (14 jours)", de: "Tägliches Volumen (14 Tage)") }
    static var groupSetsThisWeek: String { loc("部位別セット数（今週）", "Sets by Group (This Week)", zhHans: "部位组数（本周）", ko: "부위별 세트 (이번 주)", es: "Series por grupo (Esta semana)", fr: "Séries par groupe (Cette semaine)", de: "Sätze nach Gruppe (Diese Woche)") }
    static var topExercises: String { loc("よく行う種目 Top5", "Top 5 Exercises", zhHans: "常做动作 Top5", ko: "자주 하는 운동 Top5", es: "Top 5 ejercicios", fr: "Top 5 exercices", de: "Top 5 Übungen") }
    static var sessionHistory: String { loc("セッション履歴", "Session History", zhHans: "训练历史", ko: "세션 기록", es: "Historial de sesiones", fr: "Historique des séances", de: "Sitzungsverlauf") }
    static var noSessionsYet: String { loc("まだセッションがありません", "No sessions yet", zhHans: "暂无训练记录", ko: "아직 세션 없음", es: "Sin sesiones aún", fr: "Pas encore de séances", de: "Noch keine Sitzungen") }
    static var inProgress: String { loc("進行中", "In Progress", zhHans: "进行中", ko: "진행 중", es: "En progreso", fr: "En cours", de: "In Bearbeitung") }
    static func minutes(_ min: Int) -> String { loc("\(min)分", "\(min) min", zhHans: "\(min)分钟", ko: "\(min)분", es: "\(min) min", fr: "\(min) min", de: "\(min) Min") }
    static var lessThanOneMinute: String { loc("<1分", "<1 min", zhHans: "<1分钟", ko: "<1분", es: "<1 min", fr: "<1 min", de: "<1 Min") }
    static var andMore: String { loc("他", "more", zhHans: "更多", ko: "더", es: "más", fr: "plus", de: "mehr") }
    static func setsLabel(_ count: Int) -> String { loc("\(count)セット", "\(count) sets", zhHans: "\(count)组", ko: "\(count)세트", es: "\(count) series", fr: "\(count) séries", de: "\(count) Sätze") }

    // MARK: - 部位詳細画面
    static var highLoadRestNeeded: String { loc("高負荷 — 休息が必要", "High Load — Rest Needed", zhHans: "高负荷 — 需要休息", ko: "고부하 — 휴식 필요", es: "Alta carga — Descanso necesario", fr: "Charge élevée — Repos nécessaire", de: "Hohe Last — Ruhe erforderlich") }
    static var fullyRecoveredTrainable: String { loc("完全回復 — トレーニング可能", "Fully Recovered — Ready to Train", zhHans: "完全恢复 — 可以训练", ko: "완전 회복 — 훈련 가능", es: "Totalmente recuperado — Listo para entrenar", fr: "Complètement récupéré — Prêt à s'entraîner", de: "Vollständig erholt — Bereit zum Training") }
    static var neglected7Days: String { loc("未刺激 — 7日以上", "Not Stimulated — 7+ days", zhHans: "未锻炼 — 7天以上", ko: "미자극 — 7일 이상", es: "Sin estimular — 7+ días", fr: "Non stimulé — 7+ jours", de: "Nicht stimuliert — 7+ Tage") }
    static var neglected14Days: String { loc("未刺激 — 14日以上", "Not Stimulated — 14+ days", zhHans: "未锻炼 — 14天以上", ko: "미자극 — 14일 이상", es: "Sin estimular — 14+ días", fr: "Non stimulé — 14+ jours", de: "Nicht stimuliert — 14+ Tage") }
    static func remainingTime(_ hours: Int, _ mins: Int) -> String {
        if hours >= 24 {
            let days = hours / 24
            let h = hours % 24
            return loc("残り\(days)日\(h)時間", "\(days)d \(h)h remaining", zhHans: "剩余\(days)天\(h)小时", ko: "\(days)일 \(h)시간 남음", es: "\(days)d \(h)h restantes", fr: "\(days)j \(h)h restants", de: "\(days)T \(h)Std verbleibend")
        }
        return loc("残り\(hours)時間", "\(hours)h remaining", zhHans: "剩余\(hours)小时", ko: "\(hours)시간 남음", es: "\(hours)h restantes", fr: "\(hours)h restantes", de: "\(hours)Std verbleibend")
    }
    static var recoveryComplete: String { loc("回復完了", "Fully Recovered", zhHans: "完全恢复", ko: "회복 완료", es: "Totalmente recuperado", fr: "Complètement récupéré", de: "Vollständig erholt") }
    static var lastStimulation: String { loc("最終刺激", "Last Stimulation", zhHans: "最后锻炼", ko: "마지막 자극", es: "Última estimulación", fr: "Dernière stimulation", de: "Letzte Stimulation") }
    static var setCount: String { loc("セット数", "Set Count", zhHans: "组数", ko: "세트 수", es: "Número de series", fr: "Nombre de séries", de: "Satzanzahl") }
    static var estimatedRecovery: String { loc("回復予定", "Est. Recovery", zhHans: "预计恢复", ko: "예상 회복", es: "Recuperación est.", fr: "Récup. estimée", de: "Gesch. Erholung") }
    static var basicInfo: String { loc("基本情報", "Basic Info", zhHans: "基本信息", ko: "기본 정보", es: "Info básica", fr: "Info de base", de: "Grundinfo") }
    static var muscleGroup: String { loc("グループ", "Group", zhHans: "分组", ko: "그룹", es: "Grupo", fr: "Groupe", de: "Gruppe") }
    static var baseRecovery: String { loc("基準回復", "Base Recovery", zhHans: "基础恢复", ko: "기본 회복", es: "Recuperación base", fr: "Récupération de base", de: "Basiserholung") }
    static var size: String { loc("サイズ", "Size", zhHans: "大小", ko: "크기", es: "Tamaño", fr: "Taille", de: "Größe") }
    static var largeMuscle: String { loc("大筋群", "Large", zhHans: "大肌群", ko: "대근육", es: "Grande", fr: "Grand", de: "Groß") }
    static var mediumMuscle: String { loc("中筋群", "Medium", zhHans: "中肌群", ko: "중근육", es: "Mediano", fr: "Moyen", de: "Mittel") }
    static var smallMuscle: String { loc("小筋群", "Small", zhHans: "小肌群", ko: "소근육", es: "Pequeño", fr: "Petit", de: "Klein") }
    static var relatedExercises: String { loc("関連種目", "Related Exercises", zhHans: "相关动作", ko: "관련 운동", es: "Ejercicios relacionados", fr: "Exercices associés", de: "Verwandte Übungen") }
    static var recentRecords: String { loc("直近の記録", "Recent Records", zhHans: "最近记录", ko: "최근 기록", es: "Registros recientes", fr: "Enregistrements récents", de: "Aktuelle Aufzeichnungen") }
    static var noRecord: String { loc("記録なし", "No record", zhHans: "无记录", ko: "기록 없음", es: "Sin registro", fr: "Aucun enregistrement", de: "Keine Aufzeichnung") }
    static var exerciseUnit: String { loc("種目", " exercises", zhHans: "动作", ko: "운동", es: " ejercicios", fr: " exercices", de: " Übungen") }
    static var exerciseAnimation: String { loc("動作アニメーション", "Exercise Animation", zhHans: "动作动画", ko: "운동 애니메이션", es: "Animación del ejercicio", fr: "Animation de l'exercice", de: "Übungsanimation") }
    static func lastRecordLabel(_ weight: Double, _ reps: Int) -> String {
        loc("前回: \(String(format: "%.0f", weight))kg × \(reps)",
            "Last: \(String(format: "%.0f", weight))kg × \(reps)",
            zhHans: "上次: \(String(format: "%.0f", weight))kg × \(reps)",
            ko: "이전: \(String(format: "%.0f", weight))kg × \(reps)",
            es: "Último: \(String(format: "%.0f", weight))kg × \(reps)",
            fr: "Dernier: \(String(format: "%.0f", weight))kg × \(reps)",
            de: "Letztes: \(String(format: "%.0f", weight))kg × \(reps)")
    }
    static func hoursUnit(_ h: Int) -> String { loc("\(h)時間", "\(h) hours", zhHans: "\(h)小时", ko: "\(h)시간", es: "\(h) horas", fr: "\(h) heures", de: "\(h) Stunden") }

    // MARK: - 設定画面
    static var premium: String { loc("プレミアム", "Premium", zhHans: "高级版", ko: "프리미엄", es: "Premium", fr: "Premium", de: "Premium") }
    static var premiumUnlocked: String { loc("全機能がアンロックされています", "All features unlocked", zhHans: "所有功能已解锁", ko: "모든 기능 잠금 해제됨", es: "Todas las funciones desbloqueadas", fr: "Toutes les fonctionnalités débloquées", de: "Alle Funktionen freigeschaltet") }
    static var upgradeToPremium: String { loc("Premiumにアップグレード", "Upgrade to Premium", zhHans: "升级到高级版", ko: "프리미엄으로 업그레이드", es: "Actualizar a Premium", fr: "Passer à Premium", de: "Auf Premium upgraden") }
    static var unlockAllFeatures: String { loc("全機能をアンロック", "Unlock all features", zhHans: "解锁所有功能", ko: "모든 기능 잠금 해제", es: "Desbloquear todas las funciones", fr: "Débloquer toutes les fonctionnalités", de: "Alle Funktionen freischalten") }
    static var restorePurchases: String { loc("購入を復元", "Restore Purchases", zhHans: "恢复购买", ko: "구매 복원", es: "Restaurar compras", fr: "Restaurer les achats", de: "Käufe wiederherstellen") }
    static var restoreResult: String { loc("復元結果", "Restore Result", zhHans: "恢复结果", ko: "복원 결과", es: "Resultado de restauración", fr: "Résultat de la restauration", de: "Wiederherstellungsergebnis") }
    static var purchaseRestored: String { loc("購入が復元されました。", "Purchase restored.", zhHans: "购买已恢复。", ko: "구매가 복원되었습니다.", es: "Compra restaurada.", fr: "Achat restauré.", de: "Kauf wiederhergestellt.") }
    static var noPurchaseFound: String { loc("復元できる購入が見つかりませんでした。", "No purchase found to restore.", zhHans: "未找到可恢复的购买。", ko: "복원할 구매를 찾을 수 없습니다.", es: "No se encontró ninguna compra para restaurar.", fr: "Aucun achat trouvé à restaurer.", de: "Kein Kauf zum Wiederherstellen gefunden.") }
    static var appSettings: String { loc("アプリ設定", "App Settings", zhHans: "应用设置", ko: "앱 설정", es: "Ajustes de la app", fr: "Paramètres de l'app", de: "App-Einstellungen") }
    static var hapticFeedback: String { loc("触覚フィードバック", "Haptic Feedback", zhHans: "触觉反馈", ko: "햅틱 피드백", es: "Retroalimentación háptica", fr: "Retour haptique", de: "Haptisches Feedback") }
    static var language: String { loc("言語", "Language", zhHans: "语言", ko: "언어", es: "Idioma", fr: "Langue", de: "Sprache") }
    static var weightUnit: String { loc("重量単位", "Weight Unit", zhHans: "重量单位", ko: "중량 단위", es: "Unidad de peso", fr: "Unité de poids", de: "Gewichtseinheit") }
    static var theme: String { loc("テーマ", "Theme", zhHans: "主题", ko: "테마", es: "Tema", fr: "Thème", de: "Thema") }
    static var data: String { loc("データ", "Data", zhHans: "数据", ko: "데이터", es: "Datos", fr: "Données", de: "Daten") }
    static var csvImport: String { loc("CSVインポート", "CSV Import", zhHans: "CSV导入", ko: "CSV 가져오기", es: "Importar CSV", fr: "Importer CSV", de: "CSV importieren") }
    static var dataExport: String { loc("データエクスポート", "Data Export", zhHans: "数据导出", ko: "데이터 내보내기", es: "Exportar datos", fr: "Exporter les données", de: "Daten exportieren") }
    static var comingSoon: String { loc("準備中", "Coming Soon", zhHans: "即将推出", ko: "준비 중", es: "Próximamente", fr: "Bientôt disponible", de: "Demnächst") }
    static var registeredExercises: String { loc("登録種目数", "Registered Exercises", zhHans: "已注册动作", ko: "등록된 운동", es: "Ejercicios registrados", fr: "Exercices enregistrés", de: "Registrierte Übungen") }
    static var trackedMuscles: String { loc("追跡筋肉数", "Tracked Muscles", zhHans: "追踪肌肉数", ko: "추적 근육 수", es: "Músculos rastreados", fr: "Muscles suivis", de: "Verfolgte Muskeln") }
    static func exerciseCount(_ count: Int) -> String {
        loc("\(count)種目", "\(count) exercises", zhHans: "\(count)个动作", ko: "\(count)개 운동", es: "\(count) ejercicios", fr: "\(count) exercices", de: "\(count) Übungen")
    }
    static func muscleCount(_ count: Int) -> String {
        loc("\(count)部位", "\(count) muscles", zhHans: "\(count)个部位", ko: "\(count)개 부위", es: "\(count) músculos", fr: "\(count) muscles", de: "\(count) Muskeln")
    }
    static var feedback: String { loc("フィードバック", "Feedback", zhHans: "反馈", ko: "피드백", es: "Comentarios", fr: "Commentaires", de: "Feedback") }
    static var appInfo: String { loc("アプリ情報", "About", zhHans: "关于", ko: "앱 정보", es: "Acerca de", fr: "À propos", de: "Über") }
    static var version: String { loc("バージョン", "Version", zhHans: "版本", ko: "버전", es: "Versión", fr: "Version", de: "Version") }
    static var tagline: String {
        loc("MuscleMap — 筋肉の状態が見える。だから、迷わない。",
            "MuscleMap — See your muscles. Train smarter.",
            zhHans: "MuscleMap — 看见肌肉状态，训练不再迷茫。",
            ko: "MuscleMap — 근육 상태를 보세요. 더 스마트하게 훈련하세요.",
            es: "MuscleMap — Ve tus músculos. Entrena más inteligente.",
            fr: "MuscleMap — Voyez vos muscles. Entraînez-vous intelligemment.",
            de: "MuscleMap — Sieh deine Muskeln. Trainiere smarter.")
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
        loc("\(groupName)が最も回復しています", "\(groupName) is most recovered", zhHans: "\(groupName)恢复得最好", ko: "\(groupName)이(가) 가장 회복됨", es: "\(groupName) está más recuperado", fr: "\(groupName) est le plus récupéré", de: "\(groupName) ist am meisten erholt")
    }
    static func muscleNeglectedDays(_ muscleName: String, _ days: Int) -> String {
        loc("。\(muscleName)は\(days)日以上未刺激です", ". \(muscleName) hasn't been trained for \(days)+ days", zhHans: "。\(muscleName)已超过\(days)天未锻炼", ko: ". \(muscleName)은(는) \(days)일 이상 자극 없음", es: ". \(muscleName) no se ha entrenado en \(days)+ días", fr: ". \(muscleName) n'a pas été entraîné depuis \(days)+ jours", de: ". \(muscleName) wurde seit \(days)+ Tagen nicht trainiert")
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
        loc("回復まであと\(hours)時間", "\(hours)h until recovery", zhHans: "距离恢复还有\(hours)小时", ko: "회복까지 \(hours)시간", es: "\(hours)h para recuperación", fr: "\(hours)h avant récupération", de: "\(hours)h bis zur Erholung")
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
        loc("\(count)件", "\(count) items", zhHans: "\(count)条", ko: "\(count)개", es: "\(count) elementos", fr: "\(count) éléments", de: "\(count) Einträge")
    }
    static func fileReadError(_ detail: String) -> String {
        loc("ファイルの読み込みに失敗: \(detail)", "Failed to read file: \(detail)", zhHans: "文件读取失败: \(detail)", ko: "파일 읽기 실패: \(detail)", es: "Error al leer archivo: \(detail)", fr: "Échec de lecture du fichier: \(detail)", de: "Datei konnte nicht gelesen werden: \(detail)")
    }
    static func fileSelectionError(_ detail: String) -> String {
        loc("ファイル選択エラー: \(detail)", "File selection error: \(detail)", zhHans: "文件选择错误: \(detail)", ko: "파일 선택 오류: \(detail)", es: "Error de selección de archivo: \(detail)", fr: "Erreur de sélection de fichier: \(detail)", de: "Dateiauswahlfehler: \(detail)")
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
        loc("他\(count)種目", "+\(count) more", zhHans: "还有\(count)个", ko: "외 \(count)개", es: "+\(count) más", fr: "+\(count) autres", de: "+\(count) weitere")
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
        case "下半身（四頭筋）": return loc("下半身（四頭筋）", "Legs (Quads)", zhHans: "下肢（股四头肌）", ko: "하체 (대퇴사두근)", es: "Piernas (Cuádriceps)", fr: "Jambes (Quadriceps)", de: "Beine (Quadrizeps)")
        case "下半身（ハムストリングス）": return loc("下半身（ハムストリングス）", "Legs (Hamstrings)", zhHans: "下肢（腘绳肌）", ko: "하체 (햄스트링)", es: "Piernas (Isquiotibiales)", fr: "Jambes (Ischio-jambiers)", de: "Beine (Beinbizeps)")
        case "下半身（臀部）": return loc("下半身（臀部）", "Legs (Glutes)", zhHans: "下肢（臀部）", ko: "하체 (둔근)", es: "Piernas (Glúteos)", fr: "Jambes (Fessiers)", de: "Beine (Gesäß)")
        case "下半身（ふくらはぎ）": return loc("下半身（ふくらはぎ）", "Legs (Calves)", zhHans: "下肢（小腿）", ko: "하체 (종아리)", es: "Piernas (Pantorrillas)", fr: "Jambes (Mollets)", de: "Beine (Waden)")
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
        loc("累計\(count)回達成", "\(count) times achieved", zhHans: "累计达成\(count)次", ko: "총 \(count)회 달성", es: "\(count) veces logrado", fr: "\(count) fois atteint", de: "\(count) mal erreicht")
    }

    // MARK: - 週間サマリー
    static var weeklySummary: String { loc("週間サマリー", "Weekly Summary") }
    static var weeklyReport: String { loc("WEEKLY REPORT", "WEEKLY REPORT") }
    static var workouts: String { loc("ワークアウト", "Workouts") }
    static var volumeKg: String { loc("ボリューム(kg)", "Volume (kg)") }
    static var mvpMuscle: String { loc("今週のMVP", "This Week's MVP") }
    static func stimulatedTimes(_ count: Int) -> String {
        loc("\(count)回刺激", "\(count) times stimulated", zhHans: "刺激\(count)次", ko: "\(count)회 자극", es: "\(count) veces estimulado", fr: "\(count) fois stimulé", de: "\(count) mal stimuliert")
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
        loc("\(count)セッション分析", "\(count) sessions analyzed", zhHans: "分析了\(count)次训练", ko: "\(count)세션 분석", es: "\(count) sesiones analizadas", fr: "\(count) séances analysées", de: "\(count) Trainingseinheiten analysiert")
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
        loc("\(count)部位", "\(count) parts", zhHans: "\(count)个部位", ko: "\(count)부위", es: "\(count) partes", fr: "\(count) parties", de: "\(count) Bereiche")
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
        loc("\(days)日放置", "\(days) days neglected", zhHans: "已\(days)天未练", ko: "\(days)일 방치", es: "\(days) días descuidado", fr: "\(days) jours négligé", de: "\(days) Tage vernachlässigt")
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
