import Foundation

// MARK: - エクササイズ定義（exercises.jsonから読み込み）

struct ExerciseDefinition: Codable, Identifiable, Hashable {
    let id: String
    let nameEN: String
    let nameJA: String
    let nameZH: String?  // 中国語（簡体字）
    let nameKO: String?  // 韓国語
    let nameES: String?  // スペイン語
    let nameFR: String?  // フランス語
    let nameDE: String?  // ドイツ語
    let category: String
    let equipment: String
    let difficulty: String
    /// muscle_id → 刺激度% (20-100)
    let muscleMapping: [String: Int]
    /// 種目タイプ: "weighted" | "bodyweight" | "assisted"
    let exerciseType: String

    // MARK: - メンバーワイズイニシャライザ（Preview/Test用）

    init(
        id: String, nameEN: String, nameJA: String,
        nameZH: String? = nil, nameKO: String? = nil,
        nameES: String? = nil, nameFR: String? = nil, nameDE: String? = nil,
        category: String, equipment: String, difficulty: String,
        muscleMapping: [String: Int], exerciseType: String = "weighted"
    ) {
        self.id = id; self.nameEN = nameEN; self.nameJA = nameJA
        self.nameZH = nameZH; self.nameKO = nameKO
        self.nameES = nameES; self.nameFR = nameFR; self.nameDE = nameDE
        self.category = category; self.equipment = equipment
        self.difficulty = difficulty; self.muscleMapping = muscleMapping
        self.exerciseType = exerciseType
    }

    // MARK: - デコード（exerciseType後方互換）

    private enum CodingKeys: String, CodingKey {
        case id, nameEN, nameJA, nameZH, nameKO, nameES, nameFR, nameDE
        case category, equipment, difficulty, muscleMapping, exerciseType
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        nameEN = try c.decode(String.self, forKey: .nameEN)
        nameJA = try c.decode(String.self, forKey: .nameJA)
        nameZH = try c.decodeIfPresent(String.self, forKey: .nameZH)
        nameKO = try c.decodeIfPresent(String.self, forKey: .nameKO)
        nameES = try c.decodeIfPresent(String.self, forKey: .nameES)
        nameFR = try c.decodeIfPresent(String.self, forKey: .nameFR)
        nameDE = try c.decodeIfPresent(String.self, forKey: .nameDE)
        category = try c.decode(String.self, forKey: .category)
        equipment = try c.decode(String.self, forKey: .equipment)
        difficulty = try c.decode(String.self, forKey: .difficulty)
        muscleMapping = try c.decode([String: Int].self, forKey: .muscleMapping)
        exerciseType = try c.decodeIfPresent(String.self, forKey: .exerciseType) ?? "weighted"
    }

    // MARK: - 種目タイプ判定

    /// 体重ベース種目か
    var isBodyweight: Bool { exerciseType == "bodyweight" }

    /// アシスト種目か（kg低い=強い）
    var isAssisted: Bool { exerciseType == "assisted" }

    /// Strength Score計算から除外すべきか（時間/有酸素ベース）
    var isStrengthScoreExcluded: Bool {
        ["plank", "side_plank", "mountain_climber", "bicycle_crunch", "ab_roller", "burpee"].contains(id)
    }

    /// 主要ターゲット筋肉（刺激度が最も高い筋肉）
    var primaryMuscle: Muscle? {
        guard let maxEntry = muscleMapping.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return Muscle(rawValue: maxEntry.key)
    }

    /// この種目がターゲットとする全筋肉（Muscle enumに変換）
    var targetMuscles: [Muscle] {
        muscleMapping.keys.compactMap { Muscle(rawValue: $0) }
    }

    /// 指定筋肉への刺激度%を返す（0の場合はターゲットでない）
    func stimulationPercentage(for muscle: Muscle) -> Int {
        muscleMapping[muscle.rawValue] ?? 0
    }
}

// MARK: - ローカライズ済みプロパティ

#if !os(watchOS)
extension ExerciseDefinition {
    /// ローカライズされた種目名
    @MainActor var localizedName: String {
        switch LocalizationManager.shared.currentLanguage {
        case .japanese:
            return nameJA
        case .english:
            return nameEN
        case .chineseSimplified:
            return nameZH ?? nameEN
        case .korean:
            return nameKO ?? nameEN
        case .spanish:
            return nameES ?? nameEN
        case .french:
            return nameFR ?? nameEN
        case .german:
            return nameDE ?? nameEN
        }
    }

    /// セカンダリ言語の種目名（日本語選択時は英語、それ以外は日本語）
    @MainActor var secondaryLocalizedName: String {
        switch LocalizationManager.shared.currentLanguage {
        case .japanese:
            return nameEN
        default:
            return nameJA
        }
    }

    /// ローカライズされたカテゴリ名
    @MainActor var localizedCategory: String {
        L10n.localizedCategory(category)
    }

    /// ローカライズされた器具名
    @MainActor var localizedEquipment: String {
        L10n.localizedEquipment(equipment)
    }

    /// ローカライズされた難易度
    @MainActor var localizedDifficulty: String {
        L10n.localizedDifficulty(difficulty)
    }
}
#endif
