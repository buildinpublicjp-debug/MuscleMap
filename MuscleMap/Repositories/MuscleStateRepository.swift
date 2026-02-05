import Foundation
import SwiftData

// MARK: - 筋肉状態リポジトリ

@MainActor
class MuscleStateRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 全筋肉の最新刺激記録を取得（1クエリで全件取得し、Swift側で最新を抽出）
    func fetchLatestStimulations() -> [Muscle: MuscleStimulation] {
        let descriptor = FetchDescriptor<MuscleStimulation>(
            sortBy: [SortDescriptor(\.stimulationDate, order: .reverse)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []

        var result: [Muscle: MuscleStimulation] = [:]
        for stim in all {
            guard let muscle = Muscle(rawValue: stim.muscle) else { continue }
            if result[muscle] == nil {
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
        do {
            try modelContext.save()
        } catch {
            print("[MuscleStateRepository] Failed to save stimulation: \(error)")
        }
    }

    /// 既存の刺激記録を更新（同日・同筋肉・同セッション）
    /// saveImmediately=false でバッチ処理時にsaveを遅延可能
    func upsertStimulation(
        muscle: Muscle,
        sessionId: UUID,
        maxIntensity: Double,
        totalSets: Int,
        saveImmediately: Bool = true
    ) {
        let muscleRaw = muscle.rawValue
        let descriptor = FetchDescriptor<MuscleStimulation>(
            predicate: #Predicate {
                $0.muscle == muscleRaw && $0.sessionId == sessionId
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.maxIntensity = max(existing.maxIntensity, maxIntensity)
            existing.totalSets = totalSets
        } else {
            let stim = MuscleStimulation(
                muscle: muscleRaw,
                maxIntensity: maxIntensity,
                totalSets: totalSets,
                sessionId: sessionId
            )
            modelContext.insert(stim)
        }

        if saveImmediately {
            do {
                try modelContext.save()
            } catch {
                print("[MuscleStateRepository] Failed to upsert stimulation: \(error)")
            }
        }
    }

    /// コンテキストを保存（バッチ処理の最後に呼ぶ）
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("[MuscleStateRepository] Failed to save: \(error)")
        }
    }

    /// 指定セッションの刺激記録を全削除
    func deleteStimulations(sessionId: UUID) {
        let descriptor = FetchDescriptor<MuscleStimulation>(
            predicate: #Predicate { $0.sessionId == sessionId }
        )
        do {
            let stimulations = try modelContext.fetch(descriptor)
            for stim in stimulations {
                modelContext.delete(stim)
            }
            try modelContext.save()
        } catch {
            print("[MuscleStateRepository] Failed to delete stimulations: \(error)")
        }
    }
}
