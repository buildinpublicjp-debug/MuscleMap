import Foundation

// MARK: - ユーザープロフィール

struct UserProfile: Codable {
    var nickname: String
    /// 身長（cm）。BMI計算・体格補正に使用。未設定時は170cm
    var heightCm: Double
    /// 体重（kg）。Strength Map計算に使用。未設定時は70kg
    var weightKg: Double
    /// トレーニング経験（オンボーディングで選択）
    var trainingExperience: TrainingExperience
    /// 初期PR入力値（exerciseId: estimated1RM）
    var initialPRs: [String: Double]
    /// 週のトレーニング頻度（2〜5回）
    var weeklyFrequency: Int
    /// トレーニング場所（"gym", "home", "both"）
    var trainingLocation: String
    /// 目標に基づく重点筋肉のrawValue配列（例: ["deltoid_lateral", "chest_upper"]）
    var goalPriorityMuscles: [String]
    /// 目標ごとのスライダー重み（goalId: 0.0〜1.0）
    var goalWeights: [String: Double]

    static let `default` = UserProfile(
        nickname: "",
        heightCm: 170.0,
        weightKg: 70.0,
        trainingExperience: .beginner,
        initialPRs: [:],
        weeklyFrequency: 3,
        trainingLocation: "gym",
        goalPriorityMuscles: [],
        goalWeights: [:]
    )

    /// 既存ユーザーのデータに新フィールドが存在しない場合に対応
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decode(String.self, forKey: .nickname)
        // trainingGoal, experienceLevel は削除済み（OnboardingGoalに移行）
        // 後方互換: 旧データにキーが残っていても無視される
        heightCm = try container.decodeIfPresent(Double.self, forKey: .heightCm) ?? 170.0
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg) ?? 70.0
        trainingExperience = try container.decodeIfPresent(TrainingExperience.self, forKey: .trainingExperience) ?? .beginner
        initialPRs = try container.decodeIfPresent([String: Double].self, forKey: .initialPRs) ?? [:]
        weeklyFrequency = try container.decodeIfPresent(Int.self, forKey: .weeklyFrequency) ?? 3
        trainingLocation = try container.decodeIfPresent(String.self, forKey: .trainingLocation) ?? "gym"
        goalPriorityMuscles = try container.decodeIfPresent([String].self, forKey: .goalPriorityMuscles) ?? []
        goalWeights = try container.decodeIfPresent([String: Double].self, forKey: .goalWeights) ?? [:]
    }

    init(
        nickname: String,
        heightCm: Double = 170.0,
        weightKg: Double = 70.0,
        trainingExperience: TrainingExperience = .beginner,
        initialPRs: [String: Double] = [:],
        weeklyFrequency: Int = 3,
        trainingLocation: String = "gym",
        goalPriorityMuscles: [String] = [],
        goalWeights: [String: Double] = [:]
    ) {
        self.nickname = nickname
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.trainingExperience = trainingExperience
        self.initialPRs = initialPRs
        self.weeklyFrequency = weeklyFrequency
        self.trainingLocation = trainingLocation
        self.goalPriorityMuscles = goalPriorityMuscles
        self.goalWeights = goalWeights
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
