import Foundation
import SwiftData

// MARK: - インポートデータ変換

/// インポート結果
struct ImportResult: Equatable {
    let sessionsCreated: Int
    let setsCreated: Int
    let unmatchedExercises: [String]
    let duplicatesSkipped: Int
    let errors: [String]

    var isSuccess: Bool { errors.isEmpty }

    var summary: String {
        var lines: [String] = []
        lines.append("\(sessionsCreated)件のワークアウトをインポート")
        lines.append("\(setsCreated)セットを追加")
        if !unmatchedExercises.isEmpty {
            lines.append("未登録の種目: \(unmatchedExercises.joined(separator: ", "))")
        }
        if duplicatesSkipped > 0 {
            lines.append("\(duplicatesSkipped)件の重複をスキップ")
        }
        return lines.joined(separator: "\n")
    }
}

/// インポートプレビュー用
struct ImportPreview {
    let workouts: [ParsedWorkout]
    let matchedExercises: [String: ExerciseDefinition]
    let unmatchedExercises: [String]
    let potentialDuplicates: Int
}

// MARK: - ImportDataConverter

@MainActor
class ImportDataConverter {
    private let modelContext: ModelContext
    private let exerciseStore: ExerciseStore

    init(modelContext: ModelContext, exerciseStore: ExerciseStore) {
        self.modelContext = modelContext
        self.exerciseStore = exerciseStore
    }

    convenience init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, exerciseStore: .shared)
    }

    /// インポートのプレビューを生成（実際のインポートは行わない）
    func preview(_ workouts: [ParsedWorkout]) -> ImportPreview {
        var matchedExercises: [String: ExerciseDefinition] = [:]
        var unmatchedExercises: Set<String> = []

        for workout in workouts {
            for exercise in workout.exercises {
                if let matched = findExercise(name: exercise.name) {
                    matchedExercises[exercise.name] = matched
                } else {
                    unmatchedExercises.insert(exercise.name)
                }
            }
        }

        // 重複チェック（同日のセッションがあるか）
        let duplicates = countPotentialDuplicates(workouts)

        return ImportPreview(
            workouts: workouts,
            matchedExercises: matchedExercises,
            unmatchedExercises: Array(unmatchedExercises).sorted(),
            potentialDuplicates: duplicates
        )
    }

    /// ParsedWorkoutをモデルに変換して保存
    func importWorkouts(_ workouts: [ParsedWorkout], skipDuplicates: Bool = true) -> ImportResult {
        var sessionsCreated = 0
        var setsCreated = 0
        var unmatchedExercises: Set<String> = []
        var duplicatesSkipped = 0
        var errors: [String] = []

        for workout in workouts {
            // 重複チェック
            if skipDuplicates && hasExistingSession(on: workout.date) {
                duplicatesSkipped += 1
                continue
            }

            // セッション作成
            let session = WorkoutSession(
                startDate: workout.date,
                endDate: workout.date.addingTimeInterval(3600) // 1時間後に終了と仮定
            )
            modelContext.insert(session)

            var setNumber = 1
            var muscleSetCounts: [String: Int] = [:]  // 筋肉ごとのセット数
            var muscleMaxIntensity: [String: Double] = [:]  // 筋肉ごとの最大刺激度

            for exercise in workout.exercises {
                guard let matched = findExercise(name: exercise.name) else {
                    unmatchedExercises.insert(exercise.name)
                    continue
                }

                for parsedSet in exercise.sets {
                    let workoutSet = WorkoutSet(
                        session: session,
                        exerciseId: matched.id,
                        setNumber: setNumber,
                        weight: parsedSet.weight,
                        reps: parsedSet.reps,
                        completedAt: workout.date
                    )
                    modelContext.insert(workoutSet)
                    session.sets.append(workoutSet)
                    setsCreated += 1
                    setNumber += 1

                    // 筋肉刺激を集計
                    for (muscleId, intensity) in matched.muscleMapping {
                        let normalizedIntensity = Double(intensity) / 100.0
                        muscleSetCounts[muscleId, default: 0] += 1
                        muscleMaxIntensity[muscleId] = max(
                            muscleMaxIntensity[muscleId] ?? 0,
                            normalizedIntensity
                        )
                    }
                }
            }

            // MuscleStimulationを作成
            for (muscleId, totalSets) in muscleSetCounts {
                let stim = MuscleStimulation(
                    muscle: muscleId,
                    stimulationDate: workout.date,
                    maxIntensity: muscleMaxIntensity[muscleId] ?? 0,
                    totalSets: totalSets,
                    sessionId: session.id
                )
                modelContext.insert(stim)
            }

            sessionsCreated += 1
        }

        // 保存
        do {
            try modelContext.save()
        } catch {
            errors.append("保存エラー: \(error.localizedDescription)")
        }

        return ImportResult(
            sessionsCreated: sessionsCreated,
            setsCreated: setsCreated,
            unmatchedExercises: Array(unmatchedExercises).sorted(),
            duplicatesSkipped: duplicatesSkipped,
            errors: errors
        )
    }

    // MARK: - Private

    /// 種目名からExerciseDefinitionを検索（日本語名・英語名・部分一致）
    private func findExercise(name: String) -> ExerciseDefinition? {
        let normalizedName = name.lowercased()
            .trimmingCharacters(in: .whitespaces)

        // 完全一致（日本語）
        if let exact = exerciseStore.exercises.first(where: {
            $0.nameJA.lowercased() == normalizedName
        }) {
            return exact
        }

        // 完全一致（英語）
        if let exact = exerciseStore.exercises.first(where: {
            $0.nameEN.lowercased() == normalizedName
        }) {
            return exact
        }

        // 部分一致（日本語）
        if let partial = exerciseStore.exercises.first(where: {
            $0.nameJA.lowercased().contains(normalizedName) ||
            normalizedName.contains($0.nameJA.lowercased())
        }) {
            return partial
        }

        // 部分一致（英語）
        if let partial = exerciseStore.exercises.first(where: {
            $0.nameEN.lowercased().contains(normalizedName) ||
            normalizedName.contains($0.nameEN.lowercased())
        }) {
            return partial
        }

        // キーワードマッチング（一般的な種目名の別表記）
        return matchByKeyword(name)
    }

    /// キーワードによるマッチング（別表記対応）
    private func matchByKeyword(_ name: String) -> ExerciseDefinition? {
        let keywords: [(pattern: String, exerciseId: String)] = [
            ("ベンチプレス", "bench_press"),
            ("bench press", "bench_press"),
            ("チンニング", "lat_pulldown"),  // アシストチンニング → ラットプルダウンで代用
            ("懸垂", "lat_pulldown"),
            ("ラットプル", "lat_pulldown"),
            ("lat pull", "lat_pulldown"),
            ("シーテッドロー", "seated_row"),
            ("seated row", "seated_row"),
            ("レッグプレス", "leg_press"),
            ("leg press", "leg_press"),
            ("レッグカール", "leg_curl"),
            ("leg curl", "leg_curl"),
            ("スクワット", "squat"),
            ("squat", "squat"),
            ("デッドリフト", "deadlift"),
            ("deadlift", "deadlift"),
        ]

        let lowerName = name.lowercased()
        for (pattern, exerciseId) in keywords {
            if lowerName.contains(pattern.lowercased()) {
                return exerciseStore.exercise(for: exerciseId)
            }
        }

        return nil
    }

    /// 指定日にセッションが存在するかチェック
    private func hasExistingSession(on date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return false }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate {
                $0.startDate >= dayStart && $0.startDate < dayEnd
            }
        )

        return ((try? modelContext.fetch(descriptor))?.count ?? 0) > 0
    }

    /// 重複の可能性がある日数をカウント
    private func countPotentialDuplicates(_ workouts: [ParsedWorkout]) -> Int {
        var count = 0
        for workout in workouts {
            if hasExistingSession(on: workout.date) {
                count += 1
            }
        }
        return count
    }
}
