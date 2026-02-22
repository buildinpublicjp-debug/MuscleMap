import Foundation
import SwiftData

// MARK: - Watch受信データの処理（Swift Dataへの保存）

@MainActor
final class WatchDataProcessor {
    private let modelContext: ModelContext
    private let muscleRepo: MuscleStateRepository

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.muscleRepo = MuscleStateRepository(modelContext: modelContext)
    }

    // MARK: - メイン処理

    /// transferUserInfoで受信した辞書を解析・保存する
    func process(_ userInfo: [String: Any]) {
        guard let record = WatchSyncRecord.from(userInfo) else {
            #if DEBUG
            print("[WatchDataProcessor] Failed to parse WatchSyncRecord from userInfo")
            #endif
            return
        }

        switch record.type {
        case .sessionStart:
            handleSessionStart(record)
        case .setRecorded:
            handleSetRecorded(record)
        case .sessionEnd:
            handleSessionEnd(record)
        }
    }

    // MARK: - セッション開始

    /// ワークアウトセッションをSwift Dataに作成
    private func handleSessionStart(_ record: WatchSyncRecord) {
        guard let sessionUUID = UUID(uuidString: record.sessionId) else {
            #if DEBUG
            print("[WatchDataProcessor] Invalid sessionId: \(record.sessionId)")
            #endif
            return
        }

        // 既存セッションの重複チェック
        let existingDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.id == sessionUUID }
        )
        do {
            let existing = try modelContext.fetch(existingDescriptor)
            if !existing.isEmpty {
                #if DEBUG
                print("[WatchDataProcessor] Session already exists: \(record.sessionId)")
                #endif
                return
            }
        } catch {
            #if DEBUG
            print("[WatchDataProcessor] Failed to check existing session: \(error)")
            #endif
        }

        let session = WorkoutSession(
            id: sessionUUID,
            startDate: Date(timeIntervalSince1970: record.timestamp)
        )
        modelContext.insert(session)
        saveContext()

        #if DEBUG
        print("[WatchDataProcessor] Created WorkoutSession: \(record.sessionId)")
        #endif
    }

    // MARK: - セット記録

    /// ワークアウトセットを作成し、筋肉刺激を更新
    private func handleSetRecorded(_ record: WatchSyncRecord) {
        guard let sessionUUID = UUID(uuidString: record.sessionId),
              let setIdString = record.setId,
              let setUUID = UUID(uuidString: setIdString),
              let exerciseId = record.exerciseId,
              let setNumber = record.setNumber,
              let weight = record.weight,
              let reps = record.reps else {
            #if DEBUG
            print("[WatchDataProcessor] Incomplete set record data")
            #endif
            return
        }

        // 親セッションを取得
        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.id == sessionUUID }
        )
        let session: WorkoutSession?
        do {
            session = try modelContext.fetch(sessionDescriptor).first
        } catch {
            #if DEBUG
            print("[WatchDataProcessor] Failed to fetch session: \(error)")
            #endif
            session = nil
        }

        guard let session else {
            #if DEBUG
            print("[WatchDataProcessor] Session not found for set: \(record.sessionId)")
            #endif
            return
        }

        // セットの重複チェック
        let existingSetDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.id == setUUID }
        )
        do {
            let existingSets = try modelContext.fetch(existingSetDescriptor)
            if !existingSets.isEmpty {
                #if DEBUG
                print("[WatchDataProcessor] Set already exists: \(setIdString)")
                #endif
                return
            }
        } catch {
            #if DEBUG
            print("[WatchDataProcessor] Failed to check existing set: \(error)")
            #endif
        }

        // WorkoutSetを作成
        let workoutSet = WorkoutSet(
            id: setUUID,
            session: session,
            exerciseId: exerciseId,
            setNumber: setNumber,
            weight: weight,
            reps: reps,
            completedAt: Date(timeIntervalSince1970: record.timestamp)
        )
        modelContext.insert(workoutSet)

        // 筋肉刺激の更新（muscleMappingに基づく）
        updateMuscleStimulations(
            exerciseId: exerciseId,
            sessionId: sessionUUID,
            session: session
        )

        saveContext()

        #if DEBUG
        print("[WatchDataProcessor] Recorded set: \(exerciseId) #\(setNumber) \(weight)kg x \(reps)")
        #endif
    }

    // MARK: - セッション終了

    /// セッションの終了日時を設定し、ウィジェットデータを更新
    private func handleSessionEnd(_ record: WatchSyncRecord) {
        guard let sessionUUID = UUID(uuidString: record.sessionId) else {
            #if DEBUG
            print("[WatchDataProcessor] Invalid sessionId for end: \(record.sessionId)")
            #endif
            return
        }

        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.id == sessionUUID }
        )

        do {
            guard let session = try modelContext.fetch(sessionDescriptor).first else {
                #if DEBUG
                print("[WatchDataProcessor] Session not found for end: \(record.sessionId)")
                #endif
                return
            }
            session.endDate = Date(timeIntervalSince1970: record.timestamp)
            saveContext()

            #if DEBUG
            print("[WatchDataProcessor] Ended session: \(record.sessionId)")
            #endif

            // ウィジェットデータを更新
            updateWidgetData()

        } catch {
            #if DEBUG
            print("[WatchDataProcessor] Failed to end session: \(error)")
            #endif
        }
    }

    // MARK: - 筋肉刺激の更新

    /// エクササイズのmuscleMappingに基づき、各筋肉の刺激記録を更新
    private func updateMuscleStimulations(
        exerciseId: String,
        sessionId: UUID,
        session: WorkoutSession
    ) {
        let store = ExerciseStore.shared
        store.loadIfNeeded()

        guard let exercise = store.exercise(for: exerciseId) else {
            #if DEBUG
            print("[WatchDataProcessor] Exercise not found: \(exerciseId)")
            #endif
            return
        }

        // このセッションでの該当筋肉の合計セット数を計算
        let sessionSets = session.sets

        for (muscleRaw, intensityPercent) in exercise.muscleMapping {
            guard let muscle = Muscle(rawValue: muscleRaw) else { continue }

            // この筋肉に関連するセット数をカウント（同セッション内の全種目）
            let muscleSetCount = countMuscleSets(
                muscle: muscleRaw,
                sessionSets: sessionSets
            )

            // 刺激度を0.0-1.0に変換
            let maxIntensity = Double(intensityPercent) / 100.0

            muscleRepo.upsertStimulation(
                muscle: muscle,
                sessionId: sessionId,
                maxIntensity: maxIntensity,
                totalSets: muscleSetCount,
                saveImmediately: false
            )
        }

        muscleRepo.save()
    }

    /// 指定筋肉に関連するセット数をカウント
    private func countMuscleSets(muscle muscleRaw: String, sessionSets: [WorkoutSet]) -> Int {
        let store = ExerciseStore.shared
        var count = 0

        for set in sessionSets {
            if let exercise = store.exercise(for: set.exerciseId),
               exercise.muscleMapping[muscleRaw] != nil {
                count += 1
            }
        }

        return max(count, 1) // 最低1セット
    }

    // MARK: - ウィジェットデータ更新

    /// 最新の筋肉状態からウィジェット用データを生成・書き込み
    private func updateWidgetData() {
        let latestStimulations = muscleRepo.fetchLatestStimulations()

        var muscleStates: [Muscle: MuscleVisualState] = [:]

        for muscle in Muscle.allCases {
            guard let stim = latestStimulations[muscle] else {
                muscleStates[muscle] = .inactive
                continue
            }

            let status = RecoveryCalculator.recoveryStatus(
                stimulationDate: stim.stimulationDate,
                muscle: muscle,
                totalSets: stim.totalSets
            )

            switch status {
            case .recovering(let progress):
                muscleStates[muscle] = .recovering(progress: progress)
            case .fullyRecovered:
                muscleStates[muscle] = .inactive
            case .neglected:
                muscleStates[muscle] = .neglected(fast: false)
            case .neglectedSevere:
                muscleStates[muscle] = .neglected(fast: true)
            }
        }

        WidgetDataProvider.updateWidgetData(muscleStates: muscleStates)

        #if DEBUG
        print("[WatchDataProcessor] Widget data updated")
        #endif
    }

    // MARK: - ユーティリティ

    /// ModelContextを保存
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[WatchDataProcessor] Failed to save context: \(error)")
            #endif
        }
    }
}
