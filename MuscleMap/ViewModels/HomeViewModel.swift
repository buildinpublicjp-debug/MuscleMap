import Foundation
import SwiftData

// MARK: - ホーム画面ViewModel

@MainActor
@Observable
class HomeViewModel {
    private let muscleStateRepo: MuscleStateRepository
    private let workoutRepo: WorkoutRepository

    // 筋肉の視覚状態
    var muscleStates: [Muscle: MuscleVisualState] = [:]
    // 未刺激警告がある筋肉
    var neglectedMuscles: [Muscle] = []
    // 進行中のセッション
    var activeSession: WorkoutSession?
    // 継続日数
    var streakDays: Int = 0

    init(modelContext: ModelContext) {
        self.muscleStateRepo = MuscleStateRepository(modelContext: modelContext)
        self.workoutRepo = WorkoutRepository(modelContext: modelContext)
    }

    /// 筋肉状態を読み込む
    func loadMuscleStates() {
        let stimulations = muscleStateRepo.fetchLatestStimulations()
        var states: [Muscle: MuscleVisualState] = [:]
        var neglected: [Muscle] = []

        for muscle in Muscle.allCases {
            if let stim = stimulations[muscle] {
                let status = RecoveryCalculator.recoveryStatus(
                    stimulationDate: stim.stimulationDate,
                    muscle: muscle,
                    totalSets: stim.totalSets
                )
                states[muscle] = status.visualState

                if case .neglected = status {
                    neglected.append(muscle)
                } else if case .neglectedSevere = status {
                    neglected.append(muscle)
                }
            } else {
                // 刺激記録なし → inactive
                states[muscle] = .inactive
            }
        }

        muscleStates = states
        neglectedMuscles = neglected
    }

    /// 進行中セッションをチェック
    func checkActiveSession() {
        activeSession = workoutRepo.fetchActiveSession()
    }

    /// 継続日数を計算
    func calculateStreak() {
        let sessions = workoutRepo.fetchRecentSessions(limit: 100)
        guard !sessions.isEmpty else {
            streakDays = 0
            return
        }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for session in sessions {
            let sessionDay = calendar.startOfDay(for: session.startDate)
            if sessionDay == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if sessionDay < checkDate {
                break
            }
        }

        streakDays = streak
    }
}
