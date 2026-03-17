import Foundation
import SwiftData

// MARK: - ルーティン管理

/// ルーティンの保存・取得・今日のルーティン判定を担当
@MainActor
@Observable
class RoutineManager {
    static let shared = RoutineManager()

    private(set) var routine: UserRoutine

    private init() {
        self.routine = UserRoutine.load()
    }

    /// ルーティンを保存
    func saveRoutine(_ routine: UserRoutine) {
        self.routine = routine
        routine.save()
        #if DEBUG
        print("[RoutineManager] Saved routine with \(routine.days.count) days")
        #endif
    }

    /// ルーティンが存在するか
    var hasRoutine: Bool {
        !routine.days.isEmpty
    }

    /// 今日のルーティン日を取得（直近のワークアウトから次にやるべき日を判定）
    func todayRoutineDay(modelContext: ModelContext) -> RoutineDay? {
        guard hasRoutine else { return nil }

        // 直近セッションのセットを取得
        var descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let lastSession = try? modelContext.fetch(descriptor).first,
              !lastSession.sets.isEmpty else {
            // 履歴なし → 最初の日を返す
            return routine.days.first
        }

        // 直近セッションで鍛えた種目IDを取得
        let lastExerciseIds = Set(lastSession.sets.map { $0.exerciseId })

        // どのルーティン日に最もマッチするか判定
        var bestIndex = 0
        var bestScore = 0
        for (index, day) in routine.days.enumerated() {
            let dayExerciseIds = Set(day.exercises.map { $0.exerciseId })
            let overlap = dayExerciseIds.intersection(lastExerciseIds).count
            if overlap > bestScore {
                bestScore = overlap
                bestIndex = index
            }
        }

        // 次の日を返す（循環）
        let nextIndex = (bestIndex + 1) % routine.days.count
        return routine.days[nextIndex]
    }

    /// ルーティンをリロード（設定変更後などに使用）
    func reload() {
        self.routine = UserRoutine.load()
    }
}
