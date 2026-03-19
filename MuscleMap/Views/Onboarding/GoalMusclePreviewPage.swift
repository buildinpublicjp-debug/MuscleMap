import SwiftUI

// MARK: - 目標×筋肉プレビュー画面（分割法プレビュー付き）

struct GoalMusclePreviewPage: View {
    let onNext: () -> Void

    @State private var appeared = false
    @State private var mapAppeared = false
    @State private var menuAppeared = false
    @State private var isProceeding = false

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// AppStateから主要目標を取得
    private var currentGoal: OnboardingGoal {
        guard let raw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: raw) else {
            return .getBig
        }
        return goal
    }

    /// 目標に基づく重点筋肉データ
    private var priorityData: GoalMusclePriority {
        GoalMusclePriority.data(for: currentGoal)
    }

    /// 重点筋肉をハイライトした状態マップ
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if priorityData.muscles.contains(muscle) {
                states[muscle] = .recovering(progress: 0.1)
            } else {
                states[muscle] = .inactive
            }
        }
        return states
    }

    /// 分割法プレビューデータ
    private var splitPreview: [DayPreview] {
        let profile = AppState.shared.userProfile
        let frequency = max(2, min(5, profile.weeklyFrequency))
        let location = profile.trainingLocation
        let parts = WorkoutRecommendationEngine.splitParts(for: frequency)

        ExerciseStore.shared.loadIfNeeded()
        var usedExerciseIds: Set<String> = []

        return parts.enumerated().map { index, part in
            // パートの全筋肉
            let allMuscles = part.muscleGroups.flatMap { $0.muscles }
            // 代表筋肉（最大3つ、重点筋肉を優先）
            let priorityMuscleSet = Set(priorityData.muscles)
            let sortedMuscles = allMuscles.sorted { a, b in
                let aIsPriority = priorityMuscleSet.contains(a)
                let bIsPriority = priorityMuscleSet.contains(b)
                if aIsPriority != bIsPriority { return aIsPriority }
                return false
            }
            let representativeMuscles = Array(sortedMuscles.prefix(3))

            // 種目を2-3個ピック（場所フィルタ適用、重複排除）
            var exercises: [ExercisePreviewItem] = []
            for muscle in sortedMuscles {
                guard exercises.count < 3 else { break }
                let candidates = ExerciseStore.shared.exercises(targeting: muscle)
                let filtered = filterByLocation(candidates, location: location)
                if let exercise = filtered.first(where: { !usedExerciseIds.contains($0.id) }) {
                    let name = isJapanese ? exercise.nameJA : exercise.nameEN
                    let equip = exercise.localizedEquipment
                    let (sets, reps) = defaultSetsReps(for: profile.trainingExperience)
                    exercises.append(ExercisePreviewItem(
                        name: name, equipment: equip, sets: sets, reps: reps
                    ))
                    usedExerciseIds.insert(exercise.id)
                }
            }

            let dayName = isJapanese
                ? "Day \(index + 1): \(part.name)"
                : "Day \(index + 1): \(splitPartEnglishName(part.name))"

            return DayPreview(
                dayName: dayName,
                muscles: representativeMuscles,
                exercises: exercises
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            // 上部: 選んだ目標
            VStack(spacing: 4) {
                Text(isJapanese ? "あなたの目標:" : "Your goal:")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmOnboardingTextSub)

                HStack(spacing: 8) {
                    Image(systemName: currentGoal.sfSymbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingAccent)
                    Text(currentGoal.localizedName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer().frame(height: 16)

            // 中央: 筋肉マップ（前後同時表示）
            MuscleMapView(muscleStates: muscleStates)
                .frame(maxHeight: 180)
                .padding(.horizontal, 16)
                .opacity(mapAppeared ? 1 : 0)
                .scaleEffect(mapAppeared ? 1 : 0.92)

            Spacer().frame(height: 16)

            // 下部: 分割法プレビュー
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isJapanese ? "あなた向けのプログラム" : "Your Program")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .padding(.horizontal, 24)

                    // Day別カード
                    VStack(spacing: 0) {
                        ForEach(Array(splitPreview.enumerated()), id: \.element.dayName) { index, day in
                            if index > 0 {
                                Divider()
                                    .background(Color.mmOnboardingTextSub.opacity(0.2))
                                    .padding(.horizontal, 12)
                            }

                            DaySectionView(day: day)
                                .opacity(menuAppeared ? 1 : 0)
                                .offset(y: menuAppeared ? 0 : 10)
                                .animation(
                                    .easeOut(duration: 0.3).delay(Double(index) * 0.08),
                                    value: menuAppeared
                                )
                        }
                    }
                    .background(Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                }
            }
            .scrollIndicators(.hidden)

            Spacer()

            // 提案メッセージ
            Text(isJapanese
                ? "MuscleMapがこの筋肉を優先的に提案します"
                : "MuscleMap will prioritize these muscles")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.mmOnboardingAccent)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 8)

            // 次へボタン
            Button {
                guard !isProceeding else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingBg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                mapAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                menuAppeared = true
            }
        }
    }

    // MARK: - ヘルパー

    /// トレーニング場所で種目をフィルタ
    private func filterByLocation(_ exercises: [ExerciseDefinition], location: String) -> [ExerciseDefinition] {
        guard location == TrainingLocation.home.rawValue else {
            // gym / both → フィルタなし
            return exercises
        }
        let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル"]
        return exercises.filter { homeEquipment.contains($0.equipment) }
    }

    /// トレ歴に応じたデフォルトセット×レップ
    private func defaultSetsReps(for experience: TrainingExperience) -> (sets: Int, reps: Int) {
        switch experience {
        case .beginner: return (3, 12)
        case .halfYear: return (3, 10)
        case .oneYearPlus: return (4, 8)
        case .veteran: return (4, 6)
        }
    }

    /// SplitPart.name（日本語）→ 英語名マッピング
    private func splitPartEnglishName(_ jaName: String) -> String {
        // splitParts(for:)のnameは "Push", "Pull", "Legs" 等の英語もあるのでそのまま返す
        let mapping: [String: String] = [
            "上半身": "Upper Body",
            "下半身": "Lower Body",
            "胸・肩・三頭": "Chest / Shoulders / Triceps",
            "背中・二頭": "Back / Biceps",
            "脚": "Legs",
            "肩・腕": "Shoulders / Arms",
            "胸": "Chest",
            "背中": "Back",
            "肩": "Shoulders",
            "腕": "Arms",
        ]
        return mapping[jaName] ?? jaName
    }
}

// MARK: - データ構造

private struct DayPreview {
    let dayName: String
    let muscles: [Muscle]
    let exercises: [ExercisePreviewItem]
}

private struct ExercisePreviewItem {
    let name: String
    let equipment: String
    let sets: Int
    let reps: Int
}

// MARK: - Day セクション

private struct DaySectionView: View {
    let day: DayPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day名
            Text(day.dayName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mmOnboardingAccent)

            // 筋肉チップ
            HStack(spacing: 6) {
                ForEach(day.muscles, id: \.rawValue) { muscle in
                    Text(muscle.localizedName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.mmOnboardingAccent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            // 種目リスト
            ForEach(Array(day.exercises.enumerated()), id: \.offset) { _, exercise in
                HStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .lineLimit(1)

                    Spacer()

                    // 器具バッジ
                    Text(exercise.equipment)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.mmOnboardingBg.opacity(0.6))
                        .clipShape(Capsule())

                    // セット×レップ
                    Text("\(exercise.sets)×\(exercise.reps)")
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalMusclePreviewPage(onNext: {})
    }
}
