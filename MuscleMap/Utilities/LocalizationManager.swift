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
    static var goBackButton: String { loc("戻る", "Back", zhHans: "返回", ko: "뒤로", es: "Atrás", fr: "Retour", de: "Zurück") }
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
    static var browseExercises: String { loc("種目を探す", "Browse Exercises", zhHans: "浏览动作", ko: "운동 찾기", es: "Buscar ejercicios", fr: "Parcourir les exercices", de: "Übungen durchsuchen") }
    static var favoritesSection: String { loc("お気に入り", "Favorites", zhHans: "收藏", ko: "즐겨찾기", es: "Favoritos", fr: "Favoris", de: "Favoriten") }
    static var recentSearches: String { loc("最近の検索", "Recent Searches", zhHans: "最近搜索", ko: "최근 검색", es: "Búsquedas recientes", fr: "Recherches récentes", de: "Letzte Suchen") }
    static var addToWorkout: String { loc("ワークアウトに追加", "Add to Workout", zhHans: "添加到训练", ko: "운동에 추가", es: "Añadir al entrenamiento", fr: "Ajouter à l'entraînement", de: "Zum Training hinzufügen") }
    static var fatigued: String { loc("疲労", "Fatigued", zhHans: "疲劳", ko: "피로", es: "Fatigado", fr: "Fatigué", de: "Ermüdet") }
    static var gridView: String { loc("グリッド", "Grid", zhHans: "网格", ko: "그리드", es: "Cuadrícula", fr: "Grille", de: "Raster") }
    static var listViewLabel: String { loc("リスト", "List", zhHans: "列表", ko: "목록", es: "Lista", fr: "Liste", de: "Liste") }
    static var neglectedLabel: String { loc("未刺激", "Neglected", zhHans: "未刺激", ko: "미자극", es: "Descuidado", fr: "Négligé", de: "Vernachlässigt") }
    static var noPerformanceData: String { loc("記録なし", "No records", zhHans: "无记录", ko: "기록 없음", es: "Sin registros", fr: "Aucun enregistrement", de: "Keine Aufzeichnungen") }
    static var previousPerformance: String { loc("過去のパフォーマンス", "Previous Performance", zhHans: "历史表现", ko: "이전 퍼포먼스", es: "Rendimiento anterior", fr: "Performance précédente", de: "Vorherige Leistung") }
    static var recovered: String { loc("回復済", "Recovered", zhHans: "已恢复", ko: "회복됨", es: "Recuperado", fr: "Récupéré", de: "Erholt") }
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
    static var viewRecovery: String { loc("回復マップに戻る", "View Recovery", zhHans: "查看恢复", ko: "회복 보기", es: "Ver recuperación", fr: "Voir récupération", de: "Erholung anzeigen") }

    // MARK: - ワークアウト画面
    static var todayRecommendation: String { loc("今日のおすすめ", "Today's Recommendation", zhHans: "今日推荐", ko: "오늘의 추천", es: "Recomendación de hoy", fr: "Recommandation du jour", de: "Heutige Empfehlung") }
    static var todayMenu: String { loc("今日のメニュー", "Today's Menu", zhHans: "今日菜单", ko: "오늘의 메뉴", es: "Menú de hoy", fr: "Menu du jour", de: "Heutiges Menü") }
    static var firstTimeMenuHeader: String { loc("まずはこのメニューから", "Start with this menu", zhHans: "先从这个菜单开始", ko: "이 메뉴부터 시작하세요", es: "Empieza con este menú", fr: "Commencez par ce menu", de: "Starte mit diesem Menü") }
    static var firstTimeRecommendation: String { loc("初回おすすめ", "First Workout", zhHans: "首次推荐", ko: "첫 운동 추천", es: "Primera recomendación", fr: "Premier entraînement", de: "Erste Empfehlung") }
    static var favorites: String { loc("お気に入り", "Favorites", zhHans: "收藏", ko: "즐겨찾기", es: "Favoritos", fr: "Favoris", de: "Favoriten") }
    static var favoriteExercises: String { loc("お気に入り種目", "Favorite Exercises", zhHans: "收藏动作", ko: "즐겨찾기 운동", es: "Ejercicios favoritos", fr: "Exercices favoris", de: "Lieblingsübungen") }
    static var startFreeWorkout: String { loc("自由にトレーニング開始", "Start Free Workout", zhHans: "开始自由训练", ko: "자유 운동 시작", es: "Iniciar entrenamiento libre", fr: "Commencer entraînement libre", de: "Freies Training starten") }
    static var tapMuscleHint: String { loc("筋肉をタップして関連種目を選択", "Tap a muscle to select related exercises", zhHans: "点击肌肉选择相关动作", ko: "근육을 탭하여 관련 운동 선택", es: "Toca un músculo para seleccionar ejercicios relacionados", fr: "Touchez un muscle pour sélectionner les exercices associés", de: "Tippen Sie auf einen Muskel, um verwandte Übungen auszuwählen") }
    static var addExercise: String { loc("種目を追加", "Add Exercise", zhHans: "添加动作", ko: "운동 추가", es: "Añadir ejercicio", fr: "Ajouter exercice", de: "Übung hinzufügen") }
    static var addFirstExercise: String { loc("種目を追加して始める", "Add an Exercise to Start", zhHans: "添加动作以开始", ko: "운동을 추가하여 시작", es: "Añade un ejercicio para empezar", fr: "Ajoutez un exercice pour commencer", de: "Fügen Sie eine Übung hinzu, um zu beginnen") }
    static var addExerciseAndStart: String { loc("種目を追加して始める", "Add Exercise & Start", zhHans: "添加动作并开始", ko: "운동 추가하고 시작", es: "Añadir ejercicio y empezar", fr: "Ajouter exercice et commencer", de: "Übung hinzufügen und starten") }
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
    static var deleteSetConfirm: String { loc("このセットを削除しますか？", "Delete this set?", zhHans: "删除此组？", ko: "이 세트를 삭제하시겠습니까?", es: "¿Eliminar esta serie?", fr: "Supprimer cette série ?", de: "Diesen Satz löschen?") }

    // MARK: - 種目選択・種目辞典
    static var selectExercise: String { loc("種目を選択", "Select Exercise", zhHans: "选择动作", ko: "운동 선택", es: "Seleccionar ejercicio", fr: "Choisir un exercice", de: "Übung auswählen") }
    static var all: String { loc("すべて", "All", zhHans: "全部", ko: "전체", es: "Todo", fr: "Tout", de: "Alle") }
    static var filterGym: String { loc("ジム", "Gym", zhHans: "健身房", ko: "헬스장", es: "Gimnasio", fr: "Salle de sport", de: "Fitnessstudio") }
    static var filterHome: String { loc("自宅", "Home", zhHans: "居家", ko: "홈", es: "Casa", fr: "Domicile", de: "Zuhause") }
    static var noExercisesForLocation: String { loc("この場所で使える種目はありません", "No exercises for this location", zhHans: "此场所无可用动作", ko: "이 장소에서 사용할 수 있는 운동이 없습니다", es: "No hay ejercicios para esta ubicación", fr: "Aucun exercice pour ce lieu", de: "Keine Übungen für diesen Ort") }
    static var recent: String { loc("最近", "Recent", zhHans: "最近", ko: "최근", es: "Recientes", fr: "Récents", de: "Kürzlich") }
    static var equipment: String { loc("器具", "Equipment", zhHans: "器械", ko: "기구", es: "Equipamiento", fr: "Équipement", de: "Geräte") }
    static var searchExercises: String { loc("種目を検索", "Search exercises", zhHans: "搜索动作", ko: "운동 검색", es: "Buscar ejercicios", fr: "Rechercher des exercices", de: "Übungen suchen") }
    static var noFavorites: String { loc("お気に入りがありません", "No favorites", zhHans: "暂无收藏", ko: "즐겨찾기 없음", es: "Sin favoritos", fr: "Aucun favori", de: "Keine Favoriten") }
    static var addFavoritesHint: String {
        loc("種目詳細画面の☆ボタンで\nお気に入りに追加できます",
            "Tap the ☆ button in exercise detail\nto add favorites",
            zhHans: "在动作详情中点击☆按钮\n即可添加收藏",
            ko: "운동 상세 화면의 ☆ 버튼을\n탭하여 즐겨찾기에 추가하세요",
            es: "Toca el botón ☆ en el detalle\npara añadir favoritos",
            fr: "Touchez le bouton ☆ dans le détail\npour ajouter aux favoris",
            de: "Tippe auf ☆ im Übungsdetail\num Favoriten hinzuzufügen")
    }
    static var noRecentExercises: String { loc("最近使った種目がありません", "No recent exercises", zhHans: "暂无最近使用的动作", ko: "최근 사용한 운동이 없습니다", es: "Sin ejercicios recientes", fr: "Aucun exercice récent", de: "Keine kürzlichen Übungen") }
    static var recentExercisesHint: String {
        loc("ワークアウトで種目を記録すると\nここに表示されます",
            "Exercises you use in workouts\nwill appear here",
            zhHans: "训练中使用的动作\n将显示在此处",
            ko: "운동에서 사용한 종목이\n여기에 표시됩니다",
            es: "Los ejercicios que uses\naparecerán aquí",
            fr: "Les exercices utilisés\napparaîtront ici",
            de: "Verwendete Übungen\nerscheinen hier")
    }
    static func exerciseCountLabel(_ count: Int) -> String {
        loc("\(count)種目", "\(count) exercises", zhHans: "\(count)个动作", ko: "\(count)종목", es: "\(count) ejercicios", fr: "\(count) exercices", de: "\(count) Übungen")
    }

    // 種目リスト バッジ
    static var recommended: String { loc("おすすめ", "Recommended", zhHans: "推荐", ko: "추천", es: "Recomendado", fr: "Recommandé", de: "Empfohlen") }
    static var recovering: String { loc("回復中", "Recovering", zhHans: "恢复中", ko: "회복 중", es: "Recuperando", fr: "En récupération", de: "Erholend") }
    static var partiallyRecovering: String { loc("一部回復中", "Partially Recovering", zhHans: "部分恢复中", ko: "일부 회복 중", es: "Parcialmente recuperado", fr: "Partiellement récupéré", de: "Teilweise erholt") }
    static var restSuggested: String { loc("休息推奨", "Rest Suggested", zhHans: "建议休息", ko: "휴식 권장", es: "Descanso sugerido", fr: "Repos conseillé", de: "Ruhe empfohlen") }

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
    static var account: String { loc("アカウント", "Account", zhHans: "账户", ko: "계정", es: "Cuenta", fr: "Compte", de: "Konto") }
    static var profileEdit: String { loc("プロフィール編集", "Edit Profile", zhHans: "编辑个人资料", ko: "프로필 편집", es: "Editar perfil", fr: "Modifier le profil", de: "Profil bearbeiten") }
    static var proUpgradeTitle: String { loc("Pro版にアップグレード", "Upgrade to Pro", zhHans: "升级到 Pro", ko: "Pro로 업그레이드", es: "Actualizar a Pro", fr: "Passer à Pro", de: "Auf Pro upgraden") }
    static var proUpgradeSubtitle: String { loc("筋力マップ・種目別推移グラフを解放", "Unlock Strength Map & exercise trend charts", zhHans: "解锁力量图和动作趋势图", ko: "Strength Map 및 종목 추이 그래프 잠금 해제", es: "Desbloquea Strength Map y gráficos de tendencia", fr: "Débloquez Strength Map et graphiques de tendance", de: "Strength Map und Übungstrends freischalten") }
    static var proUpgradeCellTitle: String { loc("MuscleMap Pro — アップグレード", "MuscleMap Pro — Upgrade", zhHans: "MuscleMap Pro — 升级", ko: "MuscleMap Pro — 업그레이드", es: "MuscleMap Pro — Actualizar", fr: "MuscleMap Pro — Mise à niveau", de: "MuscleMap Pro — Upgrade") }
    static var proUpgradeCellSubtitle: String { loc("筋力マップ・種目提案・無制限記録を解放", "Unlock Strength Map, suggestions & unlimited tracking", zhHans: "解锁力量图、智能推荐和无限记录", ko: "Strength Map, 제안 및 무제한 기록 잠금 해제", es: "Desbloquea Strength Map, sugerencias y registro ilimitado", fr: "Débloquez Strength Map, suggestions et suivi illimité", de: "Strength Map, Vorschläge und unbegrenztes Tracking") }
    static var myRoutine: String { loc("マイルーティン", "My Routine", zhHans: "我的训练计划", ko: "마이 루틴", es: "Mi rutina", fr: "Ma routine", de: "Meine Routine") }
    static var socialFeed: String { loc("ソーシャルフィード", "Social Feed", zhHans: "社交动态", ko: "소셜 피드", es: "Feed social", fr: "Fil social", de: "Sozialer Feed") }
    static var profileNickname: String { loc("ニックネーム", "Nickname", zhHans: "昵称", ko: "닉네임", es: "Apodo", fr: "Pseudo", de: "Spitzname") }
    static var profileWeight: String { loc("体重", "Weight", zhHans: "体重", ko: "체중", es: "Peso", fr: "Poids", de: "Gewicht") }
    static var profileBasicInfo: String { loc("基本情報", "Basic Info", zhHans: "基本信息", ko: "기본 정보", es: "Info básica", fr: "Info de base", de: "Grundinfo") }
    static var profileWeightFooter: String { loc("体重はStrength Mapのスコア計算に使用されます", "Weight is used for Strength Map score calculations", zhHans: "体重用于 Strength Map 分数计算", ko: "체중은 Strength Map 점수 계산에 사용됩니다", es: "El peso se usa para calcular el puntaje de Strength Map", fr: "Le poids est utilisé pour le calcul du score Strength Map", de: "Gewicht wird für die Strength Map-Berechnung verwendet") }
    static var developerMenu: String { loc("開発者メニュー", "Developer Menu", zhHans: "开发者菜单", ko: "개발자 메뉴", es: "Menú de desarrollador", fr: "Menu développeur", de: "Entwicklermenü") }

    // MARK: - LocationSelectionPage
    static var locationTitle: String { loc("どこで鍛える？", "Where do you train?", zhHans: "在哪里锻炼？", ko: "어디서 운동하나요?", es: "¿Dónde entrenas?", fr: "Où vous entraînez-vous ?", de: "Wo trainierst du?") }
    static var locationSubtitle: String { loc("使える器具に合わせて種目を提案します", "We'll suggest exercises based on your equipment", zhHans: "我们将根据你的器械推荐动作", ko: "사용 가능한 기구에 맞춰 운동을 제안합니다", es: "Sugeriremos ejercicios según tu equipamiento", fr: "Nous suggérerons des exercices selon votre équipement", de: "Wir schlagen Übungen basierend auf deinem Equipment vor") }
    static var locationGym: String { loc("ジム", "Gym", zhHans: "健身房", ko: "헬스장", es: "Gimnasio", fr: "Salle de sport", de: "Fitnessstudio") }
    static var locationHome: String { loc("自宅", "Home", zhHans: "居家", ko: "홈", es: "Casa", fr: "Domicile", de: "Zuhause") }
    static var locationBoth: String { loc("両方", "Both", zhHans: "两者都有", ko: "둘 다", es: "Ambos", fr: "Les deux", de: "Beides") }
    static var locationGymDesc: String { loc("マシン・バーベル・ダンベル全部使える", "Full access to machines, barbells & dumbbells", zhHans: "器械、杠铃、哑铃全部可用", ko: "머신, 바벨, 덤벨 모두 사용 가능", es: "Acceso completo a máquinas, barras y mancuernas", fr: "Accès complet aux machines, barres et haltères", de: "Voller Zugang zu Maschinen, Langhanteln & Kurzhanteln") }
    static var locationHomeDesc: String { loc("自重とダンベルでしっかり鍛える", "Bodyweight & dumbbell focused", zhHans: "以自重和哑铃为主", ko: "맨몸과 덤벨 중심", es: "Enfocado en peso corporal y mancuernas", fr: "Centré sur le poids du corps et les haltères", de: "Körpergewicht & Kurzhantel-fokussiert") }
    static var locationBothDesc: String { loc("ジムと自宅を組み合わせる", "Mix gym and home workouts", zhHans: "健身房和居家训练结合", ko: "헬스장과 홈 운동 병행", es: "Combina gimnasio y casa", fr: "Mélange salle et domicile", de: "Fitnessstudio und Zuhause kombinieren") }
    static var locationExerciseCount: String { loc("収録", "included", zhHans: "收录", ko: "수록", es: "incluidos", fr: "inclus", de: "enthalten") }
    static var locationHomeExercises: String { loc("自宅でできる種目", "home exercises", zhHans: "居家可做的动作", ko: "홈 운동 종목", es: "ejercicios en casa", fr: "exercices à domicile", de: "Heimübungen") }
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
    static var privacyPolicy: String { loc("プライバシーポリシー", "Privacy Policy", zhHans: "隐私政策", ko: "개인정보 처리방침", es: "Política de privacidad", fr: "Politique de confidentialité", de: "Datenschutzrichtlinie") }
    static var termsOfService: String { loc("利用規約", "Terms of Service", zhHans: "服务条款", ko: "이용약관", es: "Términos de servicio", fr: "Conditions d'utilisation", de: "Nutzungsbedingungen") }

    // MARK: - オンボーディング
    static var onboardingTitle1: String { loc("筋肉の状態が見える", "See Your Muscle Status", zhHans: "查看肌肉状态", ko: "근육 상태 확인", es: "Ve el estado de tus músculos", fr: "Voyez l'état de vos muscles", de: "Sieh deinen Muskelstatus") }
    static var onboardingSubtitle1: String {
        loc("21の筋肉の回復状態を\nリアルタイムで可視化",
            "Visualize recovery status of\n21 muscles in real-time",
            zhHans: "实时可视化\n21块肌肉的恢复状态",
            ko: "21개 근육의 회복 상태를\n실시간으로 시각화",
            es: "Visualiza la recuperación de\n21 músculos en tiempo real",
            fr: "Visualisez la récupération de\n21 muscles en temps réel",
            de: "Erholungsstatus von\n21 Muskeln in Echtzeit sehen")
    }
    static var onboardingDetail1: String {
        loc("トレーニング後の筋肉は色で回復度を表示。\n赤→緑へのグラデーションで一目瞭然。",
            "Post-workout muscles show recovery with colors.\nRed to green gradient at a glance.",
            zhHans: "训练后的肌肉用颜色显示恢复度。\n红→绿渐变一目了然。",
            ko: "운동 후 근육의 회복도를 색상으로 표시.\n빨강→초록 그라데이션으로 한눈에 확인.",
            es: "Los músculos muestran recuperación con colores.\nDe rojo a verde de un vistazo.",
            fr: "Les muscles montrent la récupération par couleurs.\nDu rouge au vert en un coup d'œil.",
            de: "Muskeln zeigen Erholung durch Farben.\nRot-zu-Grün-Verlauf auf einen Blick.")
    }
    static var onboardingTitle2: String { loc("迷わないメニュー提案", "Smart Menu Suggestions", zhHans: "智能菜单推荐", ko: "스마트 메뉴 제안", es: "Sugerencias inteligentes", fr: "Suggestions intelligentes", de: "Smarte Menüvorschläge") }
    static var onboardingSubtitle2: String {
        loc("回復データから\n今日のベストメニューを自動提案",
            "Auto-suggest today's best menu\nfrom recovery data",
            zhHans: "基于恢复数据\n自动推荐今日最佳菜单",
            ko: "회복 데이터를 기반으로\n오늘의 최적 메뉴를 자동 제안",
            es: "Sugerencia automática del mejor menú\nbasada en datos de recuperación",
            fr: "Suggestion automatique du meilleur menu\nà partir des données de récupération",
            de: "Automatischer Vorschlag des besten Menüs\naus Erholungsdaten")
    }
    static var onboardingDetail2: String {
        loc("ジムで開いた瞬間にスタートできる。\n未刺激の部位も見逃しません。",
            "Start the moment you open at the gym.\nNever miss neglected muscles.",
            zhHans: "在健身房打开即可开始。\n不会遗漏未锻炼的部位。",
            ko: "헬스장에서 열자마자 바로 시작.\n미자극 부위도 놓치지 않습니다.",
            es: "Empieza al abrir en el gimnasio.\nNunca olvides músculos descuidados.",
            fr: "Commencez dès l'ouverture à la salle.\nNe manquez jamais un muscle négligé.",
            de: "Starte sofort im Fitnessstudio.\nVernachlässigte Muskeln nicht verpassen.")
    }
    static var onboardingTitle3: String { loc("成長を記録・分析", "Track & Analyze Growth", zhHans: "记录和分析成长", ko: "성장 기록 및 분석", es: "Registra y analiza tu progreso", fr: "Suivez et analysez votre progression", de: "Fortschritt verfolgen & analysieren") }
    static var onboardingSubtitle3: String {
        loc("80種目のEMGベース刺激マッピングで\n科学的なトレーニング管理",
            "Scientific training with\nEMG-based mapping for 80 exercises",
            zhHans: "基于80个动作的EMG刺激数据\n进行科学训练管理",
            ko: "80종목의 EMG 기반 자극 매핑으로\n과학적 트레이닝 관리",
            es: "Entrenamiento científico con\nmapeo EMG para 80 ejercicios",
            fr: "Entraînement scientifique avec\ncartographie EMG de 80 exercices",
            de: "Wissenschaftliches Training mit\nEMG-Mapping für 80 Übungen")
    }
    static var onboardingDetail3: String {
        loc("セット数・ボリューム・部位カバー率を\nチャートで確認。",
            "View sets, volume, and coverage\nin charts.",
            zhHans: "通过图表查看组数、训练量\n和部位覆盖率。",
            ko: "세트 수, 볼륨, 부위 커버율을\n차트로 확인.",
            es: "Revisa series, volumen y cobertura\nen gráficos.",
            fr: "Consultez séries, volume et couverture\nen graphiques.",
            de: "Sätze, Volumen und Abdeckung\nin Diagrammen ansehen.")
    }
    static var trainingGoalQuestion: String { loc("トレーニングの目標は？", "What's your training goal?", zhHans: "你的训练目标是？", ko: "트레이닝 목표는?", es: "¿Cuál es tu objetivo?", fr: "Quel est votre objectif ?", de: "Was ist dein Trainingsziel?") }
    static var goalSuggestionHint: String { loc("あなたに合ったメニューを提案します", "We'll suggest menus tailored for you", zhHans: "我们将为你推荐合适的菜单", ko: "당신에게 맞는 메뉴를 제안합니다", es: "Te sugeriremos menús personalizados", fr: "Nous vous suggérerons des menus adaptés", de: "Wir schlagen dir passende Menüs vor") }
    static var aboutYouQuestion: String { loc("あなたについて教えてください", "Tell us about yourself", zhHans: "请介绍一下自己", ko: "자신에 대해 알려주세요", es: "Cuéntanos sobre ti", fr: "Parlez-nous de vous", de: "Erzähl uns von dir") }
    static var nicknameOptional: String { loc("ニックネーム（任意）", "Nickname (optional)", zhHans: "昵称（可选）", ko: "닉네임 (선택)", es: "Apodo (opcional)", fr: "Pseudo (facultatif)", de: "Spitzname (optional)") }
    static var nickname: String { loc("ニックネーム", "Nickname", zhHans: "昵称", ko: "닉네임", es: "Apodo", fr: "Pseudo", de: "Spitzname") }
    static var trainingExperience: String { loc("トレーニング経験", "Training Experience", zhHans: "训练经验", ko: "트레이닝 경험", es: "Experiencia de entrenamiento", fr: "Expérience d'entraînement", de: "Trainingserfahrung") }

    // MARK: - 部位名（カテゴリ）
    static var categoryChest: String { loc("胸", "Chest", zhHans: "胸", ko: "가슴", es: "Pecho", fr: "Poitrine", de: "Brust") }
    static var categoryBack: String { loc("背中", "Back", zhHans: "背", ko: "등", es: "Espalda", fr: "Dos", de: "Rücken") }
    static var categoryShoulders: String { loc("肩", "Shoulders", zhHans: "肩", ko: "어깨", es: "Hombros", fr: "Épaules", de: "Schultern") }
    static var categoryArmsBiceps: String { loc("腕（二頭）", "Arms (Biceps)", zhHans: "手臂（肱二头肌）", ko: "팔 (이두근)", es: "Brazos (Bíceps)", fr: "Bras (Biceps)", de: "Arme (Bizeps)") }
    static var categoryArmsTriceps: String { loc("腕（三頭）", "Arms (Triceps)", zhHans: "手臂（肱三头肌）", ko: "팔 (삼두근)", es: "Brazos (Tríceps)", fr: "Bras (Triceps)", de: "Arme (Trizeps)") }
    static var categoryLegs: String { loc("脚", "Legs", zhHans: "腿", ko: "다리", es: "Piernas", fr: "Jambes", de: "Beine") }
    static var categoryCore: String { loc("腹", "Core", zhHans: "核心", ko: "코어", es: "Core", fr: "Core", de: "Core") }
    static var categoryArms: String { loc("腕", "Arms", zhHans: "手臂", ko: "팔", es: "Brazos", fr: "Bras", de: "Arme") }
    static var categoryLowerBody: String { loc("下半身", "Lower Body", zhHans: "下肢", ko: "하체", es: "Tren inferior", fr: "Bas du corps", de: "Unterkörper") }

    // MARK: - 器具名
    static var equipmentBarbell: String { loc("バーベル", "Barbell", zhHans: "杠铃", ko: "바벨", es: "Barra", fr: "Barre", de: "Langhantel") }
    static var equipmentDumbbell: String { loc("ダンベル", "Dumbbell", zhHans: "哑铃", ko: "덤벨", es: "Mancuerna", fr: "Haltère", de: "Kurzhantel") }
    static var equipmentCable: String { loc("ケーブル", "Cable", zhHans: "绳索", ko: "케이블", es: "Cable", fr: "Câble", de: "Kabelzug") }
    static var equipmentMachine: String { loc("マシン", "Machine", zhHans: "器械", ko: "머신", es: "Máquina", fr: "Machine", de: "Maschine") }
    static var equipmentBodyweight: String { loc("自重", "Bodyweight", zhHans: "自重", ko: "맨몸", es: "Peso corporal", fr: "Poids du corps", de: "Körpergewicht") }

    // MARK: - 難易度
    static var difficultyBeginner: String { loc("初級", "Beginner", zhHans: "初级", ko: "초급", es: "Principiante", fr: "Débutant", de: "Anfänger") }
    static var difficultyIntermediate: String { loc("中級", "Intermediate", zhHans: "中级", ko: "중급", es: "Intermedio", fr: "Intermédiaire", de: "Fortgeschritten") }
    static var difficultyAdvanced: String { loc("上級", "Advanced", zhHans: "高级", ko: "상급", es: "Avanzado", fr: "Avancé", de: "Profi") }

    // MARK: - YouTube検索
    static var youtubeSearch: String { loc("YouTube検索", "YouTube Search", zhHans: "YouTube搜索", ko: "YouTube 검색", es: "Buscar en YouTube", fr: "Recherche YouTube", de: "YouTube-Suche") }
    static var searchLanguage: String { loc("検索言語", "Search Language", zhHans: "搜索语言", ko: "검색 언어", es: "Idioma de búsqueda", fr: "Langue de recherche", de: "Suchsprache") }
    static var followAppLanguage: String { loc("アプリの言語に合わせる", "Follow App Language", zhHans: "跟随应用语言", ko: "앱 언어에 맞추기", es: "Seguir idioma de la app", fr: "Suivre la langue de l'app", de: "App-Sprache verwenden") }
    static var searchInJapanese: String { loc("日本語で検索", "Search in Japanese", zhHans: "用日语搜索", ko: "일본어로 검색", es: "Buscar en japonés", fr: "Rechercher en japonais", de: "Auf Japanisch suchen") }
    static var searchInEnglish: String { loc("英語で検索", "Search in English", zhHans: "用英语搜索", ko: "영어로 검색", es: "Buscar en inglés", fr: "Rechercher en anglais", de: "Auf Englisch suchen") }

    // MARK: - レストタイマー設定
    static var restTimerDuration: String { loc("レストタイマー", "Rest Timer", zhHans: "休息计时器", ko: "휴식 타이머", es: "Temporizador de descanso", fr: "Minuteur de repos", de: "Pausentimer") }
    static var seconds: String { loc("秒", "s", zhHans: "秒", ko: "초", es: "s", fr: "s", de: "s") }

    // MARK: - メニュー提案理由
    static var letsStartTraining: String { loc("トレーニングを始めましょう", "Let's start training", zhHans: "开始训练吧", ko: "트레이닝을 시작합시다", es: "¡Empecemos a entrenar!", fr: "Commençons l'entraînement", de: "Lass uns mit dem Training beginnen") }
    static var basedOnRecovery: String { loc("回復状態に基づく提案", "Based on recovery status", zhHans: "基于恢复状态的建议", ko: "회복 상태 기반 제안", es: "Basado en estado de recuperación", fr: "Basé sur l'état de récupération", de: "Basierend auf Erholungsstatus") }
    static var suggestionReason: String { loc("提案理由", "Why this menu", zhHans: "推荐理由", ko: "제안 이유", es: "Por qué este menú", fr: "Pourquoi ce menu", de: "Warum dieses Menü") }
    static var suggestedExercises: String { loc("おすすめ種目", "Suggested Exercises", zhHans: "推荐动作", ko: "추천 종목", es: "Ejercicios sugeridos", fr: "Exercices suggérés", de: "Vorgeschlagene Übungen") }
    static func groupMostRecovered(_ groupName: String) -> String {
        loc("\(groupName)が最も回復しています", "\(groupName) is most recovered", zhHans: "\(groupName)恢复得最好", ko: "\(groupName)이(가) 가장 회복됨", es: "\(groupName) está más recuperado", fr: "\(groupName) est le plus récupéré", de: "\(groupName) ist am meisten erholt")
    }
    static func muscleNeglectedDays(_ muscleName: String, _ days: Int) -> String {
        loc("。\(muscleName)は\(days)日以上未刺激です", ". \(muscleName) hasn't been trained for \(days)+ days", zhHans: "。\(muscleName)已超过\(days)天未锻炼", ko: ". \(muscleName)은(는) \(days)일 이상 자극 없음", es: ". \(muscleName) no se ha entrenado en \(days)+ días", fr: ". \(muscleName) n'a pas été entraîné depuis \(days)+ jours", de: ". \(muscleName) wurde seit \(days)+ Tagen nicht trainiert")
    }

    // MARK: - オンボーディング
    static var getStarted: String { loc("はじめる", "Get Started", zhHans: "开始使用", ko: "시작하기", es: "Comenzar", fr: "Commencer", de: "Los geht's") }
    static var onboardingTagline1: String { loc("鍛えた筋肉が光る。", "Your trained muscles glow.", zhHans: "锻炼过的肌肉会发光。", ko: "단련한 근육이 빛납니다.", es: "Tus músculos entrenados brillan.", fr: "Vos muscles entraînés brillent.", de: "Deine trainierten Muskeln leuchten.") }
    static var onboardingTagline2: String { loc("回復状態が一目でわかる。", "See recovery at a glance.", zhHans: "恢复状态一目了然。", ko: "회복 상태를 한눈에.", es: "Ve la recuperación de un vistazo.", fr: "Voyez la récupération d'un coup d'œil.", de: "Erholung auf einen Blick sehen.") }
    static var selectLanguage: String { loc("言語を選択", "Select Language", zhHans: "选择语言", ko: "언어 선택", es: "Seleccionar idioma", fr: "Choisir la langue", de: "Sprache auswählen") }
    // 言語名（ネイティブ表記で固定）
    static var languageJapanese: String { "日本語" }
    static var languageEnglish: String { "English" }

    // MARK: - スプラッシュ画面
    static var splashTagline: String { loc("鍛えた筋肉が光る。", "Your trained muscles glow.", zhHans: "锻炼过的肌肉会发光。", ko: "단련한 근육이 빛납니다.", es: "Tus músculos entrenados brillan.", fr: "Vos muscles entraînés brillent.", de: "Deine trainierten Muskeln leuchten.") }
    static var splashSubcopy: String { loc("筋肉の回復を可視化する", "Visualize muscle recovery", zhHans: "可视化肌肉恢复", ko: "근육 회복을 시각화", es: "Visualiza la recuperación muscular", fr: "Visualisez la récupération musculaire", de: "Muskelerholung visualisieren") }
    static var splashContinue: String { loc("始める", "Get Started", zhHans: "开始", ko: "시작하기", es: "Comenzar", fr: "Commencer", de: "Los geht's") }

    // MARK: - オンボーディングV2
    static var onboardingV2Title1: String { loc("努力を、可視化する。", "Visualize Your Effort.", zhHans: "将努力，可视化。", ko: "노력을 시각화하다.", es: "Visualiza tu esfuerzo.", fr: "Visualisez votre effort.", de: "Visualisiere deinen Einsatz.") }
    static var onboardingV2Subtitle1: String {
        loc("鍛えた筋肉が光る。回復状態が一目でわかる。",
            "See your muscles light up. Track recovery at a glance.",
            zhHans: "锻炼过的肌肉会发光。恢复状态一目了然。",
            ko: "단련한 근육이 빛납니다. 회복 상태를 한눈에.",
            es: "Tus músculos brillan. Ve la recuperación de un vistazo.",
            fr: "Vos muscles s'illuminent. Suivez la récupération d'un coup d'œil.",
            de: "Deine Muskeln leuchten. Erholung auf einen Blick.")
    }
    static var onboardingGoalQuestion: String { loc("主な目標は何ですか？", "What's your primary goal?", zhHans: "你的主要目标是什么？", ko: "주요 목표는 무엇인가요?", es: "¿Cuál es tu objetivo principal?", fr: "Quel est votre objectif principal ?", de: "Was ist dein Hauptziel?") }
    static var goalMuscleGain: String { loc("筋力アップ", "Muscle Gain", zhHans: "增肌", ko: "근력 향상", es: "Ganar músculo", fr: "Prise de muscle", de: "Muskelaufbau") }
    static var goalFatLoss: String { loc("脂肪燃焼", "Fat Loss", zhHans: "燃脂", ko: "체지방 감소", es: "Quemar grasa", fr: "Perte de graisse", de: "Fettabbau") }
    static var goalHealth: String { loc("健康維持", "Stay Healthy", zhHans: "保持健康", ko: "건강 유지", es: "Mantener la salud", fr: "Rester en forme", de: "Gesund bleiben") }
    static var continueButton: String { loc("続ける", "Continue", zhHans: "继续", ko: "계속", es: "Continuar", fr: "Continuer", de: "Weiter") }
    static var onboardingDemoTitle: String { loc("鍛えた部位が光る", "Trained muscles glow", zhHans: "锻炼的部位会发光", ko: "단련한 부위가 빛납니다", es: "Los músculos entrenados brillan", fr: "Les muscles entraînés brillent", de: "Trainierte Muskeln leuchten") }
    static var onboardingDemoHint: String { loc("筋肉をタップして体験", "Tap muscles to try it out", zhHans: "点击肌肉体验", ko: "근육을 탭하여 체험", es: "Toca los músculos para probar", fr: "Touchez les muscles pour essayer", de: "Tippe auf Muskeln zum Ausprobieren") }

    // MARK: - 体重入力画面（WeightInputPage）
    static var weightInputTitle: String { loc("あなたの体重を教えてください", "Tell Us Your Weight", zhHans: "请告诉我们你的体重", ko: "체중을 알려주세요", es: "Dinos tu peso", fr: "Indiquez votre poids", de: "Sag uns dein Gewicht") }
    static var weightInputSubtitle: String { loc("体重比で筋力スコアを算出します", "Used to calculate your strength score by body weight ratio", zhHans: "用于按体重比计算力量分数", ko: "체중 대비 근력 점수를 산출합니다", es: "Usado para calcular tu puntaje de fuerza por peso corporal", fr: "Utilisé pour calculer votre score de force par rapport au poids", de: "Wird zur Berechnung deines Stärke-Scores verwendet") }
    static var nicknamePlaceholder: String { loc("ニックネーム", "Nickname", zhHans: "昵称", ko: "닉네임", es: "Apodo", fr: "Pseudo", de: "Spitzname") }

    static var termsOfUse: String { loc("利用規約", "Terms of Use", zhHans: "使用条款", ko: "이용약관", es: "Términos de uso", fr: "Conditions d'utilisation", de: "Nutzungsbedingungen") }

    // MARK: - 機能紹介画面（CallToActionPage）
    static var ctaPageTitle: String { loc("MuscleMapでできること", "What MuscleMap Can Do", zhHans: "MuscleMap能做什么", ko: "MuscleMap으로 할 수 있는 것", es: "Lo que MuscleMap puede hacer", fr: "Ce que MuscleMap peut faire", de: "Was MuscleMap kann") }
    static var ctaFeature1Title: String { loc("筋肉の可視化", "Muscle Visualization", zhHans: "肌肉可视化", ko: "근육 시각화", es: "Visualización muscular", fr: "Visualisation musculaire", de: "Muskelvisualisierung") }
    static var ctaFeature1Desc: String { loc("21部位の回復状態をリアルタイムで確認", "Check recovery status of 21 muscles in real-time", zhHans: "实时查看21块肌肉的恢复状态", ko: "21개 부위의 회복 상태를 실시간 확인", es: "Comprueba la recuperación de 21 músculos en tiempo real", fr: "Vérifiez la récupération de 21 muscles en temps réel", de: "Erholungsstatus von 21 Muskeln in Echtzeit prüfen") }
    static var ctaFeature2Title: String { loc("スマートな記録", "Smart Logging", zhHans: "智能记录", ko: "스마트 기록", es: "Registro inteligente", fr: "Suivi intelligent", de: "Smartes Logging") }
    static var ctaFeature2Desc: String { loc("数タップで完了するワークアウト記録", "Complete workout logging in just a few taps", zhHans: "几次点击即可完成训练记录", ko: "몇 번의 탭으로 운동 기록 완료", es: "Registra entrenamientos con solo unos toques", fr: "Enregistrez vos entraînements en quelques touches", de: "Training mit wenigen Tipps erfassen") }
    static var ctaFeature3Title: String { loc("科学的な回復計算", "Scientific Recovery", zhHans: "科学恢复计算", ko: "과학적 회복 계산", es: "Recuperación científica", fr: "Récupération scientifique", de: "Wissenschaftliche Erholung") }
    static var ctaFeature3Desc: String { loc("EMGデータに基づく最適な休息期間", "Optimal rest periods based on EMG data", zhHans: "基于EMG数据的最佳休息时间", ko: "EMG 데이터 기반의 최적 휴식 기간", es: "Periodos de descanso óptimos basados en datos EMG", fr: "Périodes de repos optimales basées sur les données EMG", de: "Optimale Ruhezeiten basierend auf EMG-Daten") }
    static var ctaGetStartedFree: String { loc("無料ではじめる", "Start for Free", zhHans: "免费开始", ko: "무료로 시작", es: "Comenzar gratis", fr: "Commencer gratuitement", de: "Kostenlos starten") }
    static var ctaStrengthMapHint: String { loc("Strength Mapで筋力を可視化", "Visualize strength with Strength Map", zhHans: "用 Strength Map 可视化力量", ko: "Strength Map으로 근력 시각화", es: "Visualiza tu fuerza con Strength Map", fr: "Visualisez votre force avec Strength Map", de: "Stärke mit Strength Map visualisieren") }
    static var ctaProHint: String { loc("Pro版でさらに詳しく分析", "Unlock deeper analysis with Pro", zhHans: "升级 Pro 解锁更深入的分析", ko: "Pro로 더 깊은 분석 잠금 해제", es: "Desbloquea análisis avanzados con Pro", fr: "Débloquez des analyses avancées avec Pro", de: "Tiefere Analysen mit Pro freischalten") }

    // MARK: - プロフィール入力画面（ProfileInputPage: トレ歴+体重+ニックネーム統合）
    static var profileInputTitle: String { loc("あなたについて教えて", "Tell Us About You", zhHans: "介绍一下自己", ko: "자신에 대해 알려주세요", es: "Cuéntanos sobre ti", fr: "Parlez-nous de vous", de: "Erzähl uns von dir") }
    static var profileInputSubtitle: String { loc("最適なメニューを提案します", "We'll build the perfect plan for you", zhHans: "我们将为你量身定制计划", ko: "최적의 메뉴를 제안합니다", es: "Crearemos el plan perfecto para ti", fr: "Nous créerons le plan parfait pour vous", de: "Wir erstellen den perfekten Plan für dich") }
    static var profileWeightLabel: String { loc("体重", "Weight", zhHans: "体重", ko: "체중", es: "Peso", fr: "Poids", de: "Gewicht") }
    static var profileNicknameLabel: String { loc("ニックネーム", "Nickname", zhHans: "昵称", ko: "닉네임", es: "Apodo", fr: "Pseudo", de: "Spitzname") }
    static var profileOptional: String { loc("（任意）", "(optional)", zhHans: "（可选）", ko: "(선택)", es: "(opcional)", fr: "(facultatif)", de: "(optional)") }

    // MARK: - トレーニング経験（ProfileInputPage内セクション）
    static var trainingExpTitle: String { loc("トレーニングの経験は？", "Training Experience?", zhHans: "你的训练经验？", ko: "트레이닝 경험은?", es: "¿Experiencia de entrenamiento?", fr: "Expérience d'entraînement ?", de: "Trainingserfahrung?") }
    static var trainingExpSubtitle: String { loc("あなたに合った提案をします", "We'll tailor suggestions for you", zhHans: "我们将为你量身推荐", ko: "당신에게 맞는 제안을 합니다", es: "Personalizaremos las sugerencias", fr: "Nous adapterons les suggestions", de: "Wir passen die Vorschläge an dich an") }
    static var trainingExpBeginner: String { loc("これから始める", "Just Starting", zhHans: "准备开始", ko: "이제 시작", es: "Empezando", fr: "Je commence", de: "Gerade angefangen") }
    static var trainingExpBeginnerSub: String { loc("初めて or 久しぶりに復帰", "First time or coming back", zhHans: "初次或久违复出", ko: "처음 또는 오랜만에 복귀", es: "Primera vez o volviendo", fr: "Première fois ou reprise", de: "Erstes Mal oder Wiedereinstieg") }
    static var trainingExpHalfYear: String { loc("半年くらい", "About 6 Months", zhHans: "约半年", ko: "약 6개월", es: "Unos 6 meses", fr: "Environ 6 mois", de: "Etwa 6 Monate") }
    static var trainingExpHalfYearSub: String { loc("基本的な種目はわかる", "Know the basic exercises", zhHans: "了解基本动作", ko: "기본 종목은 알고 있음", es: "Conozco los ejercicios básicos", fr: "Je connais les exercices de base", de: "Kenne die Grundübungen") }
    static var trainingExpOneYearPlus: String { loc("1年以上", "1+ Years", zhHans: "1年以上", ko: "1년 이상", es: "Más de 1 año", fr: "Plus d'1 an", de: "Über 1 Jahr") }
    static var trainingExpOneYearPlusSub: String { loc("自分のメニューがある", "Have my own routine", zhHans: "有自己的训练计划", ko: "나만의 루틴이 있음", es: "Tengo mi propia rutina", fr: "J'ai ma propre routine", de: "Habe meine eigene Routine") }
    static var trainingExpVeteran: String { loc("3年以上のベテラン", "3+ Year Veteran", zhHans: "3年以上的老手", ko: "3년 이상 베테랑", es: "Veterano 3+ años", fr: "Vétéran 3+ ans", de: "3+ Jahre Veteran") }
    static var trainingExpVeteranSub: String { loc("PRにこだわりがある", "Obsessed with PRs", zhHans: "执着于突破PR", ko: "PR에 집착하는 편", es: "Obsesionado con los PRs", fr: "Obsédé par les PRs", de: "Besessen von PRs") }

    // MARK: - PR入力画面（PRInputPage）
    static var prInputTitle: String { loc("いつも何キロで鍛えてる？", "What weight do you usually lift?", zhHans: "平时用多重的重量训练？", ko: "보통 몇 킬로로 운동하나요?", es: "¿Cuánto peso sueles levantar?", fr: "Quel poids soulevez-vous habituellement ?", de: "Mit welchem Gewicht trainierst du?") }
    static var prInputSubtitle: String { loc("あなたの強さレベルを判定します", "We'll assess your strength level", zhHans: "我们将评估你的力量水平", ko: "당신의 강도 레벨을 판정합니다", es: "Evaluaremos tu nivel de fuerza", fr: "Nous évaluerons votre niveau de force", de: "Wir bewerten dein Stärke-Level") }
    static var prBenchPress: String { loc("ベンチプレス", "Bench Press", zhHans: "卧推", ko: "벤치프레스", es: "Press de banca", fr: "Développé couché", de: "Bankdrücken") }
    static var prSquat: String { loc("スクワット", "Squat", zhHans: "深蹲", ko: "스쿼트", es: "Sentadilla", fr: "Squat", de: "Kniebeuge") }
    static var prDeadlift: String { loc("デッドリフト", "Deadlift", zhHans: "硬拉", ko: "데드리프트", es: "Peso muerto", fr: "Soulevé de terre", de: "Kreuzheben") }
    static var prOverallLevel: String { loc("あなたの総合レベル", "Your Overall Level", zhHans: "你的综合水平", ko: "당신의 종합 레벨", es: "Tu nivel general", fr: "Votre niveau global", de: "Dein Gesamtlevel") }

    // MARK: - 目標選択画面（GoalSelectionPage — エモーショナル版）
    static var goalSelectionHeadline: String { loc("なぜ鍛える？", "Why Do You Train?", zhHans: "为什么锻炼？", ko: "왜 운동하나요?", es: "¿Por qué entrenas?", fr: "Pourquoi vous entraînez-vous ?", de: "Warum trainierst du?") }
    static var goalSelectionSub: String { loc("1つ選んでください", "Choose one", zhHans: "请选择一个", ko: "하나를 선택하세요", es: "Elige uno", fr: "Choisissez-en un", de: "Wähle eines") }

    // MARK: - やりたい種目選択画面（FavoriteExercisesPage）
    static var favoriteExercisesTitle: String { loc("気になる種目はある？", "Any exercises you like?", zhHans: "有感兴趣的动作吗？", ko: "관심 있는 운동이 있나요?", es: "¿Algún ejercicio que te guste?", fr: "Des exercices qui vous intéressent ?", de: "Übungen, die dich interessieren?") }
    static var favoriteExercisesSub: String { loc("選んだ種目を優先的に提案します（スキップOK）", "Selected exercises will be prioritized (skip OK)", zhHans: "选择的动作将优先推荐（可跳过）", ko: "선택한 운동을 우선 제안합니다 (건너뛰기 가능)", es: "Los ejercicios seleccionados tendrán prioridad (puedes omitir)", fr: "Les exercices choisis seront prioritaires (passer OK)", de: "Gewählte Übungen werden bevorzugt (Überspringen OK)") }
    static func exerciseSelectedCount(_ count: Int) -> String { loc("\(count)種目選択中", "\(count) selected", zhHans: "已选\(count)个", ko: "\(count)개 선택 중", es: "\(count) seleccionados", fr: "\(count) sélectionnés", de: "\(count) ausgewählt") }

    // MARK: - ルーティンビルダー（RoutineBuilderPage）
    static var routineBuilderTitle: String { loc("あなたの週間メニュー", "Your Weekly Routine", zhHans: "你的每周计划", ko: "당신의 주간 루틴", es: "Tu rutina semanal", fr: "Votre routine hebdomadaire", de: "Deine Wochenroutine") }
    static var routineBuilderSub: String { loc("自動で種目を提案しました。追加・削除できます", "We suggested exercises for you. Add or remove as you like", zhHans: "已自动推荐动作，可自行添加或删除", ko: "자동으로 종목을 제안했습니다. 추가·삭제 가능", es: "Sugerimos ejercicios. Añade o elimina como quieras", fr: "Nous avons suggéré des exercices. Ajoutez ou supprimez à volonté", de: "Wir haben Übungen vorgeschlagen. Füge hinzu oder entferne nach Belieben") }
    static var routineBuilderNextDay: String { loc("次のDayへ", "Next Day", zhHans: "下一天", ko: "다음 Day로", es: "Siguiente día", fr: "Jour suivant", de: "Nächster Tag") }
    static var routineBuilderComplete: String { loc("ルーティン完成！", "Complete Routine!", zhHans: "训练计划完成！", ko: "루틴 완성!", es: "¡Rutina completa!", fr: "Routine terminée !", de: "Routine fertig!") }
    static func routineExerciseCount(_ current: Int, _ max: Int) -> String { loc("\(current)/\(max)種目", "\(current)/\(max) exercises", zhHans: "\(current)/\(max)个动作", ko: "\(current)/\(max)종목", es: "\(current)/\(max) ejercicios", fr: "\(current)/\(max) exercices", de: "\(current)/\(max) Übungen") }
    static var routineAddExercise: String { loc("種目を追加", "Add Exercise", zhHans: "添加动作", ko: "운동 추가", es: "Añadir ejercicio", fr: "Ajouter exercice", de: "Übung hinzufügen") }
    static var routineAlreadyAdded: String { loc("追加済み", "Added", zhHans: "已添加", ko: "추가됨", es: "Añadido", fr: "Ajouté", de: "Hinzugefügt") }
    static var routineSetRepSets: String { loc("セット数", "Sets", zhHans: "组数", ko: "세트 수", es: "Series", fr: "Séries", de: "Sätze") }
    static var routineSetRepReps: String { loc("レップ数", "Reps", zhHans: "次数", ko: "횟수", es: "Reps", fr: "Reps", de: "Wdh") }
    static var routineLocationGym: String { loc("ジム", "Gym", zhHans: "健身房", ko: "헬스장", es: "Gimnasio", fr: "Salle", de: "Studio") }
    static var routineLocationHome: String { loc("自宅", "Home", zhHans: "居家", ko: "홈", es: "Casa", fr: "Domicile", de: "Zuhause") }

    // MARK: - ルーティン完了（RoutineCompletionPage）
    static var routineCompletionDefaultHeadline: String { loc("あなたの体の変化を記録しよう。", "Track your body transformation.", zhHans: "记录你的身体变化。", ko: "당신의 몸의 변화를 기록하세요.", es: "Registra la transformación de tu cuerpo.", fr: "Suivez la transformation de votre corps.", de: "Verfolge deine Körpertransformation.") }
    static var routineCompletionSub: String { loc("あなただけのメニューが完成しました", "Your personalized routine is ready", zhHans: "你的专属计划已就绪", ko: "당신만의 메뉴가 완성되었습니다", es: "Tu rutina personalizada está lista", fr: "Votre routine personnalisée est prête", de: "Deine personalisierte Routine ist fertig") }
    static func routineTotalExercises(_ exercises: Int, _ days: Int) -> String { loc("合計\(exercises)種目 / \(days)日分", "\(exercises) exercises / \(days) days", zhHans: "共\(exercises)个动作 / \(days)天", ko: "총 \(exercises)종목 / \(days)일", es: "\(exercises) ejercicios / \(days) días", fr: "\(exercises) exercices / \(days) jours", de: "\(exercises) Übungen / \(days) Tage") }
    static func routineExerciseCountShort(_ count: Int) -> String { loc("\(count)種目", "\(count) exercises", zhHans: "\(count)个动作", ko: "\(count)종목", es: "\(count) ejercicios", fr: "\(count) exercices", de: "\(count) Übungen") }
    static var routineUnlockPro: String { loc("Pro版で始める", "Start with Pro", zhHans: "升级 Pro 开始", ko: "Pro로 시작", es: "Empezar con Pro", fr: "Commencer avec Pro", de: "Mit Pro starten") }

    // MARK: - 通知許可画面
    static var notificationTitle: String { loc("回復したらお知らせ", "Get Notified When Recovered", zhHans: "恢复后通知你", ko: "회복되면 알려드립니다", es: "Recibe aviso al recuperarte", fr: "Soyez averti une fois récupéré", de: "Benachrichtigung bei Erholung") }
    static var notificationDescription: String {
        loc("筋肉が回復したタイミングで通知を受け取れます",
            "Receive notifications when your muscles are ready to train again",
            zhHans: "当肌肉恢复完毕时收到通知",
            ko: "근육이 회복되면 알림을 받을 수 있습니다",
            es: "Recibe notificaciones cuando tus músculos estén listos",
            fr: "Recevez des notifications quand vos muscles sont prêts",
            de: "Erhalte Benachrichtigungen, wenn deine Muskeln bereit sind")
    }
    static var allowNotifications: String { loc("通知を許可", "Allow Notifications", zhHans: "允许通知", ko: "알림 허용", es: "Permitir notificaciones", fr: "Autoriser les notifications", de: "Benachrichtigungen erlauben") }
    static var maybeLater: String { loc("あとで", "Maybe Later", zhHans: "稍后再说", ko: "나중에", es: "Quizás después", fr: "Peut-être plus tard", de: "Vielleicht später") }

    // MARK: - チュートリアルバナー（WorkoutIdleView）
    static var tutorialBanner: String { loc("チュートリアル中 — 1セット記録してみよう！", "Tutorial — Try logging 1 set!", zhHans: "教程中 — 试着记录1组！", ko: "튜토리얼 중 — 1세트 기록해 보세요!", es: "Tutorial — ¡Registra 1 serie!", fr: "Tutoriel — Enregistrez 1 série !", de: "Tutorial — Versuche 1 Satz aufzuzeichnen!") }

    // MARK: - CTA画面の3つの価値（CallToActionPage）
    static var ctaValue1: String { loc("鍛えた筋肉が光るマップ", "See your trained muscles glow", zhHans: "锻炼过的肌肉在地图上发光", ko: "단련한 근육이 빛나는 맵", es: "Mapa con músculos que brillan", fr: "Carte des muscles qui brillent", de: "Karte mit leuchtenden Muskeln") }
    static var ctaValue2: String { loc("あとXkgでレベルアップ", "Level up with just Xkg more", zhHans: "再加Xkg即可升级", ko: "Xkg만 더하면 레벨 업", es: "Sube de nivel con Xkg más", fr: "Montez de niveau avec Xkg de plus", de: "Level up mit nur Xkg mehr") }
    static var ctaValue3: String { loc("90日チャレンジで変化を証明", "Prove your progress in 90 days", zhHans: "90天挑战证明你的蜕变", ko: "90일 챌린지로 변화를 증명", es: "Demuestra tu progreso en 90 días", fr: "Prouvez vos progrès en 90 jours", de: "Beweise deinen Fortschritt in 90 Tagen") }

    // MARK: - CSVインポート
    static var selectCSVFile: String { loc("CSVファイルを選択", "Select CSV File", zhHans: "选择CSV文件", ko: "CSV 파일 선택", es: "Seleccionar archivo CSV", fr: "Sélectionner le fichier CSV", de: "CSV-Datei auswählen") }
    static var strongHevyFormat: String { loc("Strong/Hevy形式に対応", "Supports Strong/Hevy format", zhHans: "支持Strong/Hevy格式", ko: "Strong/Hevy 형식 지원", es: "Compatible con formato Strong/Hevy", fr: "Compatible avec le format Strong/Hevy", de: "Unterstützt Strong/Hevy-Format") }
    static var fileSelection: String { loc("ファイル選択", "File Selection", zhHans: "文件选择", ko: "파일 선택", es: "Selección de archivo", fr: "Sélection de fichier", de: "Dateiauswahl") }
    static var workoutCount: String { loc("ワークアウト数", "Workout Count", zhHans: "训练次数", ko: "운동 횟수", es: "Cantidad de entrenamientos", fr: "Nombre d'entraînements", de: "Anzahl Trainings") }
    static var unregisteredExercises: String { loc("未登録の種目", "Unregistered Exercises", zhHans: "未注册的动作", ko: "미등록 종목", es: "Ejercicios no registrados", fr: "Exercices non enregistrés", de: "Nicht registrierte Übungen") }
    static var potentialDuplicates: String { loc("重複の可能性", "Potential Duplicates", zhHans: "可能重复", ko: "중복 가능성", es: "Posibles duplicados", fr: "Doublons potentiels", de: "Mögliche Duplikate") }
    static var preview: String { loc("プレビュー", "Preview", zhHans: "预览", ko: "미리보기", es: "Vista previa", fr: "Aperçu", de: "Vorschau") }
    static var executeImport: String { loc("インポート実行", "Execute Import", zhHans: "执行导入", ko: "가져오기 실행", es: "Ejecutar importación", fr: "Exécuter l'import", de: "Import ausführen") }
    static var importComplete: String { loc("インポート完了", "Import Complete", zhHans: "导入完成", ko: "가져오기 완료", es: "Importación completa", fr: "Import terminé", de: "Import abgeschlossen") }
    static var result: String { loc("結果", "Result", zhHans: "结果", ko: "결과", es: "Resultado", fr: "Résultat", de: "Ergebnis") }
    static var supportedFormat: String { loc("対応フォーマット", "Supported Format", zhHans: "支持格式", ko: "지원 형식", es: "Formato compatible", fr: "Format pris en charge", de: "Unterstütztes Format") }
    static var help: String { loc("ヘルプ", "Help", zhHans: "帮助", ko: "도움말", es: "Ayuda", fr: "Aide", de: "Hilfe") }
    static var noAccessPermission: String { loc("ファイルへのアクセス権限がありません", "No permission to access file", zhHans: "没有文件访问权限", ko: "파일 접근 권한이 없습니다", es: "Sin permiso para acceder al archivo", fr: "Pas d'autorisation d'accès au fichier", de: "Keine Berechtigung für Dateizugriff") }
    static var noWorkoutDataFound: String {
        loc("ワークアウトデータが見つかりませんでした。フォーマットを確認してください。",
            "No workout data found. Please check the format.",
            zhHans: "未找到训练数据，请检查格式。",
            ko: "운동 데이터를 찾을 수 없습니다. 형식을 확인하세요.",
            es: "No se encontraron datos. Verifica el formato.",
            fr: "Aucune donnée trouvée. Vérifiez le format.",
            de: "Keine Trainingsdaten gefunden. Bitte Format prüfen.")
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
            "Supports CSV exported from apps like Strong, Hevy, etc.",
            zhHans: "支持从Strong、Hevy等应用导出的CSV",
            ko: "Strong, Hevy 등의 앱에서 내보낸 CSV 지원",
            es: "Compatible con CSV de Strong, Hevy, etc.",
            fr: "Compatible avec les CSV de Strong, Hevy, etc.",
            de: "Unterstützt CSV aus Strong, Hevy usw.")
    }

    // MARK: - ワークアウト完了画面
    static var workoutComplete: String { loc("ワークアウト完了！", "Workout Complete!", zhHans: "训练完成！", ko: "운동 완료!", es: "¡Entrenamiento completo!", fr: "Entraînement terminé !", de: "Training abgeschlossen!") }
    static var share: String { loc("シェア", "Share", zhHans: "分享", ko: "공유", es: "Compartir", fr: "Partager", de: "Teilen") }
    static var shareWorkout: String { loc("トレーニングをシェア", "Share Workout", zhHans: "分享训练", ko: "운동 공유", es: "Compartir entrenamiento", fr: "Partager l'entraînement", de: "Training teilen") }
    static var shareTagline: String { loc("筋肉の回復を可視化", "Visualize muscle recovery", zhHans: "可视化肌肉恢复", ko: "근육 회복을 시각화", es: "Visualiza la recuperación muscular", fr: "Visualisez la récupération musculaire", de: "Muskelerholung visualisieren") }
    static var shareTo: String { loc("シェア先を選択", "Share to", zhHans: "分享到", ko: "공유 대상 선택", es: "Compartir en", fr: "Partager vers", de: "Teilen mit") }
    static var shareToInstagramStories: String { loc("Instagram Storiesにシェア", "Share to Instagram Stories", zhHans: "分享到 Instagram Stories", ko: "Instagram Stories에 공유", es: "Compartir en Instagram Stories", fr: "Partager sur Instagram Stories", de: "Auf Instagram Stories teilen") }
    static var shareToOtherApps: String { loc("その他のアプリにシェア", "Share to other apps", zhHans: "分享到其他应用", ko: "다른 앱에 공유", es: "Compartir en otras apps", fr: "Partager vers d'autres apps", de: "In anderen Apps teilen") }
    static var downloadApp: String { loc("アプリをダウンロード →", "Download the app →", zhHans: "下载应用 →", ko: "앱 다운로드 →", es: "Descargar la app →", fr: "Télécharger l'app →", de: "App herunterladen →") }
    static var todaysWorkout: String { loc("今日のワークアウト", "Today's Workout", zhHans: "今日训练", ko: "오늘의 운동", es: "Entrenamiento de hoy", fr: "Entraînement du jour", de: "Heutiges Training") }
    static var exercises: String { loc("種目", "Exercises", zhHans: "动作", ko: "종목", es: "Ejercicios", fr: "Exercices", de: "Übungen") }
    static var sets: String { loc("セット", "Sets", zhHans: "组", ko: "세트", es: "Series", fr: "Séries", de: "Sätze") }
    static var time: String { loc("時間", "Time", zhHans: "时间", ko: "시간", es: "Tiempo", fr: "Temps", de: "Zeit") }
    static var stimulatedMuscles: String { loc("刺激した筋肉", "Stimulated Muscles", zhHans: "刺激的肌肉", ko: "자극한 근육", es: "Músculos estimulados", fr: "Muscles stimulés", de: "Stimulierte Muskeln") }
    static var exercisesDone: String { loc("実施した種目", "Exercises Done", zhHans: "完成的动作", ko: "실시한 종목", es: "Ejercicios realizados", fr: "Exercices effectués", de: "Absolvierte Übungen") }
    static var pr: String { loc("PR", "PR", zhHans: "PR", ko: "PR", es: "PR", fr: "PR", de: "PR") }
    static var volume: String { loc("ボリューム", "Volume", zhHans: "训练量", ko: "볼륨", es: "Volumen", fr: "Volume", de: "Volumen") }

    // MARK: - ワークアウト完了画面（アップグレード）
    static var beastModeActivated: String { loc("怪物モード発動", "Beast mode activated", zhHans: "怪物模式启动", ko: "비스트 모드 발동", es: "Modo bestia activado", fr: "Mode bête activé", de: "Beast-Modus aktiviert") }
    static var newRecordsSet: String { loc("自己ベスト更新！", "New records set!", zhHans: "刷新个人纪录！", ko: "자기 최고 기록 갱신!", es: "¡Nuevos récords!", fr: "Nouveaux records !", de: "Neue Rekorde!") }
    static var solidSession: String { loc("充実のセッション", "Solid session", zhHans: "充实的训练", ko: "충실한 세션", es: "Sesión sólida", fr: "Séance solide", de: "Solides Training") }
    static var goodWork: String { loc("おつかれさま", "Good work", zhHans: "辛苦了", ko: "수고했어요", es: "Buen trabajo", fr: "Bon travail", de: "Gute Arbeit") }
    static var newPR: String { loc("NEW PR!", "NEW PR!", zhHans: "NEW PR!", ko: "NEW PR!", es: "¡NUEVO PR!", fr: "NOUVEAU PR !", de: "NEUER PR!") }
    static var scheduleReminder: String { loc("リマインダーを設定", "Schedule reminder", zhHans: "设置提醒", ko: "리마인더 설정", es: "Programar recordatorio", fr: "Programmer un rappel", de: "Erinnerung planen") }
    static var reminderScheduled: String { loc("リマインダー設定済み", "Reminder scheduled", zhHans: "提醒已设置", ko: "리마인더 설정 완료", es: "Recordatorio programado", fr: "Rappel programmé", de: "Erinnerung geplant") }
    static var nextWorkoutSuggestion: String { loc("次のトレーニング", "Next Workout", zhHans: "下次训练", ko: "다음 트레이닝", es: "Próximo entrenamiento", fr: "Prochain entraînement", de: "Nächstes Training") }

    static func andMoreCount(_ count: Int) -> String {
        loc("他\(count)種目", "+\(count) more", zhHans: "还有\(count)个", ko: "외 \(count)개", es: "+\(count) más", fr: "+\(count) autres", de: "+\(count) weitere")
    }

    // MARK: - 追加カテゴリ・器具
    static var categoryArmsForearms: String { loc("腕（前腕）", "Arms (Forearms)", zhHans: "手臂（前臂）", ko: "팔 (전완근)", es: "Brazos (Antebrazos)", fr: "Bras (Avant-bras)", de: "Arme (Unterarme)") }
    static var categoryFullBody: String { loc("全身", "Full Body", zhHans: "全身", ko: "전신", es: "Cuerpo completo", fr: "Corps entier", de: "Ganzkörper") }
    static var equipmentKettlebell: String { loc("ケトルベル", "Kettlebell", zhHans: "壶铃", ko: "케틀벨", es: "Kettlebell", fr: "Kettlebell", de: "Kettlebell") }
    static var equipmentTool: String { loc("器具", "Equipment", zhHans: "器械", ko: "기구", es: "Equipamiento", fr: "Équipement", de: "Geräte") }

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
    static var fullBodyConquestTitle: String { loc("全身制覇達成！", "Full Body Conquered!", zhHans: "全身征服达成！", ko: "전신 정복 달성!", es: "¡Cuerpo completo conquistado!", fr: "Corps entier conquis !", de: "Ganzkörper bezwungen!") }
    static var fullBodyConquestSubtitle: String { loc("全21部位を刺激しました", "All 21 muscles stimulated", zhHans: "已刺激全部21块肌肉", ko: "21개 부위 모두 자극 완료", es: "Los 21 músculos estimulados", fr: "Les 21 muscles stimulés", de: "Alle 21 Muskeln stimuliert") }
    static var allMusclesStimulated: String { loc("全21部位を刺激中", "All 21 muscles active", zhHans: "全部21块肌肉活跃中", ko: "21개 부위 모두 자극 중", es: "Los 21 músculos activos", fr: "Les 21 muscles actifs", de: "Alle 21 Muskeln aktiv") }
    static var fullBodyConquestAchieved: String { loc("全身制覇達成", "Full Body Conquered", zhHans: "全身征服达成", ko: "전신 정복 달성", es: "Cuerpo completo conquistado", fr: "Corps entier conquis", de: "Ganzkörper bezwungen") }
    static func fullBodyConquestShareText(_ hashtag: String, _ url: String) -> String {
        loc("全21部位を刺激して全身制覇達成！\(hashtag)\n\(url)",
            "Full body conquered! All 21 muscles stimulated! \(hashtag)\n\(url)",
            zhHans: "全身21块肌肉全部刺激，全身征服达成！\(hashtag)\n\(url)",
            ko: "21개 부위 모두 자극하여 전신 정복 달성! \(hashtag)\n\(url)",
            es: "¡Cuerpo completo conquistado! ¡21 músculos estimulados! \(hashtag)\n\(url)",
            fr: "Corps entier conquis ! 21 muscles stimulés ! \(hashtag)\n\(url)",
            de: "Ganzkörper bezwungen! Alle 21 Muskeln stimuliert! \(hashtag)\n\(url)")
    }
    static var fullBodyConquestAgain: String { loc("再び全身制覇！", "Full Body Again!", zhHans: "再次全身征服！", ko: "다시 전신 정복!", es: "¡Cuerpo completo otra vez!", fr: "Corps entier à nouveau !", de: "Ganzkörper erneut!") }
    static func conquestCount(_ count: Int) -> String {
        loc("累計\(count)回達成", "\(count) times achieved", zhHans: "累计达成\(count)次", ko: "총 \(count)회 달성", es: "\(count) veces logrado", fr: "\(count) fois atteint", de: "\(count) mal erreicht")
    }

    // MARK: - 週間サマリー
    static var weeklySummary: String { loc("週間サマリー", "Weekly Summary", zhHans: "每周总结", ko: "주간 요약", es: "Resumen semanal", fr: "Résumé hebdomadaire", de: "Wochenzusammenfassung") }
    static var weeklyReport: String { loc("WEEKLY REPORT", "WEEKLY REPORT", zhHans: "每周报告", ko: "주간 리포트", es: "INFORME SEMANAL", fr: "RAPPORT HEBDOMADAIRE", de: "WOCHENBERICHT") }
    static var workouts: String { loc("ワークアウト", "Workouts", zhHans: "训练", ko: "운동", es: "Entrenamientos", fr: "Entraînements", de: "Trainings") }
    static var volumeKg: String { loc("ボリューム(kg)", "Volume (kg)", zhHans: "训练量(kg)", ko: "볼륨(kg)", es: "Volumen (kg)", fr: "Volume (kg)", de: "Volumen (kg)") }
    static var mvpMuscle: String { loc("今週のMVP", "This Week's MVP", zhHans: "本周MVP", ko: "이번 주 MVP", es: "MVP de la semana", fr: "MVP de la semaine", de: "MVP der Woche") }
    static func stimulatedTimes(_ count: Int) -> String {
        loc("\(count)回刺激", "\(count) times stimulated", zhHans: "刺激\(count)次", ko: "\(count)회 자극", es: "\(count) veces estimulado", fr: "\(count) fois stimulé", de: "\(count) mal stimuliert")
    }
    static var noWorkoutThisWeekYet: String { loc("今週はまだワークアウトなし", "No workouts this week yet", zhHans: "本周还没有训练", ko: "이번 주 아직 운동 없음", es: "Sin entrenamientos esta semana", fr: "Pas d'entraînement cette semaine", de: "Noch kein Training diese Woche") }
    static var lazyMuscle: String { loc("来週の宿題", "Next Week's Homework", zhHans: "下周作业", ko: "다음 주 숙제", es: "Tarea de la próxima semana", fr: "Devoirs de la semaine prochaine", de: "Hausaufgabe nächste Woche") }
    static var noLazyMuscles: String { loc("サボりなし！", "No slacking!", zhHans: "没有偷懒！", ko: "빠짐없이 완료!", es: "¡Sin descuidar!", fr: "Aucun muscle négligé !", de: "Nichts ausgelassen!") }
    static var nextWeekHomework: String { loc("来週こそ鍛えよう", "Train these next week", zhHans: "下周一定要练", ko: "다음 주엔 꼭 운동하자", es: "Entrena estos la próxima semana", fr: "Entraînez-les la semaine prochaine", de: "Nächste Woche trainieren") }
    static var currentStreak: String { loc("継続記録", "Current Streak", zhHans: "连续记录", ko: "연속 기록", es: "Racha actual", fr: "Série en cours", de: "Aktuelle Serie") }
    static var noStreakYet: String { loc("まだ記録なし", "No streak yet", zhHans: "尚无记录", ko: "아직 기록 없음", es: "Sin racha aún", fr: "Pas encore de série", de: "Noch keine Serie") }
    static var noSlacking: String { loc("完璧！", "Perfect!", zhHans: "完美！", ko: "완벽!", es: "¡Perfecto!", fr: "Parfait !", de: "Perfekt!") }
    static var homework: String { loc("宿題", "Homework", zhHans: "作业", ko: "숙제", es: "Tarea", fr: "Devoirs", de: "Hausaufgabe") }
    static var weeksStreak: String { loc("週連続", "weeks", zhHans: "周连续", ko: "주 연속", es: "semanas", fr: "semaines", de: "Wochen") }
    static func weeklySummaryShareText(_ range: String, _ hashtag: String, _ url: String) -> String {
        loc("今週のトレーニング結果 \(range)\n\(hashtag)\n\(url)",
            "This week's training results \(range)\n\(hashtag)\n\(url)",
            zhHans: "本周训练成果 \(range)\n\(hashtag)\n\(url)",
            ko: "이번 주 트레이닝 결과 \(range)\n\(hashtag)\n\(url)",
            es: "Resultados de esta semana \(range)\n\(hashtag)\n\(url)",
            fr: "Résultats de la semaine \(range)\n\(hashtag)\n\(url)",
            de: "Trainingsergebnisse dieser Woche \(range)\n\(hashtag)\n\(url)")
    }

    // MARK: - 筋肉バランス診断
    static var muscleBalanceDiagnosis: String { loc("筋肉バランス診断", "Muscle Balance Diagnosis", zhHans: "肌肉平衡诊断", ko: "근육 밸런스 진단", es: "Diagnóstico de equilibrio muscular", fr: "Diagnostic d'équilibre musculaire", de: "Muskelbalance-Diagnose") }
    static var diagnosisCardSubtitle: String { loc("あなたのトレーニングタイプを分析", "Analyze your training type", zhHans: "分析你的训练类型", ko: "당신의 트레이닝 유형을 분석", es: "Analiza tu tipo de entrenamiento", fr: "Analysez votre type d'entraînement", de: "Analysiere deinen Trainingstyp") }
    static var diagnosisDescription: String {
        loc("過去のワークアウトデータを分析し、あなたのトレーニングタイプと筋肉バランスを診断します",
            "Analyze your workout history to diagnose your training type and muscle balance",
            zhHans: "分析你的训练历史，诊断训练类型和肌肉平衡",
            ko: "과거 운동 데이터를 분석하여 트레이닝 유형과 근육 밸런스를 진단합니다",
            es: "Analiza tu historial para diagnosticar tu tipo de entrenamiento y equilibrio muscular",
            fr: "Analysez votre historique pour diagnostiquer votre type d'entraînement et équilibre musculaire",
            de: "Analysiere dein Trainingshistorie für Trainingstyp und Muskelbalance")
    }
    static var startDiagnosis: String { loc("診断を開始", "Start Diagnosis", zhHans: "开始诊断", ko: "진단 시작", es: "Iniciar diagnóstico", fr: "Commencer le diagnostic", de: "Diagnose starten") }
    static var analyzing: String { loc("分析中...", "Analyzing...", zhHans: "分析中...", ko: "분석 중...", es: "Analizando...", fr: "Analyse en cours...", de: "Analysiere...") }
    static var analyzingSubtitle: String { loc("ワークアウト履歴を解析しています", "Processing your workout history", zhHans: "正在处理训练历史", ko: "운동 기록을 분석하고 있습니다", es: "Procesando tu historial de entrenamientos", fr: "Traitement de votre historique", de: "Trainingshistorie wird verarbeitet") }
    static var diagnosisResult: String { loc("診断結果", "Diagnosis Result", zhHans: "诊断结果", ko: "진단 결과", es: "Resultado del diagnóstico", fr: "Résultat du diagnostic", de: "Diagnoseergebnis") }
    static var balanceAnalysis: String { loc("バランス分析", "Balance Analysis", zhHans: "平衡分析", ko: "밸런스 분석", es: "Análisis de equilibrio", fr: "Analyse d'équilibre", de: "Balance-Analyse") }
    static var improvementAdvice: String { loc("改善アドバイス", "Improvement Advice", zhHans: "改善建议", ko: "개선 조언", es: "Consejo de mejora", fr: "Conseil d'amélioration", de: "Verbesserungsrat") }
    static var shareResult: String { loc("結果をシェア", "Share Result", zhHans: "分享结果", ko: "결과 공유", es: "Compartir resultado", fr: "Partager le résultat", de: "Ergebnis teilen") }
    static var retryDiagnosis: String { loc("もう一度診断する", "Run Again", zhHans: "再次诊断", ko: "다시 진단하기", es: "Diagnosticar de nuevo", fr: "Refaire le diagnostic", de: "Erneut diagnostizieren") }
    static var needMoreData: String { loc("より正確な診断のため、あと少しトレーニングデータが必要です", "More workout data needed for accurate diagnosis", zhHans: "需要更多训练数据以进行更准确的诊断", ko: "더 정확한 진단을 위해 더 많은 운동 데이터가 필요합니다", es: "Se necesitan más datos para un diagnóstico preciso", fr: "Plus de données nécessaires pour un diagnostic précis", de: "Mehr Trainingsdaten für genaue Diagnose nötig") }
    static var currentSessions: String { loc("現在のセッション数", "Current Sessions", zhHans: "当前训练次数", ko: "현재 세션 수", es: "Sesiones actuales", fr: "Séances actuelles", de: "Aktuelle Sitzungen") }
    static var balanced: String { loc("バランス良好", "Balanced", zhHans: "平衡良好", ko: "밸런스 양호", es: "Equilibrado", fr: "Équilibré", de: "Ausgewogen") }
    static func sessionsAnalyzed(_ count: Int) -> String {
        loc("\(count)セッション分析", "\(count) sessions analyzed", zhHans: "分析了\(count)次训练", ko: "\(count)세션 분석", es: "\(count) sesiones analizadas", fr: "\(count) séances analysées", de: "\(count) Trainingseinheiten analysiert")
    }
    static var sessionsAnalyzed: String { loc("セッション分析済み", "sessions analyzed", zhHans: "次训练已分析", ko: "세션 분석 완료", es: "sesiones analizadas", fr: "séances analysées", de: "Sitzungen analysiert") }
    static func balanceDiagnosisShareText(_ typeName: String, _ hashtag: String, _ url: String) -> String {
        loc("私のトレーナータイプは「\(typeName)」でした！\(hashtag)\n\(url)",
            "My trainer type is \"\(typeName)\"! \(hashtag)\n\(url)",
            zhHans: "我的训练类型是「\(typeName)」！\(hashtag)\n\(url)",
            ko: "나의 트레이너 유형은 \"\(typeName)\"입니다! \(hashtag)\n\(url)",
            es: "¡Mi tipo de entrenamiento es \"\(typeName)\"! \(hashtag)\n\(url)",
            fr: "Mon type d'entraînement est « \(typeName) » ! \(hashtag)\n\(url)",
            de: "Mein Trainingstyp ist \"\(typeName)\"! \(hashtag)\n\(url)")
    }

    // バランス軸
    static var upperBody: String { loc("上半身", "Upper Body", zhHans: "上半身", ko: "상체", es: "Tren superior", fr: "Haut du corps", de: "Oberkörper") }
    static var lowerBody: String { loc("下半身", "Lower Body", zhHans: "下半身", ko: "하체", es: "Tren inferior", fr: "Bas du corps", de: "Unterkörper") }
    static var frontSide: String { loc("前面", "Front", zhHans: "前侧", ko: "전면", es: "Frontal", fr: "Avant", de: "Vorne") }
    static var backSide: String { loc("背面", "Back", zhHans: "后侧", ko: "후면", es: "Posterior", fr: "Arrière", de: "Hinten") }
    static var pushType: String { loc("プッシュ", "Push", zhHans: "推", ko: "푸시", es: "Empuje", fr: "Poussée", de: "Drücken") }
    static var pullType: String { loc("プル", "Pull", zhHans: "拉", ko: "풀", es: "Tirón", fr: "Traction", de: "Ziehen") }
    static var coreType: String { loc("体幹", "Core", zhHans: "核心", ko: "코어", es: "Core", fr: "Core", de: "Core") }
    static var limbType: String { loc("四肢", "Limbs", zhHans: "四肢", ko: "사지", es: "Extremidades", fr: "Membres", de: "Gliedmaßen") }

    // トレーナータイプ名
    static var typeMirrorMuscle: String { loc("ミラーマッスル型", "Mirror Muscle Type", zhHans: "镜面肌肉型", ko: "거울 근육 타입", es: "Tipo Músculo Espejo", fr: "Type Muscles Miroir", de: "Spiegelmuskel-Typ") }
    static var typeBalanceMaster: String { loc("バランスマスター型", "Balance Master Type", zhHans: "平衡大师型", ko: "밸런스 마스터 타입", es: "Tipo Maestro del Equilibrio", fr: "Type Maître de l'Équilibre", de: "Balance-Meister-Typ") }
    static var typeLegDayNeverSkip: String { loc("レッグデイ・ネバースキップ型", "Leg Day Never Skip Type", zhHans: "从不跳过腿日型", ko: "레그데이 절대 안 빠짐 타입", es: "Tipo Nunca Salto Pierna", fr: "Type Jamais Sans Jambes", de: "Niemals-Leg-Day-Skippen-Typ") }
    static var typeBackAttack: String { loc("バックアタック型", "Back Attack Type", zhHans: "背部攻击型", ko: "백 어택 타입", es: "Tipo Ataque de Espalda", fr: "Type Attaque Dorsale", de: "Rücken-Attacke-Typ") }
    static var typeCoreMaster: String { loc("体幹番長型", "Core Master Type", zhHans: "核心大师型", ko: "코어 마스터 타입", es: "Tipo Maestro del Core", fr: "Type Maître du Core", de: "Core-Meister-Typ") }
    static var typeArmDayEveryDay: String { loc("アームデイ・エブリデイ型", "Arm Day Every Day Type", zhHans: "每天练臂型", ko: "팔 운동 매일 타입", es: "Tipo Brazos Todos los Días", fr: "Type Bras Tous les Jours", de: "Jeden-Tag-Arm-Tag-Typ") }
    static var typePushCrazy: String { loc("プッシュ狂い型", "Push Crazy Type", zhHans: "疯狂推举型", ko: "푸시 미친 타입", es: "Tipo Loco por Empujar", fr: "Type Fou de Poussée", de: "Push-Verrückt-Typ") }
    static var typeFullBodyConqueror: String { loc("全身制覇型", "Full Body Conqueror Type", zhHans: "全身征服型", ko: "전신 정복 타입", es: "Tipo Conquistador Total", fr: "Type Conquérant Total", de: "Ganzkörper-Eroberer-Typ") }
    static var typeDataInsufficient: String { loc("データ不足", "Data Insufficient", zhHans: "数据不足", ko: "데이터 부족", es: "Datos insuficientes", fr: "Données insuffisantes", de: "Unzureichende Daten") }

    // トレーナータイプ説明
    static var descMirrorMuscle: String {
        loc("胸・肩・腕など、鏡に映る筋肉を重点的に鍛えるタイプです",
            "You focus on muscles visible in the mirror: chest, shoulders, and arms",
            zhHans: "你重点锻炼镜子里看得到的肌肉：胸、肩、手臂",
            ko: "가슴, 어깨, 팔 등 거울에 보이는 근육을 중점적으로 단련하는 타입",
            es: "Te enfocas en músculos visibles al espejo: pecho, hombros y brazos",
            fr: "Vous ciblez les muscles visibles dans le miroir : pectoraux, épaules et bras",
            de: "Du fokussierst auf Spiegelmuskeln: Brust, Schultern und Arme")
    }
    static var descBalanceMaster: String {
        loc("全身をバランスよく鍛えられています。理想的なトレーニングです！",
            "You train your entire body in perfect balance. Ideal training!",
            zhHans: "你全身锻炼非常均衡，理想的训练方式！",
            ko: "전신을 균형 있게 단련하고 있습니다. 이상적인 트레이닝!",
            es: "Entrenas todo el cuerpo en perfecto equilibrio. ¡Ideal!",
            fr: "Vous entraînez tout le corps en parfait équilibre. Idéal !",
            de: "Du trainierst den ganzen Körper in perfekter Balance. Ideal!")
    }
    static var descLegDayNeverSkip: String {
        loc("下半身を重点的に鍛えるタイプです。脚の日を欠かしません！",
            "You emphasize lower body training. Never skip leg day!",
            zhHans: "你重点锻炼下半身，从不跳过腿日！",
            ko: "하체를 중점적으로 단련하는 타입. 레그데이를 절대 안 빠뜁니다!",
            es: "Enfatizas el tren inferior. ¡Nunca saltas el día de piernas!",
            fr: "Vous privilégiez le bas du corps. Jamais sans jour jambes !",
            de: "Du fokussierst auf Unterkörper-Training. Leg Day wird nie übersprungen!")
    }
    static var descBackAttack: String {
        loc("背中を重点的に鍛えるタイプです。引く動作が得意です",
            "You focus on back training. Great at pulling movements",
            zhHans: "你重点锻炼背部，擅长拉的动作",
            ko: "등을 중점적으로 단련하는 타입. 당기는 동작이 특기",
            es: "Te enfocas en la espalda. Genial en movimientos de tirón",
            fr: "Vous ciblez le dos. Excellent en mouvements de traction",
            de: "Du fokussierst auf Rückentraining. Stark bei Zugbewegungen")
    }
    static var descCoreMaster: String {
        loc("体幹を重点的に鍛えるタイプです。安定性を重視しています",
            "You emphasize core training. Stability is your priority",
            zhHans: "你重点锻炼核心，注重稳定性",
            ko: "코어를 중점적으로 단련하는 타입. 안정성을 중시",
            es: "Enfatizas el core. La estabilidad es tu prioridad",
            fr: "Vous privilégiez le core. La stabilité est votre priorité",
            de: "Du fokussierst auf Core-Training. Stabilität hat Priorität")
    }
    static var descArmDayEveryDay: String {
        loc("腕を重点的に鍛えるタイプです。二頭・三頭が大好き！",
            "You focus on arm training. Love those biceps and triceps!",
            zhHans: "你重点锻炼手臂，超爱二头和三头！",
            ko: "팔을 중점적으로 단련하는 타입. 이두근·삼두근을 사랑!",
            es: "Te enfocas en los brazos. ¡Amas bíceps y tríceps!",
            fr: "Vous ciblez les bras. Biceps et triceps adorés !",
            de: "Du fokussierst auf Armtraining. Bizeps und Trizeps sind dein Ding!")
    }
    static var descPushCrazy: String {
        loc("押す動作を重点的に行うタイプです。プレス系が得意です",
            "You focus on pushing movements. Great at pressing exercises",
            zhHans: "你重点进行推的动作，擅长推举类动作",
            ko: "밀기 동작을 중점적으로 하는 타입. 프레스 계열이 특기",
            es: "Te enfocas en empujar. Genial en ejercicios de press",
            fr: "Vous ciblez les mouvements de poussée. Excellent en press",
            de: "Du fokussierst auf Druckbewegungen. Stark bei Pressübungen")
    }
    static var descFullBodyConqueror: String {
        loc("全身をまんべんなく高頻度で鍛えています。素晴らしい！",
            "You train your entire body frequently and evenly. Amazing!",
            zhHans: "你高频率地均匀锻炼全身，太棒了！",
            ko: "전신을 고르게 높은 빈도로 단련하고 있습니다. 대단해!",
            es: "Entrenas todo el cuerpo con frecuencia y equilibrio. ¡Increíble!",
            fr: "Vous entraînez tout le corps fréquemment et uniformément. Incroyable !",
            de: "Du trainierst den ganzen Körper häufig und gleichmäßig. Fantastisch!")
    }
    static var descDataInsufficient: String {
        loc("診断には10セッション以上のデータが必要です",
            "At least 10 sessions needed for diagnosis",
            zhHans: "诊断需要至少10次训练数据",
            ko: "진단에는 10세션 이상의 데이터가 필요합니다",
            es: "Se necesitan al menos 10 sesiones para el diagnóstico",
            fr: "Au moins 10 séances nécessaires pour le diagnostic",
            de: "Mindestens 10 Sitzungen für die Diagnose nötig")
    }

    // トレーナータイプアドバイス
    static var adviceMirrorMuscle: String {
        loc("背中と下半身のトレーニングを増やすと、より バランスの取れた体を作れます。特にデッドリフトやスクワットがおすすめです。",
            "Add more back and leg training for a balanced physique. Deadlifts and squats are highly recommended.",
            zhHans: "增加背部和腿部训练可以打造更均衡的体型。推荐硬拉和深蹲。",
            ko: "등과 하체 운동을 늘리면 더 균형 잡힌 몸을 만들 수 있습니다. 데드리프트와 스쿼트를 추천합니다.",
            es: "Añade más espalda y piernas para un físico equilibrado. Se recomiendan peso muerto y sentadillas.",
            fr: "Ajoutez du dos et des jambes pour un physique équilibré. Soulevé de terre et squats recommandés.",
            de: "Mehr Rücken- und Beintraining für einen ausgewogenen Körper. Kreuzheben und Kniebeugen empfohlen.")
    }
    static var adviceBalanceMaster: String {
        loc("このまま続けてください！次のステップとして、弱点部位をさらに強化するか、新しい種目に挑戦してみましょう。",
            "Keep it up! Next step: strengthen any weak points or try new exercises.",
            zhHans: "继续保持！下一步：进一步强化弱点或尝试新动作。",
            ko: "계속 이어가세요! 다음 단계: 약점 부위를 더 강화하거나 새로운 종목에 도전하세요.",
            es: "¡Sigue así! Siguiente paso: refuerza puntos débiles o prueba nuevos ejercicios.",
            fr: "Continuez ainsi ! Prochaine étape : renforcez vos points faibles ou essayez de nouveaux exercices.",
            de: "Weiter so! Nächster Schritt: Schwachstellen stärken oder neue Übungen ausprobieren.")
    }
    static var adviceLegDayNeverSkip: String {
        loc("素晴らしい下半身の意識です！上半身、特に背中や胸のトレーニングも取り入れると、さらにバランスが良くなります。",
            "Great lower body focus! Add upper body work, especially back and chest, for better balance.",
            zhHans: "很好的下半身意识！加入上半身训练，特别是背部和胸部，以获得更好的平衡。",
            ko: "훌륭한 하체 의식! 상체, 특히 등과 가슴 운동도 추가하면 더 균형이 좋아집니다.",
            es: "¡Gran enfoque en piernas! Añade tren superior, especialmente espalda y pecho.",
            fr: "Excellent focus sur le bas du corps ! Ajoutez du haut du corps, surtout dos et pectoraux.",
            de: "Toller Unterkörper-Fokus! Oberkörper hinzufügen, besonders Rücken und Brust.")
    }
    static var adviceBackAttack: String {
        loc("背中の発達は素晴らしい！胸やプッシュ系の種目を追加して、前後のバランスを整えましょう。",
            "Great back development! Add chest and push exercises to balance front and back.",
            zhHans: "背部发展很棒！加入胸部和推的动作来平衡前后。",
            ko: "등 발달이 훌륭합니다! 가슴과 푸시 계열 종목을 추가하여 전후 밸런스를 맞추세요.",
            es: "¡Gran desarrollo de espalda! Añade pecho y empujes para equilibrar frente y atrás.",
            fr: "Super développement du dos ! Ajoutez pectoraux et poussées pour l'équilibre avant-arrière.",
            de: "Tolle Rückenentwicklung! Brust und Druckübungen für Vorne-Hinten-Balance hinzufügen.")
    }
    static var adviceCoreMaster: String {
        loc("体幹の強さは全ての基礎です。四肢（腕・脚）のトレーニングも増やして、パワーを活かしましょう。",
            "Core strength is fundamental. Add more limb training to utilize that power.",
            zhHans: "核心力量是一切的基础。增加四肢训练来发挥这种力量。",
            ko: "코어 강도는 모든 것의 기초입니다. 사지(팔·다리) 운동도 늘려 파워를 활용하세요.",
            es: "La fuerza del core es fundamental. Añade más extremidades para aprovechar ese poder.",
            fr: "La force du core est fondamentale. Ajoutez plus de membres pour exploiter cette puissance.",
            de: "Core-Stärke ist fundamental. Mehr Gliedmaßen-Training, um diese Kraft zu nutzen.")
    }
    static var adviceArmDayEveryDay: String {
        loc("腕の成長には大筋群も重要です。胸・背中・脚のコンパウンド種目を増やすと、腕もさらに発達します。",
            "Big muscles help arm growth. Add compound exercises for chest, back, and legs.",
            zhHans: "大肌群对手臂增长也很重要。增加胸、背、腿的复合动作，手臂也会更加发达。",
            ko: "팔 성장에는 대근육도 중요합니다. 가슴·등·다리의 복합 종목을 늘리면 팔도 더 발달합니다.",
            es: "Los músculos grandes ayudan al crecimiento de brazos. Añade compuestos de pecho, espalda y piernas.",
            fr: "Les gros muscles aident les bras. Ajoutez des exercices composés pour pectoraux, dos et jambes.",
            de: "Große Muskeln helfen beim Armwachstum. Compound-Übungen für Brust, Rücken und Beine hinzufügen.")
    }
    static var advicePushCrazy: String {
        loc("プル系（引く動作）を増やしましょう。ローイングやプルダウンで背中を鍛えると、姿勢も良くなります。",
            "Add more pulling movements. Rows and pulldowns will improve your posture too.",
            zhHans: "增加拉的动作吧。划船和下拉训练背部，还能改善姿势。",
            ko: "풀 계열(당기기 동작)을 늘리세요. 로잉과 풀다운으로 등을 단련하면 자세도 좋아집니다.",
            es: "Añade más movimientos de tirón. Remos y jalones mejorarán tu postura también.",
            fr: "Ajoutez plus de tractions. Rameurs et tirages amélioreront aussi votre posture.",
            de: "Mehr Zugbewegungen hinzufügen. Rudern und Pulldowns verbessern auch die Haltung.")
    }
    static var adviceFullBodyConqueror: String {
        loc("完璧なバランスです！さらなる成長のために、各部位のボリュームを徐々に増やしていきましょう。",
            "Perfect balance! For more growth, gradually increase volume for each muscle group.",
            zhHans: "完美的平衡！为了进一步成长，逐步增加每个部位的训练量吧。",
            ko: "완벽한 밸런스! 더 성장하기 위해 각 부위의 볼륨을 점진적으로 늘려봅시다.",
            es: "¡Equilibrio perfecto! Para más crecimiento, aumenta gradualmente el volumen por grupo muscular.",
            fr: "Équilibre parfait ! Pour progresser, augmentez graduellement le volume par groupe musculaire.",
            de: "Perfekte Balance! Für mehr Wachstum schrittweise das Volumen pro Muskelgruppe steigern.")
    }
    static var adviceDataInsufficient: String {
        loc("もう少しトレーニングを記録してから診断をお試しください。毎回のワークアウトを記録することで、より正確な分析が可能になります。",
            "Record more workouts before trying again. Logging every session enables more accurate analysis.",
            zhHans: "请多记录一些训练后再尝试诊断。记录每次训练可以实现更准确的分析。",
            ko: "더 많은 운동을 기록한 후 다시 시도하세요. 매번 운동을 기록하면 더 정확한 분석이 가능합니다.",
            es: "Registra más entrenamientos antes de intentar de nuevo. Registrar cada sesión permite un análisis más preciso.",
            fr: "Enregistrez plus d'entraînements avant de réessayer. Chaque séance enregistrée améliore l'analyse.",
            de: "Mehr Trainings aufzeichnen, bevor du es erneut versuchst. Jede aufgezeichnete Sitzung verbessert die Analyse.")
    }

    // MARK: - マッスル・ジャーニー
    static var muscleJourney: String { loc("マッスル・ジャーニー", "Muscle Journey", zhHans: "肌肉旅程", ko: "머슬 저니", es: "Viaje Muscular", fr: "Parcours Musculaire", de: "Muskelreise") }
    static var journeyCardSubtitle: String { loc("過去と現在を比較", "Compare past and present", zhHans: "比较过去和现在", ko: "과거와 현재 비교", es: "Compara pasado y presente", fr: "Comparez passé et présent", de: "Vergangenheit und Gegenwart vergleichen") }
    static var oneMonthAgo: String { loc("1ヶ月前", "1 month ago", zhHans: "1个月前", ko: "1개월 전", es: "Hace 1 mes", fr: "Il y a 1 mois", de: "Vor 1 Monat") }
    static var threeMonthsAgo: String { loc("3ヶ月前", "3 months ago", zhHans: "3个月前", ko: "3개월 전", es: "Hace 3 meses", fr: "Il y a 3 mois", de: "Vor 3 Monaten") }
    static var sixMonthsAgo: String { loc("6ヶ月前", "6 months ago", zhHans: "6个月前", ko: "6개월 전", es: "Hace 6 meses", fr: "Il y a 6 mois", de: "Vor 6 Monaten") }
    static var oneYearAgo: String { loc("1年前", "1 year ago", zhHans: "1年前", ko: "1년 전", es: "Hace 1 año", fr: "Il y a 1 an", de: "Vor 1 Jahr") }
    static var customDate: String { loc("カスタム", "Custom", zhHans: "自定义", ko: "사용자 지정", es: "Personalizado", fr: "Personnalisé", de: "Benutzerdefiniert") }
    static var now: String { loc("現在", "Now", zhHans: "现在", ko: "현재", es: "Ahora", fr: "Maintenant", de: "Jetzt") }
    static var selectDate: String { loc("日付を選択", "Select Date", zhHans: "选择日期", ko: "날짜 선택", es: "Seleccionar fecha", fr: "Sélectionner la date", de: "Datum auswählen") }
    static var changeSummary: String { loc("変化のサマリー", "Change Summary", zhHans: "变化总结", ko: "변화 요약", es: "Resumen de cambios", fr: "Résumé des changements", de: "Änderungszusammenfassung") }
    static var newlyStimulated: String { loc("新たに刺激した部位", "Newly Stimulated", zhHans: "新刺激的部位", ko: "새로 자극한 부위", es: "Recién estimulados", fr: "Nouvellement stimulés", de: "Neu stimuliert") }
    static var mostImproved: String { loc("最も改善した部位", "Most Improved", zhHans: "改善最多的部位", ko: "가장 개선된 부위", es: "Más mejorado", fr: "Plus amélioré", de: "Am meisten verbessert") }
    static var stillNeglected: String { loc("まだ未刺激の部位", "Still Neglected", zhHans: "仍未锻炼的部位", ko: "아직 미자극인 부위", es: "Aún descuidados", fr: "Encore négligés", de: "Immer noch vernachlässigt") }
    static func countParts(_ count: Int) -> String {
        loc("\(count)部位", "\(count) parts", zhHans: "\(count)个部位", ko: "\(count)부위", es: "\(count) partes", fr: "\(count) parties", de: "\(count) Bereiche")
    }
    static var noDataForPeriod: String { loc("この期間のデータがありません", "No data for this period", zhHans: "此期间无数据", ko: "이 기간의 데이터가 없습니다", es: "Sin datos para este periodo", fr: "Aucune donnée pour cette période", de: "Keine Daten für diesen Zeitraum") }
    static var newMuscles: String { loc("新規部位", "New Muscles", zhHans: "新部位", ko: "새 부위", es: "Nuevos músculos", fr: "Nouveaux muscles", de: "Neue Muskeln") }
    static func journeyShareText(_ progress: String, _ hashtag: String, _ url: String) -> String {
        loc("私の筋肉の成長記録！\(progress)\n\(hashtag)\n\(url)",
            "My muscle growth journey! \(progress)\n\(hashtag)\n\(url)",
            zhHans: "我的肌肉成长记录！\(progress)\n\(hashtag)\n\(url)",
            ko: "나의 근육 성장 기록! \(progress)\n\(hashtag)\n\(url)",
            es: "¡Mi viaje de crecimiento muscular! \(progress)\n\(hashtag)\n\(url)",
            fr: "Mon parcours de croissance musculaire ! \(progress)\n\(hashtag)\n\(url)",
            de: "Meine Muskelwachstums-Reise! \(progress)\n\(hashtag)\n\(url)")
    }

    // MARK: - 未刺激警告シェア
    static var shareShame: String { loc("恥を晒す 😱", "Share my shame 😱", zhHans: "晒出我的耻辱 😱", ko: "부끄러움을 공유 😱", es: "Compartir mi vergüenza 😱", fr: "Partager ma honte 😱", de: "Meine Schande teilen 😱") }
    static var neglectedShareSubtitle: String { loc("サボってます...", "Slacking off...", zhHans: "在偷懒...", ko: "빠먹고 있어요...", es: "Descuidando...", fr: "Je me relâche...", de: "Ich faulenze...") }
    static func daysNeglected(_ days: Int) -> String {
        loc("\(days)日放置", "\(days) days neglected", zhHans: "已\(days)天未练", ko: "\(days)일 방치", es: "\(days) días descuidado", fr: "\(days) jours négligé", de: "\(days) Tage vernachlässigt")
    }
    static func neglectedShareText(_ muscle: String, _ days: Int, _ hashtag: String, _ url: String) -> String {
        loc("\(muscle)を\(days)日間サボってます...誰か叱ってください 😭 \(hashtag)\n\(url)",
            "I've been neglecting my \(muscle) for \(days) days... someone scold me 😭 \(hashtag)\n\(url)",
            zhHans: "已经\(days)天没练\(muscle)了...谁来骂我一顿 😭 \(hashtag)\n\(url)",
            ko: "\(muscle)을(를) \(days)일 동안 빠먹고 있어요... 누가 혼내주세요 😭 \(hashtag)\n\(url)",
            es: "Llevo \(days) días sin entrenar \(muscle)... alguien regáñame 😭 \(hashtag)\n\(url)",
            fr: "Je néglige mes \(muscle) depuis \(days) jours... quelqu'un grondez-moi 😭 \(hashtag)\n\(url)",
            de: "Ich vernachlässige meine \(muscle) seit \(days) Tagen... schimpft mich bitte 😭 \(hashtag)\n\(url)")
    }

    // MARK: - トレーニングヒートマップ
    static var trainingHeatmap: String { loc("トレーニングヒートマップ", "Training Heatmap", zhHans: "训练热力图", ko: "트레이닝 히트맵", es: "Mapa de calor de entrenamiento", fr: "Carte thermique d'entraînement", de: "Training-Heatmap") }
    static var heatmapCardSubtitle: String { loc("GitHubの草のようにトレーニングを可視化", "Visualize training like GitHub contributions", zhHans: "像GitHub贡献图一样可视化训练", ko: "GitHub 잔디처럼 트레이닝을 시각화", es: "Visualiza entrenamientos como contribuciones de GitHub", fr: "Visualisez l'entraînement comme les contributions GitHub", de: "Training wie GitHub-Beiträge visualisieren") }
    static var less: String { loc("少ない", "Less", zhHans: "少", ko: "적음", es: "Menos", fr: "Moins", de: "Weniger") }
    static var more: String { loc("多い", "More", zhHans: "多", ko: "많음", es: "Más", fr: "Plus", de: "Mehr") }
    static var trainingDaysLabel: String { loc("トレーニング日数", "Training Days", zhHans: "训练天数", ko: "트레이닝 일수", es: "Días de entrenamiento", fr: "Jours d'entraînement", de: "Trainingstage") }
    static var days: String { loc("日", "days", zhHans: "天", ko: "일", es: "días", fr: "jours", de: "Tage") }
    static var longestStreak: String { loc("最長連続", "Longest Streak", zhHans: "最长连续", ko: "최장 연속", es: "Racha más larga", fr: "Plus longue série", de: "Längste Serie") }
    static var averagePerWeek: String { loc("週平均", "Weekly Average", zhHans: "周平均", ko: "주 평균", es: "Promedio semanal", fr: "Moyenne hebdomadaire", de: "Wochendurchschnitt") }
    static var timesPerWeek: String { loc("回/週", "times/week", zhHans: "次/周", ko: "회/주", es: "veces/semana", fr: "fois/semaine", de: "mal/Woche") }
    static func heatmapShareText(_ trainingDays: Int, _ hashtag: String, _ url: String) -> String {
        loc("\(trainingDays)日間トレーニングを積み重ねています！\(hashtag)\n\(url)",
            "I've trained for \(trainingDays) days! \(hashtag)\n\(url)",
            zhHans: "我已经训练了\(trainingDays)天！\(hashtag)\n\(url)",
            ko: "\(trainingDays)일간 트레이닝을 쌓아왔습니다! \(hashtag)\n\(url)",
            es: "¡He entrenado durante \(trainingDays) días! \(hashtag)\n\(url)",
            fr: "J'ai entraîné pendant \(trainingDays) jours ! \(hashtag)\n\(url)",
            de: "Ich habe \(trainingDays) Tage trainiert! \(hashtag)\n\(url)")
    }

    // MARK: - 次回おすすめ日
    static var nextRecommendedDay: String { loc("次回おすすめ日", "Next Best Day", zhHans: "下次推荐日", ko: "다음 추천일", es: "Próximo mejor día", fr: "Prochain jour idéal", de: "Nächster bester Tag") }
    static func nextBestDateLabel(_ dateStr: String) -> String {
        loc("\(dateStr)がベスト", "\(dateStr) is best", zhHans: "\(dateStr)最佳", ko: "\(dateStr)이 최적", es: "\(dateStr) es ideal", fr: "\(dateStr) est idéal", de: "\(dateStr) ist ideal")
    }
    static var basedOnRecoveryPrediction: String { loc("今日の刺激部位の回復予測から算出", "Based on recovery prediction for today's muscles", zhHans: "基于今日锻炼肌肉恢复预测", ko: "오늘 자극한 근육 회복 예측 기준", es: "Basado en la predicción de recuperación", fr: "Basé sur la prédiction de récupération", de: "Basierend auf der Erholungsprognose") }
    static var tomorrow: String { loc("明日", "Tomorrow", zhHans: "明天", ko: "내일", es: "Mañana", fr: "Demain", de: "Morgen") }
    static var today: String { loc("今日", "Today", zhHans: "今天", ko: "오늘", es: "Hoy", fr: "Aujourd'hui", de: "Heute") }

    // MARK: - Strength Mapシェア
    static var prUpdated: String { loc("PR更新！", "PR Updated!", zhHans: "PR刷新！", ko: "PR 갱신!", es: "¡PR actualizado!", fr: "PR mis à jour !", de: "PR aktualisiert!") }
    static var shareStrengthMap: String { loc("Strength Mapをシェア", "Share Strength Map", zhHans: "分享力量图", ko: "Strength Map 공유", es: "Compartir Strength Map", fr: "Partager Strength Map", de: "Strength Map teilen") }

    // MARK: - Strength Mapバナー（Proチラ見せ）
    static var strengthMapBannerTitle: String { loc("Strength Map — あなたの筋力を可視化", "Strength Map — Visualize Your Strength", zhHans: "Strength Map — 可视化您的力量", ko: "Strength Map — 근력 시각화", es: "Strength Map — Visualiza Tu Fuerza", fr: "Strength Map — Visualisez Votre Force", de: "Strength Map — Visualisiere Deine Kraft") }
    static var unlockWithPro: String { loc("Pro でアンロック", "Unlock with Pro", zhHans: "通过 Pro 解锁", ko: "Pro로 잠금 해제", es: "Desbloquear con Pro", fr: "Débloquer avec Pro", de: "Mit Pro freischalten") }

    // MARK: - 種目別推移グラフ（Proロック）
    static var exerciseTrendTitle: String { loc("種目別推移グラフ", "Exercise Trend Graph", zhHans: "动作趋势图", ko: "종목별 추이 그래프", es: "Gráfico de tendencia", fr: "Graphique de tendance", de: "Übungstrend") }

    // MARK: - 統計・分析メニュー
    static var analyticsMenu: String { loc("統計・分析", "Analytics", zhHans: "统计与分析", ko: "통계·분석", es: "Estadísticas", fr: "Analyses", de: "Statistiken") }
    static var viewStats: String { loc("統計を見る", "View Stats", zhHans: "查看统计", ko: "통계 보기", es: "Ver estadísticas", fr: "Voir les stats", de: "Statistiken ansehen") }
    static var weeklySummaryDescription: String { loc("今週のトレーニング成果を確認", "Review this week's training results", zhHans: "查看本周训练成果", ko: "이번 주 트레이닝 성과 확인", es: "Revisa los resultados de esta semana", fr: "Consultez les résultats de la semaine", de: "Trainingsergebnisse dieser Woche ansehen") }
    static var balanceDiagnosis: String { loc("筋肉バランス診断", "Balance Diagnosis", zhHans: "肌肉平衡诊断", ko: "근육 밸런스 진단", es: "Diagnóstico de equilibrio", fr: "Diagnostic d'équilibre", de: "Balance-Diagnose") }
    static var balanceDiagnosisDescription: String { loc("部位ごとの刺激バランスをチェック", "Check stimulation balance by muscle group", zhHans: "检查各部位的刺激平衡", ko: "부위별 자극 밸런스 체크", es: "Comprueba el equilibrio por grupo muscular", fr: "Vérifiez l'équilibre par groupe musculaire", de: "Stimulationsbalance nach Muskelgruppe prüfen") }
    static var startFirstWorkout: String { loc("最初のワークアウトを記録しよう！", "Start Your First Workout!", zhHans: "记录你的第一次训练！", ko: "첫 운동을 기록하세요!", es: "¡Registra tu primer entrenamiento!", fr: "Enregistrez votre premier entraînement !", de: "Starte dein erstes Training!") }
    static var startWorkout: String { loc("ワークアウトを開始", "Start Workout", zhHans: "开始训练", ko: "운동 시작", es: "Iniciar entrenamiento", fr: "Commencer l'entraînement", de: "Training starten") }
    static var firstWorkoutHint: String { loc("トレーニングを記録すると、ここに統計が表示されます", "Record a workout to see your stats here", zhHans: "记录训练后，统计数据将显示在这里", ko: "운동을 기록하면 여기에 통계가 표시됩니다", es: "Registra un entrenamiento para ver tus estadísticas aquí", fr: "Enregistrez un entraînement pour voir vos stats ici", de: "Training aufzeichnen, um hier Statistiken zu sehen") }

    // MARK: - 種目プレビュー
    static var exerciseInfo: String { loc("種目情報", "Exercise Info", zhHans: "动作信息", ko: "종목 정보", es: "Info del ejercicio", fr: "Info exercice", de: "Übungsinfo") }
    static var primaryTarget: String { loc("メインターゲット", "Primary Target", zhHans: "主要目标", ko: "메인 타겟", es: "Objetivo principal", fr: "Cible principale", de: "Hauptziel") }
    static var secondaryTarget: String { loc("サブターゲット", "Secondary Target", zhHans: "次要目标", ko: "서브 타겟", es: "Objetivo secundario", fr: "Cible secondaire", de: "Nebenziel") }
    static var watchFormVideo: String { loc("フォームを動画で確認", "Watch Form Video", zhHans: "观看姿势视频", ko: "폼 동영상 보기", es: "Ver video de forma", fr: "Voir la vidéo de forme", de: "Formvideo ansehen") }
    static var openInYouTube: String { loc("YouTubeで開く", "Open in YouTube", zhHans: "在YouTube中打开", ko: "YouTube에서 열기", es: "Abrir en YouTube", fr: "Ouvrir dans YouTube", de: "In YouTube öffnen") }
    static var addThisExercise: String { loc("この種目を追加", "Add This Exercise", zhHans: "添加此动作", ko: "이 종목 추가", es: "Añadir este ejercicio", fr: "Ajouter cet exercice", de: "Diese Übung hinzufügen") }
    static var startWorkoutWithExercise: String { loc("この種目でワークアウト開始", "Start Workout with This Exercise", zhHans: "用此动作开始训练", ko: "이 종목으로 운동 시작", es: "Iniciar entrenamiento con este ejercicio", fr: "Commencer l'entraînement avec cet exercice", de: "Training mit dieser Übung starten") }

    // MARK: - ソーシャルフィード
    static var feed: String { loc("フィード", "Feed", zhHans: "动态", ko: "피드", es: "Feed", fr: "Fil", de: "Feed") }
    static var feedComingSoon: String { loc("現在モックデータで表示中 — ソーシャル機能は近日公開", "Showing mock data — Social features coming soon", zhHans: "显示模拟数据 — 社交功能即将上线", ko: "목업 데이터 표시 중 — 소셜 기능 곧 출시", es: "Datos de ejemplo — Funciones sociales próximamente", fr: "Données fictives — Fonctions sociales bientôt", de: "Mockdaten — Soziale Funktionen bald verfügbar") }
    static var feedInviteFriends: String { loc("フレンドを招待", "Invite Friends", zhHans: "邀请好友", ko: "친구 초대", es: "Invitar amigos", fr: "Inviter des amis", de: "Freunde einladen") }
    static var feedInviteSubtitle: String { loc("一緒にトレーニングを記録しよう", "Track workouts together", zhHans: "一起记录训练", ko: "함께 운동을 기록하자", es: "Registra entrenamientos juntos", fr: "Enregistrez vos entraînements ensemble", de: "Trainiert gemeinsam") }
    static func feedInviteMessage(_ url: String) -> String {
        loc("MuscleMapで一緒にトレーニングしよう！ \(url)", "Let's train together on MuscleMap! \(url)", zhHans: "一起用MuscleMap训练吧！ \(url)", ko: "MuscleMap에서 함께 운동하자! \(url)", es: "¡Entrena conmigo en MuscleMap! \(url)", fr: "Entraînons-nous ensemble sur MuscleMap ! \(url)", de: "Lass uns zusammen auf MuscleMap trainieren! \(url)")
    }
    static var feedRecorded: String { loc("を記録 🔥", "recorded 🔥", zhHans: "已记录 🔥", ko: "기록 🔥", es: "registrado 🔥", fr: "enregistré 🔥", de: "aufgezeichnet 🔥") }
    static var feedWorkoutCompleted: String { loc("ワークアウトを完了", "Workout completed", zhHans: "完成训练", ko: "운동 완료", es: "Entrenamiento completado", fr: "Entraînement terminé", de: "Training abgeschlossen") }
    static var feedPRUpdated: String { loc("でPR更新！ 🏆", "— New PR! 🏆", zhHans: "刷新PR！ 🏆", ko: "PR 갱신! 🏆", es: "¡Nuevo PR! 🏆", fr: "Nouveau PR ! 🏆", de: "Neuer PR! 🏆") }
    static var feedPRGeneric: String { loc("自己ベストを更新！", "New personal record!", zhHans: "刷新个人记录！", ko: "개인 기록 갱신!", es: "¡Nuevo récord personal!", fr: "Nouveau record personnel !", de: "Neuer persönlicher Rekord!") }
    static var feedStreakAchieved: String { loc("連続トレーニング記録を達成！ 🎯", "Training streak achieved! 🎯", zhHans: "达成连续训练记录！ 🎯", ko: "연속 트레이닝 달성! 🎯", es: "¡Racha de entrenamiento lograda! 🎯", fr: "Série d'entraînement atteinte ! 🎯", de: "Trainingsserie erreicht! 🎯") }
    static var feedJustNow: String { loc("たった今", "Just now", zhHans: "刚刚", ko: "방금", es: "Ahora mismo", fr: "À l'instant", de: "Gerade eben") }
    static func feedMinutesAgo(_ minutes: Int) -> String {
        loc("\(minutes)分前", "\(minutes)m ago", zhHans: "\(minutes)分钟前", ko: "\(minutes)분 전", es: "Hace \(minutes)m", fr: "Il y a \(minutes)min", de: "Vor \(minutes)Min")
    }
    static func feedHoursAgo(_ hours: Int) -> String {
        loc("\(hours)時間前", "\(hours)h ago", zhHans: "\(hours)小时前", ko: "\(hours)시간 전", es: "Hace \(hours)h", fr: "Il y a \(hours)h", de: "Vor \(hours)Std")
    }
    static func feedDaysAgo(_ days: Int) -> String {
        loc("\(days)日前", "\(days)d ago", zhHans: "\(days)天前", ko: "\(days)일 전", es: "Hace \(days)d", fr: "Il y a \(days)j", de: "Vor \(days)T")
    }

    // MARK: - ワークアウトUX改善
    static var copyLastSet: String { loc("同じ", "Same", zhHans: "同上", ko: "동일", es: "Igual", fr: "Idem", de: "Gleich") }
    static var previousSessionHeader: String { loc("前回の記録", "Previous Session", zhHans: "上次记录", ko: "이전 기록", es: "Sesión anterior", fr: "Session précédente", de: "Letzte Sitzung") }
    static var currentSessionHeader: String { loc("今回", "Current", zhHans: "本次", ko: "이번", es: "Actual", fr: "Actuelle", de: "Aktuell") }
    static var prBadge: String { "PR!" }
    static func recommendedWorkout(_ group: String) -> String {
        loc("今日のおすすめ: \(group)（回復済み）", "Recommended: \(group) (recovered)", zhHans: "今日推荐: \(group)（已恢复）", ko: "추천: \(group) (회복됨)", es: "Recomendado: \(group) (recuperado)", fr: "Recommandé : \(group) (récupéré)", de: "Empfohlen: \(group) (erholt)")
    }
    static var startRecommended: String { loc("おすすめで始める", "Start recommended", zhHans: "按推荐开始", ko: "추천으로 시작", es: "Iniciar recomendado", fr: "Commencer recommandé", de: "Empfohlen starten") }

    // MARK: - 90日チャレンジ
    static var challenge90Title: String { loc("90日チャレンジ", "90-Day Challenge", zhHans: "90天挑战", ko: "90일 챌린지", es: "Desafío de 90 días", fr: "Défi 90 jours", de: "90-Tage-Challenge") }
    static var challenge90Subtitle: String { loc("体の変化を90日で証明しよう", "Prove your body's transformation in 90 days", zhHans: "用90天证明你的蜕变", ko: "90일 동안 몸의 변화를 증명하세요", es: "Demuestra tu transformación en 90 días", fr: "Prouvez votre transformation en 90 jours", de: "Beweise deine Transformation in 90 Tagen") }
    static func challengeDayN(_ day: Int) -> String {
        loc("Day \(day)", "Day \(day)", zhHans: "第\(day)天", ko: "Day \(day)", es: "Día \(day)", fr: "Jour \(day)", de: "Tag \(day)")
    }
    static func challengeDaysLeft(_ days: Int) -> String {
        loc("あと\(days)日", "\(days) days left", zhHans: "还剩\(days)天", ko: "\(days)일 남음", es: "\(days) días restantes", fr: "\(days) jours restants", de: "Noch \(days) Tage")
    }
    static var challengeComplete: String { loc("90日チャレンジ達成！", "90-Day Challenge Complete!", zhHans: "90天挑战完成！", ko: "90일 챌린지 달성!", es: "¡Desafío de 90 días completado!", fr: "Défi 90 jours terminé !", de: "90-Tage-Challenge geschafft!") }
    static var challengeViewRecap: String { loc("Recapを見る", "View Recap", zhHans: "查看回顾", ko: "Recap 보기", es: "Ver resumen", fr: "Voir le récap", de: "Rückblick ansehen") }
    static var challengeDayComplete: String { loc("完了！", "Complete!", zhHans: "完成！", ko: "완료!", es: "¡Hecho!", fr: "Terminé !", de: "Fertig!") }

    // MARK: - メニュー自動提案（Pro）
    static var startWithThisMenu: String { loc("このメニューで始める", "Start This Menu", zhHans: "按此菜单开始", ko: "이 메뉴로 시작", es: "Iniciar este menú", fr: "Commencer ce menu", de: "Dieses Menü starten") }
    static var reviewMenu: String { loc("メニューを確認する", "Review Menu", zhHans: "查看菜单", ko: "메뉴 확인하기", es: "Revisar menú", fr: "Voir le menu", de: "Menü ansehen") }
    static var todayMenuTitle: String { loc("今日のメニュー", "Today's Menu", zhHans: "今日菜单", ko: "오늘의 메뉴", es: "Menú de hoy", fr: "Menu du jour", de: "Heutiges Menü") }
    static var trainedMuscles: String { loc("鍛える筋肉", "Muscles Trained", zhHans: "训练肌肉", ko: "훈련 근육", es: "Músculos entrenados", fr: "Muscles entraînés", de: "Trainierte Muskeln") }
    static func previousRecord(_ text: String) -> String { loc("前回: \(text)", "Last: \(text)", zhHans: "上次: \(text)", ko: "지난번: \(text)", es: "Anterior: \(text)", fr: "Précédent: \(text)", de: "Letzte: \(text)") }
    static func weightChallenge(_ kg: String) -> String {
        loc("+\(kg)kg 挑戦！", "+\(kg)kg Challenge!", zhHans: "+\(kg)kg 挑战！", ko: "+\(kg)kg 도전!", es: "+\(kg)kg ¡Reto!", fr: "+\(kg)kg Défi !", de: "+\(kg)kg Herausforderung!")
    }
    static var proLabel: String { loc("Pro", "Pro") }
    static var noHistory: String { loc("履歴なし", "No history", zhHans: "无历史", ko: "기록 없음", es: "Sin historial", fr: "Aucun historique", de: "Kein Verlauf") }
    static var menuSuggestionProDescription: String { loc("種目・重量・セットを自動提案", "Auto-suggest exercises, weight & sets", zhHans: "自动推荐动作、重量和组数", ko: "종목·중량·세트 자동 제안", es: "Sugerencia automática de ejercicios", fr: "Suggestion auto d'exercices", de: "Auto-Vorschlag für Übungen") }

    // MARK: - ルーティン表示
    static var todayRoutine: String { loc("今日のルーティン", "Today's Routine", zhHans: "今日训练", ko: "오늘의 루틴", es: "Rutina de hoy", fr: "Routine du jour", de: "Heutige Routine") }
    static var startRoutine: String { loc("ルーティンを開始する", "Start Routine", zhHans: "开始训练", ko: "루틴 시작", es: "Iniciar rutina", fr: "Commencer la routine", de: "Routine starten") }
    static var noWeight: String { loc("-- kg", "-- kg") }

    // MARK: - レベルアップ
    static var strengthLevelTitle: String { loc("強さレベル", "Strength Level", zhHans: "力量等级", ko: "강도 레벨", es: "Nivel de fuerza", fr: "Niveau de force", de: "Stärke-Level") }
    static var maxLevelReached: String { loc("最高レベル到達！", "Max Level Reached!", zhHans: "已达最高等级！", ko: "최고 레벨 달성!", es: "¡Nivel máximo alcanzado!", fr: "Niveau max atteint !", de: "Max Level erreicht!") }
    static var levelUp: String { loc("レベルアップ！", "Level Up!", zhHans: "升级！", ko: "레벨 업!", es: "¡Subida de nivel!", fr: "Niveau supérieur !", de: "Level Up!") }
    static func levelUpKgToNext(_ kg: Int, _ levelName: String) -> String {
        loc("あと\(kg)kgで\(levelName)", "\(kg)kg to \(levelName)", zhHans: "距\(levelName)还需\(kg)kg", ko: "\(levelName)까지 \(kg)kg", es: "\(kg)kg para \(levelName)", fr: "\(kg)kg pour \(levelName)", de: "\(kg)kg bis \(levelName)")
    }

    // MARK: - SplashView
    static var splashHeadline: String { loc("鍛えた筋肉が光る。", "Watch your muscles light up.", zhHans: "锻炼的肌肉会发光。", ko: "단련한 근육이 빛난다.", es: "Tus músculos se iluminan.", fr: "Vos muscles s'illuminent.", de: "Deine Muskeln leuchten auf.") }
    static var splashSubheadline: String { loc("あなたの体の変化を、目で見る。", "See your body transform.", zhHans: "用眼睛看到身体的变化。", ko: "몸의 변화를 눈으로 보세요.", es: "Observa cómo tu cuerpo se transforma.", fr: "Voyez votre corps se transformer.", de: "Sieh deinen Körper sich verändern.") }

    // MARK: - GoalSelectionPage
    static var keyTargets: String { loc("重点部位", "Key Targets", zhHans: "重点部位", ko: "중점 부위", es: "Objetivos clave", fr: "Cibles clés", de: "Schwerpunkte") }
    static var tapToSelectGoals: String { loc("タップして目標を選択", "Tap to select your goals", zhHans: "点击选择目标", ko: "탭하여 목표를 선택하세요", es: "Toca para seleccionar tus objetivos", fr: "Appuyez pour sélectionner vos objectifs", de: "Tippen, um Ziele auszuwählen") }

    // MARK: - FrequencySelectionPage
    static var freqTwice: String { loc("週2回", "2× / week", zhHans: "每周2次", ko: "주 2회", es: "2× / semana", fr: "2× / semaine", de: "2× / Woche") }
    static var freqThrice: String { loc("週3回", "3× / week", zhHans: "每周3次", ko: "주 3회", es: "3× / semana", fr: "3× / semaine", de: "3× / Woche") }
    static var freqFour: String { loc("週4回", "4× / week", zhHans: "每周4次", ko: "주 4회", es: "4× / semana", fr: "4× / semaine", de: "4× / Woche") }
    static var freqFivePlus: String { loc("週5回以上", "5+ / week", zhHans: "每周5次以上", ko: "주 5회 이상", es: "5+ / semana", fr: "5+ / semaine", de: "5+ / Woche") }
    static var freqTwiceDesc: String { loc("上半身と下半身を分けて鍛える", "Upper body & lower body split", zhHans: "上下半身分开训练", ko: "상체와 하체를 나누어 운동", es: "División superior e inferior", fr: "Split haut et bas du corps", de: "Ober- und Unterkörper-Split") }
    static var freqThriceDesc: String { loc("胸・背中・脚の3分割", "Chest, back & legs — 3 day split", zhHans: "胸·背·腿3分化", ko: "가슴·등·다리 3분할", es: "Pecho, espalda y piernas — 3 días", fr: "Poitrine, dos et jambes — 3 jours", de: "Brust, Rücken & Beine — 3er Split") }
    static var freqFourDesc: String { loc("部位ごとにしっかり追い込む", "Dedicated day for each muscle group", zhHans: "每个部位深度训练", ko: "부위별로 확실하게 운동", es: "Día dedicado a cada grupo muscular", fr: "Jour dédié à chaque groupe musculaire", de: "Eigener Tag pro Muskelgruppe") }
    static var freqFivePlusDesc: String { loc("毎日違う部位をフルで鍛える", "Full volume per muscle group daily", zhHans: "每天全力训练不同部位", ko: "매일 다른 부위를 풀로 운동", es: "Volumen completo por grupo cada día", fr: "Volume complet par groupe chaque jour", de: "Volles Volumen pro Muskelgruppe täglich") }
    static var freqTwiceDetail: String { loc("各部位に十分な回復時間。初心者に最適", "Full recovery time. Best for beginners", zhHans: "各部位充足恢复时间。最适合初学者", ko: "각 부위에 충분한 회복 시간. 초보자에게 최적", es: "Tiempo de recuperación completo. Ideal para principiantes", fr: "Temps de récupération complet. Idéal pour débutants", de: "Volle Erholungszeit. Ideal für Anfänger") }
    static var freqThriceDetail: String { loc("胸・背中・脚の王道3分割", "Classic 3-day split for balanced growth", zhHans: "经典胸·背·腿3分化", ko: "클래식 3분할로 균형 잡힌 성장", es: "Split clásico de 3 días para crecimiento equilibrado", fr: "Split classique 3 jours pour croissance équilibrée", de: "Klassischer 3er-Split für ausgewogenes Wachstum") }
    static var freqFourDetail: String { loc("部位ごとにしっかり追い込む", "Dedicated focus per muscle group", zhHans: "每个部位深度训练", ko: "부위별 집중 운동", es: "Enfoque dedicado por grupo muscular", fr: "Focus dédié par groupe musculaire", de: "Fokus pro Muskelgruppe") }
    static var freqFivePlusDetail: String { loc("各部位を個別にフルで鍛える", "Maximum volume per muscle group", zhHans: "各部位全力训练", ko: "각 부위를 개별적으로 풀로 운동", es: "Máximo volumen por grupo muscular", fr: "Volume maximum par groupe musculaire", de: "Maximales Volumen pro Muskelgruppe") }
    static var freqTitle: String { loc("週にどれくらいやれる？", "How often can you train?", zhHans: "每周能练几次？", ko: "일주일에 몇 번 할 수 있어?", es: "¿Cuántas veces puedes entrenar?", fr: "Combien de fois par semaine ?", de: "Wie oft kannst du trainieren?") }
    static var freqSubtitle: String { loc("あなたに合った分割法を提案します", "We'll suggest the best split for you", zhHans: "我们会推荐最适合你的分割法", ko: "당신에게 맞는 분할법을 제안합니다", es: "Te sugeriremos la mejor división", fr: "Nous vous suggérerons le meilleur split", de: "Wir schlagen dir den besten Split vor") }
    static var legendStimulus: String { loc("刺激", "Stimulus", zhHans: "刺激", ko: "자극", es: "Estímulo", fr: "Stimulus", de: "Stimulus") }
    static var legendRecovering: String { loc("回復中", "Recovering", zhHans: "恢复中", ko: "회복 중", es: "Recuperando", fr: "Récupération", de: "Erholung") }
    static var legendInactive: String { loc("未刺激", "Inactive", zhHans: "未刺激", ko: "미자극", es: "Inactivo", fr: "Inactif", de: "Inaktiv") }
    static var freqCycleHint: String { loc("頻度を選ぶとサイクルが動きます", "Select to see the recovery cycle", zhHans: "选择频率查看恢复周期", ko: "빈도를 선택하면 사이클이 움직입니다", es: "Selecciona para ver el ciclo de recuperación", fr: "Sélectionnez pour voir le cycle de récupération", de: "Wähle, um den Erholungszyklus zu sehen") }
    static var freqRecommended: String { loc("初心者におすすめ", "Recommended", zhHans: "推荐新手", ko: "초보자 추천", es: "Recomendado", fr: "Recommandé", de: "Empfohlen") }
    static var freqCycleDescription: String { loc("赤＝刺激 → 黄＝回復中 → 暗い＝回復完了。このサイクルで鍛える", "Red = stimulated → Yellow = recovering → Dark = recovered. Train with this cycle", zhHans: "红=刺激 → 黄=恢复中 → 暗=恢复完成。按此周期训练", ko: "빨강=자극 → 노랑=회복 중 → 어두운=회복 완료. 이 사이클로 운동", es: "Rojo = estimulado → Amarillo = recuperando → Oscuro = recuperado", fr: "Rouge = stimulé → Jaune = récupération → Sombre = récupéré", de: "Rot = stimuliert → Gelb = Erholung → Dunkel = erholt") }
    static func freqDayLabels() -> [String] { [loc("月", "Mon", zhHans: "一", ko: "월", es: "Lun", fr: "Lun", de: "Mo"), loc("火", "Tue", zhHans: "二", ko: "화", es: "Mar", fr: "Mar", de: "Di"), loc("水", "Wed", zhHans: "三", ko: "수", es: "Mié", fr: "Mer", de: "Mi"), loc("木", "Thu", zhHans: "四", ko: "목", es: "Jue", fr: "Jeu", de: "Do"), loc("金", "Fri", zhHans: "五", ko: "금", es: "Vie", fr: "Ven", de: "Fr"), loc("土", "Sat", zhHans: "六", ko: "토", es: "Sáb", fr: "Sam", de: "Sa"), loc("日", "Sun", zhHans: "日", ko: "일", es: "Dom", fr: "Dim", de: "So")] }

    // MARK: - LocationSelectionPage
    static var locGym: String { loc("ジム", "Gym", zhHans: "健身房", ko: "헬스장", es: "Gimnasio", fr: "Salle de sport", de: "Fitnessstudio") }
    static var locHome: String { loc("自宅", "Home", zhHans: "家里", ko: "자택", es: "Casa", fr: "Domicile", de: "Zuhause") }
    static var locBodyweight: String { loc("自重のみ", "Bodyweight Only", zhHans: "徒手训练", ko: "맨몸 운동만", es: "Solo peso corporal", fr: "Poids du corps uniquement", de: "Nur Eigengewicht") }
    static var locBoth: String { loc("両方", "Both", zhHans: "两者都", ko: "둘 다", es: "Ambos", fr: "Les deux", de: "Beides") }
    static var locGymSub: String { loc("マシン・バーベル・ダンベル全部", "Full equipment access", zhHans: "机器·杠铃·哑铃齐全", ko: "머신·바벨·덤벨 전부", es: "Acceso completo al equipo", fr: "Accès complet à l'équipement", de: "Voller Gerätezugang") }
    static var locHomeSub: String { loc("ダンベルと自重で鍛える", "Dumbbells & bodyweight", zhHans: "哑铃和自重训练", ko: "덤벨과 맨몸 운동", es: "Mancuernas y peso corporal", fr: "Haltères et poids du corps", de: "Hanteln & Eigengewicht") }
    static var locBodyweightSub: String { loc("器具なし、体ひとつで", "No equipment needed", zhHans: "无需器械，徒手训练", ko: "기구 없이 몸 하나로", es: "Sin equipo necesario", fr: "Aucun équipement nécessaire", de: "Keine Geräte nötig") }
    static var locBothSub: String { loc("ジムと自宅を組み合わせ", "Mix gym and home", zhHans: "健身房和家里结合", ko: "헬스장과 자택을 조합", es: "Combina gimnasio y casa", fr: "Mix salle et domicile", de: "Kombination Studio & Zuhause") }

    // MARK: - TrainingHistoryPage (ProfileInputPage)
    static var expNewbie: String { loc("初心者", "Newbie", zhHans: "新手", ko: "초보자", es: "Novato", fr: "Débutant", de: "Anfänger") }
    static var expSixMonths: String { loc("半年", "6 Mo", zhHans: "半年", ko: "반년", es: "6 meses", fr: "6 mois", de: "6 Mon.") }
    static var expOneYearPlus: String { loc("1年+", "1 Yr+", zhHans: "1年+", ko: "1년+", es: "1 año+", fr: "1 an+", de: "1 J+") }
    static var expVeteran: String { loc("ベテラン", "Veteran", zhHans: "老手", ko: "베테랑", es: "Veterano", fr: "Vétéran", de: "Veteran") }
    static var expRecommendNewbie: String { loc("わからない場合は「初心者」がおすすめ", "If unsure, select \"Newbie\"", zhHans: "不确定的话选择「新手」", ko: "잘 모르겠으면 \"초보자\"를 선택", es: "Si no estás seguro, selecciona \"Novato\"", fr: "Si incertain, sélectionnez \"Débutant\"", de: "Im Zweifel \"Anfänger\" wählen") }
    static var heightLabel: String { loc("身長", "Height", zhHans: "身高", ko: "신장", es: "Altura", fr: "Taille", de: "Größe") }
    static var heightUsedForBMI: String { loc("BMI計算に使用します", "Used for BMI calculation", zhHans: "用于计算BMI", ko: "BMI 계산에 사용됩니다", es: "Usado para cálculo de IMC", fr: "Utilisé pour le calcul de l'IMC", de: "Wird für BMI-Berechnung verwendet") }
    static var weightUsedForSuggestion: String { loc("体重から最適な重量を提案します", "Used to suggest optimal weights", zhHans: "根据体重推荐最佳训练重量", ko: "체중으로 최적 중량을 제안합니다", es: "Para sugerir pesos óptimos", fr: "Pour suggérer les poids optimaux", de: "Zur Empfehlung optimaler Gewichte") }
    static var bodyFatLabel: String { loc("体脂肪率", "Body Fat", zhHans: "体脂率", ko: "체지방률", es: "Grasa corporal", fr: "Masse grasse", de: "Körperfett") }
    static var bodyFatShort: String { loc("体脂肪率", "BF%", zhHans: "体脂率", ko: "체지방률", es: "% grasa", fr: "% MG", de: "KF%") }
    static var bfAthlete: String { loc("アスリート", "Athlete", zhHans: "运动员", ko: "운동선수", es: "Atleta", fr: "Athlète", de: "Athlet") }
    static var bfFitness: String { loc("フィットネス", "Fitness", zhHans: "健身", ko: "피트니스", es: "Fitness", fr: "Fitness", de: "Fitness") }
    static var bfAverage: String { loc("標準", "Average", zhHans: "标准", ko: "표준", es: "Promedio", fr: "Moyen", de: "Durchschnitt") }
    static var bfAboveAverage: String { loc("やや高め", "Above Average", zhHans: "偏高", ko: "다소 높음", es: "Por encima del promedio", fr: "Au-dessus de la moyenne", de: "Überdurchschnittlich") }
    static var bfHigh: String { loc("高め", "High", zhHans: "高", ko: "높음", es: "Alto", fr: "Élevé", de: "Hoch") }

    // MARK: - PRInputPage
    static var prTapMuscles: String { loc("筋肉をタップして重量を入力", "Tap muscles to enter weights", zhHans: "点击肌肉输入重量", ko: "근육을 탭하여 중량 입력", es: "Toca los músculos para ingresar pesos", fr: "Appuyez sur les muscles pour entrer les poids", de: "Tippe auf Muskeln, um Gewichte einzugeben") }
    static var addLabel: String { loc("追加", "Add", zhHans: "添加", ko: "추가", es: "Añadir", fr: "Ajouter", de: "Hinzufügen") }
    static var yourLevel: String { loc("現在のレベル", "Your Level", zhHans: "当前水平", ko: "현재 레벨", es: "Tu nivel", fr: "Votre niveau", de: "Dein Level") }
    static var skipIfUnsure: String { loc("わからない場合はスキップ →", "Skip if unsure →", zhHans: "不确定可以跳过 →", ko: "잘 모르겠으면 건너뛰기 →", es: "Omitir si no estás seguro →", fr: "Passer si incertain →", de: "Überspringen wenn unsicher →") }
    static var prMaxWeight: String { loc("最大重量 (1RM)", "Max Weight (1RM)", zhHans: "最大重量 (1RM)", ko: "최대 중량 (1RM)", es: "Peso máximo (1RM)", fr: "Poids max (1RM)", de: "Maximalgewicht (1RM)") }
    static var prMaxWeightDesc: String { loc("1回だけ挙げられる最大の重量", "The heaviest weight you can lift once", zhHans: "你只能举一次的最大重量", ko: "한 번만 들 수 있는 최대 중량", es: "El peso más pesado que puedes levantar una vez", fr: "Le poids le plus lourd que vous pouvez soulever une fois", de: "Das schwerste Gewicht, das du einmal heben kannst") }
    static var recordButton: String { loc("記録する", "Record", zhHans: "记录", ko: "기록하기", es: "Registrar", fr: "Enregistrer", de: "Aufzeichnen") }
    static var prEnterWeightHint: String { loc("重量を入力すると、あなたの強さレベルが判定されます", "Enter weights to see your strength level", zhHans: "输入重量后，会判定你的力量水平", ko: "중량을 입력하면 강도 레벨이 판정됩니다", es: "Introduce pesos para ver tu nivel de fuerza", fr: "Entrez les poids pour voir votre niveau", de: "Gib Gewichte ein, um dein Stärkelevel zu sehen") }
    static var prMoreInputHint: String { loc("もっと入力すると精度が上がります", "More entries improve accuracy", zhHans: "输入越多精度越高", ko: "더 입력하면 정확도가 올라갑니다", es: "Más entradas mejoran la precisión", fr: "Plus d'entrées améliorent la précision", de: "Mehr Eingaben verbessern die Genauigkeit") }
    static var addedLabel: String { loc("追加済み", "Added", zhHans: "已添加", ko: "추가됨", es: "Añadido", fr: "Ajouté", de: "Hinzugefügt") }

    // MARK: - MenuGeneratingPage
    static var menuGeneratingTitle: String { loc("あなた専用メニューを作成中", "Creating Your Custom Menu", zhHans: "正在创建你的专属菜单", ko: "맞춤 메뉴를 만드는 중", es: "Creando tu menú personalizado", fr: "Création de votre menu personnalisé", de: "Dein individuelles Menü wird erstellt") }
    static var mgStep1: String { loc("目標と経験を分析中…", "Analyzing goals & experience…", zhHans: "分析目标和经验…", ko: "목표와 경험 분석 중…", es: "Analizando objetivos y experiencia…", fr: "Analyse des objectifs et de l'expérience…", de: "Ziele und Erfahrung werden analysiert…") }
    static var mgStep2: String { loc("最適な種目を選定中…", "Selecting optimal exercises…", zhHans: "选择最佳动作…", ko: "최적 종목 선정 중…", es: "Seleccionando ejercicios óptimos…", fr: "Sélection des exercices optimaux…", de: "Optimale Übungen werden ausgewählt…") }
    static var mgStep3: String { loc("分割スケジュールを構築中…", "Building your split schedule…", zhHans: "构建分割计划…", ko: "분할 스케줄 구축 중…", es: "Construyendo tu plan de división…", fr: "Construction de votre programme split…", de: "Dein Split-Plan wird erstellt…") }
    static var mgStep4: String { loc("あなた専用メニュー完成！", "Your custom menu is ready!", zhHans: "你的专属菜单完成！", ko: "맞춤 메뉴 완성!", es: "¡Tu menú personalizado está listo!", fr: "Votre menu personnalisé est prêt !", de: "Dein individuelles Menü ist fertig!") }

    // MARK: - RoutineBuilderPage
    static func muscleCoveragePercent(_ pct: Int) -> String { loc("\(pct)%の筋肉をカバー", "\(pct)% muscle coverage", zhHans: "覆盖\(pct)%肌肉", ko: "\(pct)% 근육 커버", es: "\(pct)% cobertura muscular", fr: "\(pct)% de couverture musculaire", de: "\(pct)% Muskelabdeckung") }
    static func reviewDay(_ num: Int) -> String { loc("Day \(num) を確認する", "Review Day \(num)", zhHans: "查看Day \(num)", ko: "Day \(num) 확인하기", es: "Revisar Día \(num)", fr: "Voir Jour \(num)", de: "Tag \(num) ansehen") }
    static var routineChangeLater: String { loc("メニューは後から設定で変更できます", "You can customize your routine later in Settings", zhHans: "菜单可以在设置中更改", ko: "메뉴는 나중에 설정에서 변경할 수 있습니다", es: "Puedes cambiar tu rutina después en Ajustes", fr: "Vous pouvez modifier votre routine plus tard dans les Réglages", de: "Du kannst dein Menü später in den Einstellungen ändern") }
    static var routineAutoSuggested: String { loc("あなたの目標に合わせて自動提案しました", "Auto-suggested based on your goals", zhHans: "根据你的目标自动推荐", ko: "목표에 맞춰 자동 제안했습니다", es: "Sugerido automáticamente según tus objetivos", fr: "Suggestion automatique selon vos objectifs", de: "Automatisch basierend auf deinen Zielen vorgeschlagen") }
    static func totalExercisesPerWeek(_ exercises: Int, _ days: Int) -> String { loc("合計 \(exercises)種目 / 週\(days)回", "Total \(exercises) exercises / \(days)× per week", zhHans: "共\(exercises)个动作 / 每周\(days)次", ko: "총 \(exercises)종목 / 주\(days)회", es: "Total \(exercises) ejercicios / \(days)× por semana", fr: "Total \(exercises) exercices / \(days)× par semaine", de: "Gesamt \(exercises) Übungen / \(days)× pro Woche") }
    static func dayExerciseCount(_ count: Int) -> String { loc("\(count)種目", "\(count) exercises", zhHans: "\(count)个动作", ko: "\(count)종목", es: "\(count) ejercicios", fr: "\(count) exercices", de: "\(count) Übungen") }
    static var rbTipPush: String { loc("💡 「押す」動作の筋肉をまとめて効率UP", "💡 Group push muscles for maximum efficiency", zhHans: "💡 推的动作肌肉组合提高效率", ko: "💡 밀기 동작 근육을 모아서 효율 UP", es: "💡 Agrupa músculos de empuje para máxima eficiencia", fr: "💡 Regroupez les muscles de poussée pour plus d'efficacité", de: "💡 Druckmuskulatur bündeln für maximale Effizienz") }
    static var rbTipPull: String { loc("💡 「引く」動作の筋肉で背中を厚く", "💡 Pull muscles build a thicker back", zhHans: "💡 拉的动作肌肉让背部更厚", ko: "💡 당기기 동작 근육으로 등을 두껍게", es: "💡 Los músculos de tirón construyen una espalda más gruesa", fr: "💡 Les muscles de traction construisent un dos plus épais", de: "💡 Zugmuskulatur für einen breiteren Rücken") }
    static var rbTipLegs: String { loc("💡 下半身は代謝UPの最重要パーツ", "💡 Lower body is key for boosting metabolism", zhHans: "💡 下半身是提高代谢的最重要部位", ko: "💡 하체는 대사 UP의 가장 중요한 부위", es: "💡 El tren inferior es clave para el metabolismo", fr: "💡 Le bas du corps est clé pour le métabolisme", de: "💡 Unterkörper ist der Schlüssel zum Stoffwechsel") }
    static var rbTipShoulders: String { loc("💡 肩を鍛えると全体のシルエットが変わる", "💡 Shoulders transform your overall silhouette", zhHans: "💡 练肩可以改变整体轮廓", ko: "💡 어깨를 단련하면 전체 실루엣이 변한다", es: "💡 Los hombros transforman tu silueta", fr: "💡 Les épaules transforment votre silhouette", de: "💡 Schultern verändern deine gesamte Silhouette") }
    static var rbTipArms: String { loc("💡 腕はTシャツから見える「名刺」", "💡 Arms are your \"business card\" in a T-shirt", zhHans: "💡 手臂是T恤下的「名片」", ko: "💡 팔은 티셔츠 속 \"명함\"", es: "💡 Los brazos son tu \"tarjeta de presentación\"", fr: "💡 Les bras sont votre \"carte de visite\"", de: "💡 Arme sind deine \"Visitenkarte\" im T-Shirt") }
    static var rbTipAux: String { loc("💡 補助筋もまとめてカバー", "💡 Accessory muscles covered together", zhHans: "💡 辅助肌肉也一起覆盖", ko: "💡 보조근도 함께 커버", es: "💡 Músculos auxiliares cubiertos también", fr: "💡 Muscles accessoires couverts ensemble", de: "💡 Hilfsmuskulatur wird gleich mittrainiert") }

    // MARK: - NotificationPermissionView
    static var notifHeadline: String { loc("回復したら、教える。", "We'll Tell You When You're Ready.", zhHans: "恢复了就告诉你。", ko: "회복되면 알려줄게.", es: "Te avisamos cuando estés listo.", fr: "On vous prévient quand c'est bon.", de: "Wir sagen dir, wann du bereit bist.") }
    static var notifSubheadline: String { loc("筋肉が回復したタイミングで通知を受け取れます\nベストなタイミングで次のトレーニングへ。", "Get notified when your muscles recover.\nTrain at the perfect time.", zhHans: "肌肉恢复时收到通知\n在最佳时机进行下一次训练。", ko: "근육이 회복되면 알림을 받으세요\n최적의 타이밍에 다음 트레이닝으로.", es: "Recibe notificaciones cuando tus músculos se recuperen.\nEntrena en el momento perfecto.", fr: "Soyez notifié quand vos muscles récupèrent.\nEntraînez-vous au moment parfait.", de: "Erhalte Benachrichtigungen, wenn deine Muskeln erholt sind.\nTrainiere zum perfekten Zeitpunkt.") }
    static var notifMockTitle1: String { loc("🔥 大胸筋・三角筋 回復完了！", "🔥 Chest & Delts Recovered!", zhHans: "🔥 胸肌·三角肌恢复完成！", ko: "🔥 대흉근·삼각근 회복 완료!", es: "🔥 ¡Pecho y deltoides recuperados!", fr: "🔥 Pectoraux et deltoïdes récupérés !", de: "🔥 Brust & Schultern erholt!") }
    static var notifMockBody1: String { loc("プッシュの日です。トレーニングしよう！", "Push day. Time to train!", zhHans: "今天是推日。开始训练吧！", ko: "푸쉬 데이입니다. 트레이닝하자!", es: "Día de empuje. ¡A entrenar!", fr: "Jour de poussée. C'est l'heure !", de: "Push-Tag. Zeit zu trainieren!") }
    static var notifMockTime1: String { loc("たった今", "Just now", zhHans: "刚刚", ko: "방금", es: "Ahora mismo", fr: "À l'instant", de: "Gerade eben") }
    static var notifMockTitle2: String { loc("🏆 ベンチプレス PR更新チャンス！", "🏆 Bench Press PR Opportunity!", zhHans: "🏆 卧推PR更新机会！", ko: "🏆 벤치프레스 PR 갱신 찬스!", es: "🏆 ¡Oportunidad de PR en press de banca!", fr: "🏆 Occasion de PR au développé couché !", de: "🏆 Bankdrücken PR-Chance!") }
    static var notifMockBody2: String { loc("前回62.5kg×8。今日65kgに挑戦できるかも", "Last time 62.5kg×8. Try 65kg today?", zhHans: "上次62.5kg×8。今天可以挑战65kg", ko: "지난번 62.5kg×8. 오늘 65kg에 도전할 수 있을지도", es: "Última vez 62.5kg×8. ¿Intentar 65kg hoy?", fr: "Dernière fois 62.5kg×8. Essayer 65kg aujourd'hui ?", de: "Letztes Mal 62.5kg×8. Heute 65kg versuchen?") }
    static var notifMockTime2: String { loc("2時間前", "2h ago", zhHans: "2小时前", ko: "2시간 전", es: "Hace 2h", fr: "Il y a 2h", de: "Vor 2 Std.") }
    static var notifEnableButton: String { loc("回復通知をオンにする", "Turn On Recovery Alerts", zhHans: "开启恢复通知", ko: "회복 알림 켜기", es: "Activar alertas de recuperación", fr: "Activer les alertes de récupération", de: "Erholungsbenachrichtigungen aktivieren") }
    static var notifStepStimulate: String { loc("刺激", "Stimulate", zhHans: "刺激", ko: "자극", es: "Estimular", fr: "Stimuler", de: "Stimulieren") }
    static var notifStepRecover: String { loc("回復", "Recover", zhHans: "恢复", ko: "회복", es: "Recuperar", fr: "Récupérer", de: "Erholen") }
    static var notifStepGrow: String { loc("成長", "Grow", zhHans: "成长", ko: "성장", es: "Crecer", fr: "Grandir", de: "Wachsen") }

    // MARK: - RoutineCompletionPage
    static var completionDefaultTitle: String { loc("あなた専用プログラム完成", "Your Program is Ready", zhHans: "你的专属计划完成", ko: "맞춤 프로그램 완성", es: "Tu programa está listo", fr: "Votre programme est prêt", de: "Dein Programm ist fertig") }
    static var completionBulk: String { loc("デカくなる準備完了。", "Ready to Get Big.", zhHans: "变大的准备完成。", ko: "커질 준비 완료.", es: "Listo para crecer.", fr: "Prêt à grossir.", de: "Bereit, groß zu werden.") }
    static var completionStrength: String { loc("強くなる準備完了。", "Ready to Get Strong.", zhHans: "变强的准备完成。", ko: "강해질 준비 완료.", es: "Listo para ser fuerte.", fr: "Prêt à devenir fort.", de: "Bereit, stark zu werden.") }
    static var completionFight: String { loc("闘う体の準備完了。", "Fight-Ready Program.", zhHans: "战斗体格准备完成。", ko: "싸우는 몸 준비 완료.", es: "Programa listo para pelear.", fr: "Programme prêt au combat.", de: "Kampfbereit.") }
    static var completionTransform: String { loc("変わる準備完了。", "Ready to Transform.", zhHans: "蜕变准备完成。", ko: "변할 준비 완료.", es: "Listo para transformarte.", fr: "Prêt à se transformer.", de: "Bereit zur Transformation.") }
    static var completionAthlete: String { loc("アスリートの準備完了。", "Athletic Program Ready.", zhHans: "运动员计划就绪。", ko: "운동선수 준비 완료.", es: "Programa atlético listo.", fr: "Programme athlétique prêt.", de: "Athleten-Programm bereit.") }
    static var completionMobility: String { loc("動ける体の準備完了。", "Mobility Program Ready.", zhHans: "灵活身体准备完成。", ko: "움직이는 몸 준비 완료.", es: "Programa de movilidad listo.", fr: "Programme mobilité prêt.", de: "Mobilität-Programm bereit.") }
    static var completionHealth: String { loc("健康への第一歩。", "Your Health Journey Starts.", zhHans: "迈向健康的第一步。", ko: "건강을 향한 첫걸음.", es: "Tu camino a la salud comienza.", fr: "Votre parcours santé commence.", de: "Dein Gesundheitsweg beginnt.") }
    static var coverageLabel: String { loc("カバレッジ", "Coverage", zhHans: "覆盖率", ko: "커버리지", es: "Cobertura", fr: "Couverture", de: "Abdeckung") }
    static var fullBodyCover: String { loc("全身カバー!", "Full body!", zhHans: "全身覆盖!", ko: "전신 커버!", es: "¡Cuerpo completo!", fr: "Corps entier !", de: "Ganzkörper!") }
    static var completionOptimized: String { loc("目標・経験・環境から最適化", "Optimized for your goals, experience & environment", zhHans: "根据目标·经验·环境优化", ko: "목표·경험·환경에 맞춰 최적화", es: "Optimizado para tus objetivos, experiencia y entorno", fr: "Optimisé selon vos objectifs, expérience et environnement", de: "Optimiert für deine Ziele, Erfahrung & Umgebung") }

    // MARK: - GoalMusclePreviewPage
    static var gmProgBulk: String { loc("デカくなるプログラム", "Program to Get Big", zhHans: "增肌计划", ko: "벌크업 프로그램", es: "Programa para crecer", fr: "Programme pour grossir", de: "Programm zum Masseaufbau") }
    static var gmProgStrength: String { loc("強くなるプログラム", "Program to Get Strong", zhHans: "增强力量计划", ko: "강해지는 프로그램", es: "Programa para ser fuerte", fr: "Programme pour devenir fort", de: "Programm zum Starkwerden") }
    static var gmProgFight: String { loc("闘う体のプログラム", "Fighter's Program", zhHans: "格斗体格计划", ko: "격투 프로그램", es: "Programa de luchador", fr: "Programme de combat", de: "Kämpfer-Programm") }
    static var gmProgTransform: String { loc("変わるためのプログラム", "Transformation Program", zhHans: "蜕变计划", ko: "변화 프로그램", es: "Programa de transformación", fr: "Programme de transformation", de: "Transformations-Programm") }
    static var gmProgAthlete: String { loc("アスリートのプログラム", "Athlete's Program", zhHans: "运动员计划", ko: "운동선수 프로그램", es: "Programa de atleta", fr: "Programme d'athlète", de: "Athleten-Programm") }
    static var gmProgMobility: String { loc("動ける体のプログラム", "Mobility Program", zhHans: "灵活身体计划", ko: "움직이는 몸 프로그램", es: "Programa de movilidad", fr: "Programme mobilité", de: "Mobilitäts-Programm") }
    static var gmProgHealth: String { loc("健康のためのプログラム", "Health Program", zhHans: "健康计划", ko: "건강 프로그램", es: "Programa de salud", fr: "Programme santé", de: "Gesundheits-Programm") }
    static var gmPreviewSubtitle: String { loc("あなたの目標・経験・環境から最適な分割法を作成しました", "We've created the optimal split based on your goals, experience & environment", zhHans: "根据你的目标·经验·环境创建了最佳分割法", ko: "목표·경험·환경에 맞는 최적의 분할법을 만들었습니다", es: "Hemos creado la división óptima según tus objetivos", fr: "Nous avons créé le split optimal selon vos objectifs", de: "Wir haben den optimalen Split basierend auf deinen Zielen erstellt") }
    static var reviewExercises: String { loc("種目を確認する →", "Review Exercises →", zhHans: "查看动作 →", ko: "종목 확인하기 →", es: "Revisar ejercicios →", fr: "Voir les exercices →", de: "Übungen ansehen →") }

    // MARK: - PaywallView
    static var pwProcessing: String { loc("処理中...", "Processing...", zhHans: "处理中...", ko: "처리 중...", es: "Procesando...", fr: "Traitement...", de: "Verarbeitung...") }
    static var purchaseError: String { loc("購入エラー", "Purchase Error", zhHans: "购买错误", ko: "구매 오류", es: "Error de compra", fr: "Erreur d'achat", de: "Kauffehler") }
    static var unknownError: String { loc("不明なエラーが発生しました。", "An unknown error occurred.", zhHans: "发生未知错误。", ko: "알 수 없는 오류가 발생했습니다.", es: "Ocurrió un error desconocido.", fr: "Une erreur inconnue s'est produite.", de: "Ein unbekannter Fehler ist aufgetreten.") }
    static var pwMonthlyButton: String { loc("月額¥590で始める", "Start for $4.99/month", zhHans: "每月¥590开始", ko: "월 ¥590으로 시작", es: "Empezar por $4.99/mes", fr: "Commencer à 4,99$/mois", de: "Starten für 4,99$/Monat") }
    static var pwYearlyPrice: String { loc("年額¥4,900（月¥408）", "$39.99/year ($3.33/mo)", zhHans: "年费¥4,900（月¥408）", ko: "연 ¥4,900 (월 ¥408)", es: "$39.99/año ($3.33/mes)", fr: "39,99$/an (3,33$/mois)", de: "39,99$/Jahr (3,33$/Monat)") }
    static var pwFreeTrial: String { loc("7日間無料トライアル", "7-day free trial", zhHans: "7天免费试用", ko: "7일 무료 체험", es: "Prueba gratuita de 7 días", fr: "Essai gratuit de 7 jours", de: "7-Tage-Testversion") }
    static var pwCancelAnytime: String { loc("いつでもキャンセル可能", "Cancel anytime", zhHans: "随时可取消", ko: "언제든지 취소 가능", es: "Cancela cuando quieras", fr: "Annulez à tout moment", de: "Jederzeit kündbar") }
    static var pwRestorePurchase: String { loc("購入を復元", "Restore Purchase", zhHans: "恢复购买", ko: "구매 복원", es: "Restaurar compra", fr: "Restaurer l'achat", de: "Kauf wiederherstellen") }
    static var pwStartFreeNow: String { loc("無料で今すぐ始める", "Start Free Now", zhHans: "免费立即开始", ko: "무료로 지금 시작", es: "Empezar gratis ahora", fr: "Commencer gratuitement", de: "Jetzt kostenlos starten") }
    static var pwTermsOfUse: String { loc("利用規約", "Terms of Use", zhHans: "使用条款", ko: "이용약관", es: "Términos de uso", fr: "Conditions d'utilisation", de: "Nutzungsbedingungen") }
    static var pwPrivacyPolicy: String { loc("プライバシーポリシー", "Privacy Policy", zhHans: "隐私政策", ko: "개인정보처리방침", es: "Política de privacidad", fr: "Politique de confidentialité", de: "Datenschutzrichtlinie") }
    static var pwNoRestorableFound: String { loc("復元できる購入履歴が見つかりませんでした。", "No restorable purchases were found.", zhHans: "未找到可恢复的购买记录。", ko: "복원할 수 있는 구매 내역을 찾을 수 없습니다.", es: "No se encontraron compras restaurables.", fr: "Aucun achat restaurable trouvé.", de: "Keine wiederherstellbaren Käufe gefunden.") }
    static var pwLegalText: String { loc("購入によりApple IDに請求されます。定期購読は期限切れの24時間以内に自動更新されます。iTunesアカウント設定から自動更新をオフにすることができます。", "Payment will be charged to your Apple ID. Subscriptions automatically renew within 24 hours before expiration. You can turn off auto-renewal in your iTunes account settings.", zhHans: "购买将向Apple ID收费。订阅将在到期前24小时内自动续订。您可以在iTunes帐户设置中关闭自动续订。", ko: "구매 시 Apple ID로 청구됩니다. 구독은 만료 24시간 전에 자동 갱신됩니다. iTunes 계정 설정에서 자동 갱신을 끌 수 있습니다.", es: "El pago se cargará a tu Apple ID. Las suscripciones se renuevan automáticamente 24 horas antes del vencimiento. Puedes desactivar la renovación automática en los ajustes de tu cuenta de iTunes.", fr: "Le paiement sera débité de votre Apple ID. Les abonnements se renouvellent automatiquement 24h avant l'expiration. Vous pouvez désactiver le renouvellement dans les réglages iTunes.", de: "Die Zahlung wird über deine Apple-ID abgerechnet. Abonnements verlängern sich automatisch 24 Stunden vor Ablauf. Du kannst die automatische Verlängerung in den iTunes-Kontoeinstellungen deaktivieren.") }
    static func pwHeadlineWithRoutine(_ days: Int, _ exercises: Int) -> String { loc("あなた専用の\(days)日間メニュー", "Your \(days)-Day Program", zhHans: "你的\(days)天专属菜单", ko: "맞춤 \(days)일 메뉴", es: "Tu programa de \(days) días", fr: "Votre programme de \(days) jours", de: "Dein \(days)-Tage-Programm") }
    static func pwHeadlineExercises(_ count: Int) -> String { loc("\(count)種目、今日から始めよう", "\(count) exercises — start today", zhHans: "\(count)个动作，今天就开始", ko: "\(count)종목, 오늘부터 시작하자", es: "\(count) ejercicios — empieza hoy", fr: "\(count) exercices — commencez aujourd'hui", de: "\(count) Übungen — starte heute") }
    static var pwHeadlineFallback: String { loc("理想のカラダへ、最短ルート", "The Fastest Path to Your Ideal Body", zhHans: "通往理想身体的最短路线", ko: "이상적인 몸으로 가는 최단 루트", es: "El camino más rápido a tu cuerpo ideal", fr: "Le chemin le plus court vers votre corps idéal", de: "Der schnellste Weg zu deinem Idealkörper") }
    static func pwGoalSubtitle(_ goalName: String) -> String { loc("「\(goalName)」のために最適化", "Optimized for \"\(goalName)\"", zhHans: "为「\(goalName)」优化", ko: "「\(goalName)」을 위해 최적화", es: "Optimizado para \"\(goalName)\"", fr: "Optimisé pour « \(goalName) »", de: "Optimiert für \u{201E}\(goalName)\u{201C}") }
    static var pwFeature: String { loc("機能", "Feature", zhHans: "功能", ko: "기능", es: "Función", fr: "Fonction", de: "Funktion") }
    static var pwFree: String { loc("無料", "Free", zhHans: "免费", ko: "무료", es: "Gratis", fr: "Gratuit", de: "Kostenlos") }
    static var pwRecoveryMap: String { loc("回復マップ", "Recovery Map", zhHans: "恢复图", ko: "회복 맵", es: "Mapa de recuperación", fr: "Carte de récupération", de: "Erholungskarte") }
    static var pwWorkoutLog: String { loc("ワークアウト記録", "Workout Log", zhHans: "训练记录", ko: "운동 기록", es: "Registro de ejercicio", fr: "Journal d'entraînement", de: "Trainingsprotokoll") }
    static var pwTwicePerWeek: String { loc("週2回", "2/wk", zhHans: "每周2次", ko: "주2회", es: "2/sem", fr: "2/sem", de: "2/Wo") }

    // MARK: - HomeHelpers
    static var coachMarkTitle: String { loc("これがあなたの筋肉マップ", "This is your muscle map", zhHans: "这是你的肌肉图", ko: "이것이 당신의 근육 맵", es: "Este es tu mapa muscular", fr: "Voici votre carte musculaire", de: "Das ist deine Muskelkarte") }
    static var coachMarkBody: String { loc("トレーニングすると筋肉が赤く光ります。\n回復すると黄→暗い色に戻ります。", "Muscles light up red after training.\nThey turn yellow → dark as they recover.", zhHans: "训练后肌肉会变红。\n恢复后会从黄色→暗色。", ko: "트레이닝하면 근육이 빨갛게 빛납니다.\n회복되면 노랑→어두운 색으로 돌아갑니다.", es: "Los músculos se iluminan en rojo al entrenar.\nSe vuelven amarillos → oscuros al recuperarse.", fr: "Les muscles s'illuminent en rouge après l'entraînement.\nIls passent au jaune → sombre en récupérant.", de: "Muskeln leuchten rot nach dem Training.\nSie werden gelb → dunkel bei der Erholung.") }
    static var gotIt: String { loc("わかった！", "Got it!", zhHans: "明白了！", ko: "알겠어!", es: "¡Entendido!", fr: "Compris !", de: "Verstanden!") }

    // MARK: - ActiveWorkoutComponents
    static var routineComplete: String { loc("ルーティン完了!", "Routine Complete!", zhHans: "训练完成!", ko: "루틴 완료!", es: "¡Rutina completada!", fr: "Routine terminée !", de: "Routine abgeschlossen!") }
    static var routineCompleteHint: String { loc("追加で種目を記録するか、ワークアウトを終了できます", "Add more exercises or finish your workout", zhHans: "可以继续记录或结束训练", ko: "추가 종목을 기록하거나 워크아웃을 종료할 수 있습니다", es: "Añade más ejercicios o termina tu entrenamiento", fr: "Ajoutez des exercices ou terminez votre entraînement", de: "Weitere Übungen hinzufügen oder Training beenden") }
    static func exerciseProgress(_ completed: Int, _ total: Int) -> String { loc("\(completed)/\(total) 種目完了", "\(completed)/\(total) exercises done", zhHans: "\(completed)/\(total) 个动作完成", ko: "\(completed)/\(total) 종목 완료", es: "\(completed)/\(total) ejercicios completados", fr: "\(completed)/\(total) exercices terminés", de: "\(completed)/\(total) Übungen fertig") }

    // MARK: - SettingsView (inline)
    static var settingsTrainingExp: String { loc("トレーニング経験", "Training Experience", zhHans: "训练经验", ko: "트레이닝 경험", es: "Experiencia de entrenamiento", fr: "Expérience d'entraînement", de: "Trainingserfahrung") }
    static var settingsExpBeginner: String { loc("これから始める", "Beginner", zhHans: "刚开始", ko: "이제 시작", es: "Principiante", fr: "Débutant", de: "Anfänger") }
    static var settingsExpSixMonths: String { loc("半年くらい", "About 6 months", zhHans: "大约半年", ko: "약 반년", es: "Unos 6 meses", fr: "Environ 6 mois", de: "Etwa 6 Monate") }
    static var settingsExpOneYear: String { loc("1年以上", "1+ years", zhHans: "1年以上", ko: "1년 이상", es: "1+ años", fr: "1+ ans", de: "1+ Jahre") }
    static var settingsExpVeteran: String { loc("3年以上のベテラン", "3+ years veteran", zhHans: "3年以上老手", ko: "3년 이상 베테랑", es: "Veterano de 3+ años", fr: "Vétéran 3+ ans", de: "3+ Jahre Veteran") }
    static var settingsExpLabel: String { loc("経験レベル", "Experience Level", zhHans: "经验等级", ko: "경험 레벨", es: "Nivel de experiencia", fr: "Niveau d'expérience", de: "Erfahrungslevel") }
    static var settingsExpChanged: String { loc("変更しました", "Changes saved", zhHans: "已更改", ko: "변경되었습니다", es: "Cambios guardados", fr: "Modifications enregistrées", de: "Änderungen gespeichert") }
    static var settingsExpMenuHint: String { loc("メニュー提案のセット数・レップ数に影響します", "Affects suggested sets & reps in menu proposals", zhHans: "影响菜单建议的组数和次数", ko: "메뉴 제안의 세트 수·렙 수에 영향", es: "Afecta los sets y reps sugeridos", fr: "Affecte les séries et répétitions suggérées", de: "Beeinflusst vorgeschlagene Sätze & Wiederholungen") }

    // MARK: - ExerciseDictionaryView (inline)
    static var allEquipment: String { loc("全器具", "All", zhHans: "全部器械", ko: "전체 기구", es: "Todo", fr: "Tout", de: "Alle") }
    static var exerciseDictTitle: String { loc("種目辞典", "Exercise Dictionary", zhHans: "动作词典", ko: "종목 사전", es: "Diccionario de ejercicios", fr: "Dictionnaire d'exercices", de: "Übungswörterbuch") }
    static func filteredExercisesCount(_ count: Int) -> String { loc("\(count)種目", "\(count) exercises", zhHans: "\(count)个动作", ko: "\(count)종목", es: "\(count) ejercicios", fr: "\(count) exercices", de: "\(count) Übungen") }

    // MARK: - NotificationManager (inline)
    static func notifRecoveryComplete(_ muscles: String) -> String { loc("💪 \(muscles) 回復完了！", "💪 \(muscles) Recovery Complete!", zhHans: "💪 \(muscles) 恢复完成！", ko: "💪 \(muscles) 회복 완료!", es: "💪 ¡\(muscles) recuperados!", fr: "💪 \(muscles) récupérés !", de: "💪 \(muscles) erholt!") }
    static func notifNextPart(_ part: String) -> String { loc("次は\(part)の日。トレーニングしよう！", "Next is \(part) day. Time to train!", zhHans: "下次是\(part)日。开始训练吧！", ko: "다음은 \(part) 날. 트레이닝하자!", es: "Siguiente: día de \(part). ¡A entrenar!", fr: "Prochain : jour de \(part). Allons-y !", de: "Als nächstes: \(part)-Tag. Los geht's!") }
    static var notifTrainRecoveredMuscles: String { loc("回復した筋肉を鍛えよう！", "Train your recovered muscles!", zhHans: "锻炼恢复好的肌肉吧！", ko: "회복된 근육을 단련하자!", es: "¡Entrena tus músculos recuperados!", fr: "Entraînez vos muscles récupérés !", de: "Trainiere deine erholten Muskeln!") }
    static var notifRecoveryCompleteShort: String { loc("💪 回復完了！", "💪 Recovery Complete!", zhHans: "💪 恢复完成！", ko: "💪 회복 완료!", es: "💪 ¡Recuperación completa!", fr: "💪 Récupération terminée !", de: "💪 Erholung abgeschlossen!") }
    static var notifTimeToTrain: String { loc("トレーニングの時間", "Time to Train", zhHans: "训练时间到了", ko: "트레이닝 시간", es: "Hora de entrenar", fr: "C'est l'heure de s'entraîner", de: "Zeit zu trainieren") }
    static func notifMuscleWaiting(_ muscle: String) -> String { loc("\(muscle)が待ってるぞ 🔥", "\(muscle) is waiting 🔥", zhHans: "\(muscle)在等你 🔥", ko: "\(muscle)이(가) 기다리고 있어 🔥", es: "\(muscle) te espera 🔥", fr: "\(muscle) vous attend 🔥", de: "\(muscle) wartet auf dich 🔥") }
    static var notifTwoDaysOff: String { loc("2日空いたよ。今日やろう 🔥", "2 days off. Let's go today 🔥", zhHans: "已经休息2天了。今天练起来 🔥", ko: "2일 쉬었어. 오늘 하자 🔥", es: "2 días sin entrenar. ¡Vamos hoy! 🔥", fr: "2 jours de repos. Allons-y aujourd'hui 🔥", de: "2 Tage Pause. Los geht's heute 🔥") }
    static var notifWeeklySummary: String { loc("週間サマリー", "Weekly Summary", zhHans: "每周总结", ko: "주간 요약", es: "Resumen semanal", fr: "Résumé hebdomadaire", de: "Wochenzusammenfassung") }
    static func notifWeeklyBody(_ count: Int) -> String { loc("先週は\(count)回トレーニング。今週も頑張ろう！", "Last week: \(count) workouts. Keep it up!", zhHans: "上周训练了\(count)次。这周也加油！", ko: "지난주 \(count)회 트레이닝. 이번 주도 힘내자!", es: "Semana pasada: \(count) entrenamientos. ¡Sigue así!", fr: "Semaine dernière : \(count) entraînements. Continuez !", de: "Letzte Woche: \(count) Trainings. Weiter so!") }
}
