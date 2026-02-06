import Foundation

// MARK: - ユーザープロフィール

struct UserProfile: Codable {
    var nickname: String
    var trainingGoal: TrainingGoal
    var experienceLevel: ExperienceLevel

    static let `default` = UserProfile(
        nickname: "",
        trainingGoal: .hypertrophy,
        experienceLevel: .beginner
    )
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
