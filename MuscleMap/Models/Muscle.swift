import Foundation

// MARK: - 筋肉定義（21筋肉）

enum Muscle: String, CaseIterable, Codable, Identifiable {
    // 胸（2）
    case chestUpper = "chest_upper"
    case chestLower = "chest_lower"
    // 背中（4）
    case lats = "lats"
    case trapsUpper = "traps_upper"
    case trapsMiddleLower = "traps_middle_lower"
    case erectorSpinae = "erector_spinae"
    // 肩（3）
    case deltoidAnterior = "deltoid_anterior"
    case deltoidLateral = "deltoid_lateral"
    case deltoidPosterior = "deltoid_posterior"
    // 腕（3）
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"
    // 体幹（2）
    case rectusAbdominis = "rectus_abdominis"
    case obliques = "obliques"
    // 下半身（7）
    case glutes = "glutes"
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case adductors = "adductors"
    case hipFlexors = "hip_flexors"
    case gastrocnemius = "gastrocnemius"
    case soleus = "soleus"

    var id: String { rawValue }

    // 日本語名
    var japaneseName: String {
        switch self {
        case .chestUpper: return "大胸筋上部"
        case .chestLower: return "大胸筋下部"
        case .lats: return "広背筋"
        case .trapsUpper: return "僧帽筋上部"
        case .trapsMiddleLower: return "僧帽筋中部・下部"
        case .erectorSpinae: return "脊柱起立筋"
        case .deltoidAnterior: return "三角筋前部"
        case .deltoidLateral: return "三角筋中部"
        case .deltoidPosterior: return "三角筋後部"
        case .biceps: return "上腕二頭筋"
        case .triceps: return "上腕三頭筋"
        case .forearms: return "前腕筋群"
        case .rectusAbdominis: return "腹直筋"
        case .obliques: return "腹斜筋"
        case .glutes: return "臀筋群"
        case .quadriceps: return "大腿四頭筋"
        case .hamstrings: return "ハムストリングス"
        case .adductors: return "内転筋群"
        case .hipFlexors: return "腸腰筋"
        case .gastrocnemius: return "腓腹筋"
        case .soleus: return "ヒラメ筋"
        }
    }

    // 英語名
    var englishName: String {
        switch self {
        case .chestUpper: return "Upper Chest"
        case .chestLower: return "Lower Chest"
        case .lats: return "Latissimus Dorsi"
        case .trapsUpper: return "Upper Traps"
        case .trapsMiddleLower: return "Mid/Lower Traps"
        case .erectorSpinae: return "Erector Spinae"
        case .deltoidAnterior: return "Front Delts"
        case .deltoidLateral: return "Side Delts"
        case .deltoidPosterior: return "Rear Delts"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .rectusAbdominis: return "Rectus Abdominis"
        case .obliques: return "Obliques"
        case .glutes: return "Glutes"
        case .quadriceps: return "Quadriceps"
        case .hamstrings: return "Hamstrings"
        case .adductors: return "Adductors"
        case .hipFlexors: return "Hip Flexors"
        case .gastrocnemius: return "Gastrocnemius"
        case .soleus: return "Soleus"
        }
    }

    // 中国語名（簡体字）
    var chineseName: String {
        switch self {
        case .chestUpper: return "胸大肌上束"
        case .chestLower: return "胸大肌下束"
        case .lats: return "背阔肌"
        case .trapsUpper: return "斜方肌上束"
        case .trapsMiddleLower: return "斜方肌中下束"
        case .erectorSpinae: return "竖脊肌"
        case .deltoidAnterior: return "三角肌前束"
        case .deltoidLateral: return "三角肌中束"
        case .deltoidPosterior: return "三角肌后束"
        case .biceps: return "肱二头肌"
        case .triceps: return "肱三头肌"
        case .forearms: return "前臂肌群"
        case .rectusAbdominis: return "腹直肌"
        case .obliques: return "腹斜肌"
        case .glutes: return "臀肌群"
        case .quadriceps: return "股四头肌"
        case .hamstrings: return "腘绳肌"
        case .adductors: return "内收肌群"
        case .hipFlexors: return "髂腰肌"
        case .gastrocnemius: return "腓肠肌"
        case .soleus: return "比目鱼肌"
        }
    }

    // 韓国語名
    var koreanName: String {
        switch self {
        case .chestUpper: return "대흉근 상부"
        case .chestLower: return "대흉근 하부"
        case .lats: return "광배근"
        case .trapsUpper: return "승모근 상부"
        case .trapsMiddleLower: return "승모근 중·하부"
        case .erectorSpinae: return "척추기립근"
        case .deltoidAnterior: return "삼각근 전면"
        case .deltoidLateral: return "삼각근 측면"
        case .deltoidPosterior: return "삼각근 후면"
        case .biceps: return "이두근"
        case .triceps: return "삼두근"
        case .forearms: return "전완근"
        case .rectusAbdominis: return "복직근"
        case .obliques: return "복사근"
        case .glutes: return "둔근"
        case .quadriceps: return "대퇴사두근"
        case .hamstrings: return "햄스트링"
        case .adductors: return "내전근"
        case .hipFlexors: return "장요근"
        case .gastrocnemius: return "비복근"
        case .soleus: return "가자미근"
        }
    }

    /// ローカライズ名（現在の言語設定に応じて返す）
    #if os(watchOS)
    var localizedName: String { japaneseName }
    #else
    @MainActor
    var localizedName: String {
        switch LocalizationManager.shared.currentLanguage {
        case .japanese: return japaneseName
        case .chineseSimplified: return chineseName
        case .korean: return koreanName
        case .english, .spanish, .french, .german: return englishName
        }
    }
    #endif

    // 所属グループ
    var group: MuscleGroup {
        switch self {
        case .chestUpper, .chestLower:
            return .chest
        case .lats, .trapsUpper, .trapsMiddleLower, .erectorSpinae:
            return .back
        case .deltoidAnterior, .deltoidLateral, .deltoidPosterior:
            return .shoulders
        case .biceps, .triceps, .forearms:
            return .arms
        case .rectusAbdominis, .obliques:
            return .core
        case .glutes, .quadriceps, .hamstrings, .adductors, .hipFlexors,
             .gastrocnemius, .soleus:
            return .lowerBody
        }
    }

    /// 基準回復時間（時間）。ボリューム係数で調整される
    var baseRecoveryHours: Int {
        switch self {
        // 大筋群: 72h
        case .lats, .trapsUpper, .trapsMiddleLower, .erectorSpinae,
             .glutes, .quadriceps, .hamstrings, .adductors, .hipFlexors:
            return 72
        // 中筋群: 48h
        case .chestUpper, .chestLower,
             .deltoidAnterior, .deltoidLateral, .deltoidPosterior,
             .biceps, .triceps:
            return 48
        // 小筋群: 24h
        case .forearms, .rectusAbdominis, .obliques,
             .gastrocnemius, .soleus:
            return 24
        }
    }
}

// MARK: - 筋肉グループ

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest
    case back
    case shoulders
    case arms
    case core
    case lowerBody

    var id: String { rawValue }

    // 日本語名
    var japaneseName: String {
        switch self {
        case .chest: return "胸"
        case .back: return "背中"
        case .shoulders: return "肩"
        case .arms: return "腕"
        case .core: return "体幹"
        case .lowerBody: return "下半身"
        }
    }

    // 英語名
    var englishName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .core: return "Core"
        case .lowerBody: return "Lower Body"
        }
    }

    // 中国語名（簡体字）
    var chineseName: String {
        switch self {
        case .chest: return "胸"
        case .back: return "背"
        case .shoulders: return "肩"
        case .arms: return "臂"
        case .core: return "核心"
        case .lowerBody: return "下肢"
        }
    }

    // 韓国語名
    var koreanName: String {
        switch self {
        case .chest: return "가슴"
        case .back: return "등"
        case .shoulders: return "어깨"
        case .arms: return "팔"
        case .core: return "코어"
        case .lowerBody: return "하체"
        }
    }

    /// 短縮英語名（タイムラインバー等の狭いスペース用）
    var shortEnglishName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shldr"
        case .arms: return "Arms"
        case .core: return "Core"
        case .lowerBody: return "Legs"
        }
    }

    /// ローカライズ名（現在の言語設定に応じて返す）
    #if os(watchOS)
    var localizedName: String { japaneseName }
    #else
    @MainActor
    var localizedName: String {
        switch LocalizationManager.shared.currentLanguage {
        case .japanese: return japaneseName
        case .chineseSimplified: return chineseName
        case .korean: return koreanName
        case .english, .spanish, .french, .german: return englishName
        }
    }
    #endif

    /// このグループに属する筋肉一覧
    var muscles: [Muscle] {
        Muscle.allCases.filter { $0.group == self }
    }
}
