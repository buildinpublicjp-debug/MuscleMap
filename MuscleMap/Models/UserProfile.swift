import Foundation

// MARK: - ユーザープロフィール

struct UserProfile: Codable {
    var nickname: String
    var trainingGoal: TrainingGoal
    var experienceLevel: ExperienceLevel
    /// 体重（kg）。Strength Map計算に使用。未設定時は70kg
    var weightKg: Double
    /// トレーニング経験（オンボーディングで選択）
    var trainingExperience: TrainingExperience
    /// 初期PR入力値（exerciseId: estimated1RM）
    var initialPRs: [String: Double]

    static let `default` = UserProfile(
        nickname: "",
        trainingGoal: .hypertrophy,
        experienceLevel: .beginner,
        weightKg: 70.0,
        trainingExperience: .beginner,
        initialPRs: [:]
    )

    /// 既存ユーザーのデータに新フィールドが存在しない場合に対応
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decode(String.self, forKey: .nickname)
        trainingGoal = try container.decode(TrainingGoal.self, forKey: .trainingGoal)
        experienceLevel = try container.decode(ExperienceLevel.self, forKey: .experienceLevel)
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg) ?? 70.0
        trainingExperience = try container.decodeIfPresent(TrainingExperience.self, forKey: .trainingExperience) ?? .beginner
        initialPRs = try container.decodeIfPresent([String: Double].self, forKey: .initialPRs) ?? [:]
    }

    init(
        nickname: String,
        trainingGoal: TrainingGoal,
        experienceLevel: ExperienceLevel,
        weightKg: Double = 70.0,
        trainingExperience: TrainingExperience = .beginner,
        initialPRs: [String: Double] = [:]
    ) {
        self.nickname = nickname
        self.trainingGoal = trainingGoal
        self.experienceLevel = experienceLevel
        self.weightKg = weightKg
        self.trainingExperience = trainingExperience
        self.initialPRs = initialPRs
    }
}

// MARK: - トレーニング目標

enum TrainingGoal: String, Codable, CaseIterable, Identifiable {
    case hypertrophy     // 筋肥大
    case strength        // 筋力アップ
    case diet            // ダイエット
    case health          // 健康維持

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .hypertrophy: return String(localized: "筋肥大")
        case .strength: return String(localized: "筋力アップ")
        case .diet: return String(localized: "ダイエット")
        case .health: return String(localized: "健康維持")
        }
    }

    var icon: String {
        switch self {
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .strength: return "bolt.fill"
        case .diet: return "flame.fill"
        case .health: return "heart.fill"
        }
    }

    var descriptionText: String {
        switch self {
        case .hypertrophy: return String(localized: "筋肉を大きくしたい")
        case .strength: return String(localized: "重い重量を扱えるようになりたい")
        case .diet: return String(localized: "体脂肪を落としたい")
        case .health: return String(localized: "健康的な体を維持したい")
        }
    }
}

// MARK: - 経験レベル

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner       // 初心者
    case intermediate   // 中級者
    case advanced       // 上級者

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .beginner: return String(localized: "初心者")
        case .intermediate: return String(localized: "中級者")
        case .advanced: return String(localized: "上級者")
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        }
    }

    var descriptionText: String {
        switch self {
        case .beginner: return String(localized: "トレーニング歴1年未満")
        case .intermediate: return String(localized: "トレーニング歴1〜3年")
        case .advanced: return String(localized: "トレーニング歴3年以上")
        }
    }
}

// MARK: - トレーニング経験（オンボーディング用）

enum TrainingExperience: String, Codable, CaseIterable, Identifiable {
    case beginner       // これから始める
    case halfYear       // 半年くらい
    case oneYearPlus    // 1年以上
    case veteran        // 3年以上のベテラン

    var id: String { rawValue }

    /// PR入力ページを表示するか
    var shouldShowPRInput: Bool {
        self == .oneYearPlus || self == .veteran
    }
}

// MARK: - UserDefaults永続化

extension UserProfile {
    private static let storageKey = "userProfile"

    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            #if DEBUG
            print("[UserProfile] Failed to decode: \(error)")
            #endif
            return .default
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            #if DEBUG
            print("[UserProfile] Failed to encode: \(error)")
            #endif
        }
    }
}
