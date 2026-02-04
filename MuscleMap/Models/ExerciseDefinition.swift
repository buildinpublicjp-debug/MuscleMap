import Foundation

// MARK: - エクササイズ定義（exercises.jsonから読み込み）

struct ExerciseDefinition: Codable, Identifiable, Hashable {
    let id: String
    let nameEN: String
    let nameJA: String
    let category: String
    let equipment: String
    let difficulty: String
    /// muscle_id → 刺激度% (20-100)
    let muscleMapping: [String: Int]

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

extension ExerciseDefinition {
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
