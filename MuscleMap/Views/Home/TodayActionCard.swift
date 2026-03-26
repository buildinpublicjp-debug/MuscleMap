import SwiftUI

// MARK: - 今日のアクションカード（ホーム画面トップ）

/// ホーム画面の最上部に表示する「今日何をやるか」カード
/// ルーティン設定済み → ルーティンカード / 初回ユーザー → 目標ベース提案 / フォールバック → ルーティン作成導線
struct TodayActionCard: View {
    let viewModel: HomeViewModel
    let streakWeeks: Int
    let isCurrentWeekCompleted: Bool
    let hasWorkoutHistory: Bool
    let recommendedWorkout: RecommendedWorkout?
    let onShowPaywall: () -> Void
    let onStartWithMenu: ([RecommendedExercise]) -> Void
    let onReviewMenu: ((RecommendedWorkout, SuggestedMenu) -> Void)?
    let onStart: () -> Void

    /// Day切替用ステート
    @State private var selectedDayIndex: Int?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        if let routine = viewModel.todayRoutine, !routine.exercises.isEmpty {
            routineActionCard(routine: routine)
        } else if RoutineManager.shared.hasRoutine {
            restDayActionCard
        } else if !hasWorkoutHistory, let rec = recommendedWorkout, !rec.exercises.isEmpty {
            firstTimeActionCard(recommendation: rec)
        } else {
            setupRoutineCard
        }
    }

    // MARK: - ルーティンカード

    /// 現在選択中のDay（selectedDayIndexまたはtodayRoutineのインデックス）
    private var activeDay: RoutineDay {
        let allDays = RoutineManager.shared.routine.days
        if let idx = selectedDayIndex, idx < allDays.count {
            return allDays[idx]
        }
        return viewModel.todayRoutine ?? allDays.first ?? RoutineDay(id: UUID(), name: "", muscleGroups: [], exercises: [])
    }

    private func routineActionCard(routine: RoutineDay) -> some View {
        let allDays = RoutineManager.shared.routine.days
        let displayDay = activeDay
        let groupNames = displayDay.muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
            .map { isJapanese ? $0.japaneseName : $0.englishName }
            .joined(separator: " + ")

        return VStack(alignment: .leading, spacing: 12) {
            // ヘッダー行: タイトル + ストリークピル
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(isJapanese ? "今日:" : "Today:") \(groupNames)")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)

                    Text("\(displayDay.name) - \(displayDay.exercises.count)\(isJapanese ? "種目" : " exercises")")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // ストリークピル
                streakPill
            }

            // Day切替タブ（2Day以上の場合のみ表示）
            if allDays.count > 1 {
                dayPickerTabs(allDays: allDays, todayRoutine: routine)
            }

            // 種目GIFサムネイル横スクロール
            exerciseThumbnailScroll(exercises: displayDay.exercises)

            // CTA: ワークアウト開始
            startWorkoutButton(routine: displayDay)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.16, blue: 0.09), Color.mmBgSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mmAccentPrimary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - Day切替タブ

    private func dayPickerTabs(allDays: [RoutineDay], todayRoutine: RoutineDay) -> some View {
        let todayIdx = allDays.firstIndex(where: { $0.id == todayRoutine.id }) ?? 0
        let currentIdx = selectedDayIndex ?? todayIdx

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(allDays.enumerated()), id: \.offset) { idx, day in
                    let isSelected = idx == currentIdx
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDayIndex = idx
                        }
                        HapticManager.lightTap()
                    } label: {
                        Text("Day \(idx + 1)")
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .black : Color.mmTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.mmAccentPrimary : Color.mmBgSecondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 種目サムネイルスクロール

    /// 括弧以降を省略して表示名を短くする
    private func shortenedName(_ fullName: String) -> String {
        if let parenIdx = fullName.firstIndex(of: "（") {
            return String(fullName[..<parenIdx])
        }
        if let parenIdx = fullName.firstIndex(of: "(") {
            return String(fullName[..<parenIdx])
        }
        return fullName
    }

    private func exerciseThumbnailScroll(exercises: [RoutineExercise]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(exercises) { exercise in
                    let def = ExerciseStore.shared.exercise(for: exercise.exerciseId)
                    let rawName: String = {
                        guard let d = def else { return exercise.exerciseId }
                        return isJapanese ? d.nameJA : d.nameEN
                    }()
                    let name = shortenedName(rawName)

                    VStack(spacing: 4) {
                        // GIFサムネイル or プレースホルダー
                        ZStack {
                            Color.mmBgPrimary
                            if ExerciseGifView.hasGif(exerciseId: exercise.exerciseId) {
                                ExerciseGifView(exerciseId: exercise.exerciseId, size: .thumbnail)
                                    .scaledToFill()
                                    .frame(width: 90, height: 70)
                                    .clipped()
                            } else {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                            }
                        }
                        .frame(width: 90, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // 種目名（括弧以降省略、9px）
                        Text(name)
                            .font(.system(size: 9))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .frame(width: 100)

                        // セット × レップ
                        Text("\(exercise.suggestedSets)×\(exercise.suggestedReps)")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(width: 110)
                }
            }
            // 右端パディングでスクロール示唆
            .padding(.trailing, 20)
        }
    }

    // MARK: - CTAボタン

    private func startWorkoutButton(routine: RoutineDay) -> some View {
        Button {
            HapticManager.lightTap()
            RoutineManager.shared.pendingStartDay = routine
            AppState.shared.selectedTab = 1
        } label: {
            Text(isJapanese ? "ワークアウトを開始" : "Start Workout")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [Color.mmAccentPrimary, Color.mmAccentPrimary.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - ストリークピル

    @ViewBuilder
    private var streakPill: some View {
        if hasWorkoutHistory && streakWeeks > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmWarning)
                Text(L10n.weekStreak(streakWeeks))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - 休息日カード

    private var restDayActionCard: some View {
        let routineDays = RoutineManager.shared.routine.days
        let nextDay = routineDays.first { !$0.exercises.isEmpty }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(isJapanese ? "今日は休息日" : "Rest Day")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Text(isJapanese
                        ? "筋肉を回復させて、次のトレーニングに備えましょう"
                        : "Let your muscles recover for the next session")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                streakPill
            }

            if let next = nextDay {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(isJapanese
                        ? "次回: \(next.name)（\(next.exercises.count)種目）"
                        : "Next: \(next.name) (\(next.exercises.count) exercises)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // それでもトレーニングする
            Button {
                HapticManager.lightTap()
                onStart()
            } label: {
                Text(isJapanese ? "それでもトレーニングする" : "Train Anyway")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.mmAccentPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.16, blue: 0.09), Color.mmBgSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mmAccentPrimary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - 初回ユーザー向けカード

    private func firstTimeActionCard(recommendation: RecommendedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.firstTimeMenuHeader)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("\(recommendation.exercises.count)\(isJapanese ? "種目" : " exercises")")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }

            // 種目サムネイル
            let routineExercises = recommendation.exercises.map { ex in
                RoutineExercise(
                    id: UUID(),
                    exerciseId: ex.exerciseId,
                    suggestedSets: ex.suggestedSets,
                    suggestedReps: ex.suggestedReps
                )
            }
            exerciseThumbnailScroll(exercises: routineExercises)

            Button {
                HapticManager.lightTap()
                onStartWithMenu(recommendation.exercises)
            } label: {
                Text(isJapanese ? "ワークアウトを開始" : "Start Workout")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color.mmAccentPrimary, Color.mmAccentPrimary.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.16, blue: 0.09), Color.mmBgSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mmAccentPrimary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - ルーティン未設定カード

    @State private var showRoutineEdit = false

    private var setupRoutineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(isJapanese ? "ルーティンを設定しよう" : "Set Up Your Routine")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Text(isJapanese
                        ? "ルーティンを設定すると、毎日最適なメニューを提案します"
                        : "Set up a routine to get daily personalized suggestions")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                streakPill
            }

            Button {
                HapticManager.lightTap()
                showRoutineEdit = true
            } label: {
                Text(isJapanese ? "ルーティンを作成" : "Create Routine")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [Color.mmAccentPrimary, Color.mmAccentPrimary.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.lightTap()
                onStart()
            } label: {
                Text(isJapanese ? "ルーティンなしで始める" : "Start Without Routine")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.16, blue: 0.09), Color.mmBgSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mmAccentPrimary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showRoutineEdit) {
            NavigationStack {
                RoutineEditView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        Text("Preview requires HomeViewModel")
            .foregroundStyle(.white)
    }
}
