import SwiftUI

// MARK: - 今日のアクションカード（ホーム画面トップ）

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

    @State private var selectedDayIndex: Int?
    @State private var selectedExerciseDetail: ExerciseDefinition?
    @State private var showingRoutineEdit = false

    var body: some View {
        Group {
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
        .sheet(item: $selectedExerciseDetail) { exercise in
            ExerciseDetailView(exercise: exercise, hideStartWorkoutButton: true)
        }
        .sheet(isPresented: $showingRoutineEdit) {
            NavigationStack {
                RoutineEditView()
            }
        }
    }

    // MARK: - ルーティンカード

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
            .map { $0.localizedName }
            .joined(separator: " + ")

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(L10n.todayColon) \(groupNames)")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("\(displayDay.name) - \(L10n.exerciseCountLabel(displayDay.exercises.count))")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                routineEditButton
            }

            if allDays.count > 1 {
                dayPickerTabs(allDays: allDays, todayRoutine: routine)
            }

            exerciseThumbnailScroll(exercises: displayDay.exercises)

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
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 種目サムネイルスクロール

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
                        return d.localizedName
                    }()
                    let name = shortenedName(rawName)

                    ZStack {
                        // GIF（アニメーション）
                        if ExerciseGifView.hasGif(exerciseId: exercise.exerciseId) {
                            ExerciseGifView(exerciseId: exercise.exerciseId, size: .gridCard)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 140, height: 120)
                                .background(Color.white)
                                .clipped()
                        } else {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                .frame(width: 140, height: 120)
                        }

                        // 下部グラデーション + テキスト
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 50)
                        }

                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(name)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text("\(exercise.suggestedSets)×\(exercise.suggestedReps)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                Spacer()
                            }
                            .padding(6)
                        }

                        // 右上 info ボタン
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    if let d = def {
                                        HapticManager.lightTap()
                                        selectedExerciseDetail = d
                                    }
                                } label: {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .background(Circle().fill(Color.black.opacity(0.3)).frame(width: 22, height: 22))
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(5)
                            Spacer()
                        }
                    }
                    .frame(width: 140, height: 120)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
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
            Text(L10n.startWorkout)
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - ルーティン編集ボタン

    private var routineEditButton: some View {
        Button {
            HapticManager.lightTap()
            showingRoutineEdit = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 14))
                .foregroundStyle(Color.mmTextSecondary)
                .padding(6)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                        Text(L10n.restDay)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Text(L10n.restDayDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                routineEditButton
            }

            if let next = nextDay {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(L10n.nextRoutineDay(next.name, next.exercises.count))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                HapticManager.lightTap()
                onStart()
            } label: {
                Text(L10n.trainAnyway)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.mmAccentPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
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
                    Text(L10n.exerciseCountLabel(recommendation.exercises.count))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }

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
                Text(L10n.startWorkout)
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
                .contentShape(Rectangle())
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

    private var setupRoutineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(L10n.setupRoutineTitle)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Text(L10n.setupRoutineHint)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }

            Button {
                HapticManager.lightTap()
                showingRoutineEdit = true
            } label: {
                Text(L10n.createRoutine)
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                HapticManager.lightTap()
                onStart()
            } label: {
                Text(L10n.startWithoutRoutine)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mmAccentPrimary)
                .contentShape(Rectangle())
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
    }
}

#Preview {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        Text("Preview requires HomeViewModel")
            .foregroundStyle(.white)
    }
}
