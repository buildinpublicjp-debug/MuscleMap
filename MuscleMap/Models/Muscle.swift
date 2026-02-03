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

    // ローカライズ名
    var localizedName: String {
        switch self {
        case .chestUpper: return String(localized: "大胸筋上部")
        case .chestLower: return String(localized: "大胸筋下部")
        case .lats: return String(localized: "広背筋")
        case .trapsUpper: return String(localized: "僧帽筋上部")
        case .trapsMiddleLower: return String(localized: "僧帽筋中部・下部")
        case .erectorSpinae: return String(localized: "脊柱起立筋")
        case .deltoidAnterior: return String(localized: "三角筋前部")
        case .deltoidLateral: return String(localized: "三角筋中部")
        case .deltoidPosterior: return String(localized: "三角筋後部")
        case .biceps: return String(localized: "上腕二頭筋")
        case .triceps: return String(localized: "上腕三頭筋")
        case .forearms: return String(localized: "前腕筋群")
        case .rectusAbdominis: return String(localized: "腹直筋")
        case .obliques: return String(localized: "腹斜筋")
        case .glutes: return String(localized: "臀筋群")
        case .quadriceps: return String(localized: "大腿四頭筋")
        case .hamstrings: return String(localized: "ハムストリングス")
        case .adductors: return String(localized: "内転筋群")
        case .hipFlexors: return String(localized: "腸腰筋")
        case .gastrocnemius: return String(localized: "腓腹筋")
        case .soleus: return String(localized: "ヒラメ筋")
        }
    }

    /// 後方互換エイリアス
    var japaneseName: String { localizedName }

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

    var localizedName: String {
        switch self {
        case .chest: return String(localized: "胸")
        case .back: return String(localized: "背中")
        case .shoulders: return String(localized: "肩")
        case .arms: return String(localized: "腕")
        case .core: return String(localized: "体幹")
        case .lowerBody: return String(localized: "下半身")
        }
    }

    /// 後方互換エイリアス
    var japaneseName: String { localizedName }

    /// このグループに属する筋肉一覧
    var muscles: [Muscle] {
        Muscle.allCases.filter { $0.group == self }
    }
}
