import Foundation
import SwiftData

// MARK: - 筋肉状態リポジトリ

@MainActor
class MuscleStateRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 全筋肉の最新刺激記録を取得
    func fetchLatestStimulations() -> [Muscle: MuscleStimulation] {
        var result: [Muscle: MuscleStimulation] = [:]

        for muscle in Muscle.allCases {
            let muscleRaw = muscle.rawValue
            var descriptor = FetchDescriptor<MuscleStimulation>(
                predicate: #Predicate { $0.muscle == muscleRaw },
                sortBy: [SortDescriptor(\.stimulationDate, order: .reverse)]
            )
            descriptor.fetchLimit = 1

            if let stim = try? modelContext.fetch(descriptor).first {
                result[muscle] = stim
            }
        }

        return result
    }

    /// 指定筋肉の最新刺激記録を取得
    func fetchLatestStimulation(for muscle: Muscle) -> MuscleStimulation? {
        let muscleRaw = muscle.rawValue
        var descriptor = FetchDescriptor<MuscleStimulation>(
            predicate: #Predicate { $0.muscle == muscleRaw },
            sortBy: [SortDescriptor(\.stimulationDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    /// 刺激記録を保存
    func saveStimulation(_ stimulation: MuscleStimulation) {
        modelContext.insert(stimulation)
        try? modelContext.save()
    }

    /// 既存の刺激記録を更新（同日・同筋肉・同セッション）
    func upsertStimulation(
        muscle: Muscle,
        sessionId: UUID,
        maxIntensity: Double,
        totalSets: Int
    ) {
        let muscleRaw = muscle.rawValue
        let descriptor = FetchDescriptor<MuscleStimulation>(
            predicate: #Predicate {
                $0.muscle == muscleRaw && $0.sessionId == sessionId
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            // 既存のレコードを更新
            existing.maxIntensity = max(existing.maxIntensity, maxIntensity)
            existing.totalSets = totalSets
        } else {
            // 新規作成
            let stim = MuscleStimulation(
                muscle: muscleRaw,
                maxIntensity: maxIntensity,
                totalSets: totalSets,
                sessionId: sessionId
            )
            modelContext.insert(stim)
        }
        try? modelContext.save()
    }

    /// 指定セッションの刺激記録を全削除
    func deleteStimulations(sessionId: UUID) {
        let descriptor = FetchDescriptor<MuscleStimulation>(
            predicate: #Predicate { $0.sessionId == sessionId }
        )
        if let stimulations = try? modelContext.fetch(descriptor) {
            for stim in stimulations {
                modelContext.delete(stim)
            }
            try? modelContext.save()
        }
    }
}
