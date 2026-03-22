import SwiftUI

// MARK: - 凡例（3×2グリッド）

struct MuscleMapLegend: View {
    private var items: [(Color, String)] {
        [
            (.mmMuscleCoral, L10n.highLoad),
            (.mmMuscleAmber, L10n.earlyRecovery),
            (.mmMuscleYellow, L10n.midRecovery),
            (.mmMuscleLime, L10n.lateRecovery),
            (.mmMuscleBioGreen, L10n.almostRecovered),
            (.mmMuscleNeglected, L10n.notStimulated),
        ]
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.0)
                        .frame(width: 10, height: 10)
                    Text(item.1)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
    }
}

// MARK: - 初回コーチマーク

/// 筋肉マップの上に表示する矢印付きコーチマーク
/// WorkoutSet 0件のユーザーにのみ1回だけ表示
struct HomeCoachMarkView: View {
    let onDismiss: () -> Void

    @State private var arrowOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 4) {
            // テキストバッジ
            Text(LocalizationManager.shared.currentLanguage == .japanese
                 ? "まずワークアウトを記録しよう 👆"
                 : "Record your first workout 👆")
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmBgPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.mmAccentPrimary)
                .clipShape(Capsule())

            // 下向き矢印
            Image(systemName: "arrowtriangle.down.fill")
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)
                .offset(y: arrowOffset)
        }
        .shadow(color: Color.mmAccentPrimary.opacity(0.4), radius: 8, y: 4)
        .padding(.top, 16)
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                arrowOffset = 6
            }
        }
    }
}

// MARK: - 筋肉マップ色説明オーバーレイ（初回1回のみ）

/// オンボーディング完了直後にマップの色の意味を説明する
struct MapExplanationOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(L10n.coachMarkTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.mmTextPrimary)

            Text(L10n.coachMarkBody)
                .font(.system(size: 13))
                .foregroundStyle(Color.mmTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                HapticManager.lightTap()
                onDismiss()
            } label: {
                Text(L10n.gotIt)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmBgPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.mmAccentPrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.mmAccentPrimary.opacity(0.3), radius: 20)
        .padding(.horizontal, 24)
    }
}

// MARK: - 今日のおすすめインライン（筋肉マップ直下）

/// 筋肉マップの直下に常時表示するおすすめカード
/// Pro: 種目リスト+重量+セット表示 / 無料: 部位名のみ+Proバッジ
struct TodayRecommendationInline: View {
    let suggestedMenu: SuggestedMenu?
    let recommendation: RecommendedWorkout?
    let hasWorkoutHistory: Bool
    let isPremium: Bool
    let onStart: () -> Void
    let onStartWithMenu: ([RecommendedExercise]) -> Void
    let onShowPaywall: () -> Void
    var onReviewMenu: ((RecommendedWorkout, SuggestedMenu) -> Void)?
    /// ルーティン表示用
    var todayRoutine: RoutineDay?
    var previousWeightProvider: ((String) -> Double?)?

    @State private var selectedExerciseDefinition: ExerciseDefinition?
    @State private var showRoutineEdit = false
    @State private var selectedDayIndex: Int?
    @State private var showingReplaceSheet = false
    @State private var replacingExerciseIndex: Int?

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        if let routine = todayRoutine, !routine.exercises.isEmpty {
            // ルーティン設定済み → ルーティンカード
            routineCard(routine: routine)
        } else if RoutineManager.shared.hasRoutine {
            // ルーティンあるが今日のDayの種目が空 → 休息日
            restDayCard
        } else if !hasWorkoutHistory, let rec = recommendation, !rec.exercises.isEmpty {
            // 初回ユーザー + メニュー提案あり → 目標ベースのメニューカード
            firstTimeRecommendationCard(recommendation: rec)
        } else if hasWorkoutHistory, let menu = suggestedMenu {
            if isPremium, let rec = recommendation, !rec.exercises.isEmpty {
                // Pro: 詳細メニュー提案
                proRecommendationCard(menu: menu, recommendation: rec)
            } else if !isPremium {
                // 無料: 部位名のみ + Proバッジ
                freeRecommendationCard(menu: menu)
            } else {
                // Pro だが提案なし → 従来の1行表示
                simpleRecommendationCard(menu: menu)
            }
        } else {
            // ルーティンなし → ルーティン作成導線付きフォールバック
            noRoutineCard
        }
    }

    // MARK: - ルーティンカード

    /// 今日のDayインデックスを計算（todayRoutineのidで一致検索）
    private var todayDayIndex: Int {
        let days = RoutineManager.shared.routine.days
        guard let today = todayRoutine else { return 0 }
        return days.firstIndex(where: { $0.id == today.id }) ?? 0
    }

    /// 現在選択中のDayインデックス（初期値はtodayDayIndex）
    private var currentDayIndex: Int {
        selectedDayIndex ?? todayDayIndex
    }

    private func routineCard(routine: RoutineDay) -> some View {
        let allDays = RoutineManager.shared.routine.days
        let displayDay = allDays.indices.contains(currentDayIndex) ? allDays[currentDayIndex] : routine
        let isToday = currentDayIndex == todayDayIndex

        return VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack(spacing: 8) {
                Text(isToday ? L10n.todayRoutine : (localization.currentLanguage == .japanese ? "ルーティン" : "Routine"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Text(displayDay.name)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmAccentPrimary)

                Spacer()
            }

            // 対象筋肉グループ
            if !displayDay.muscleGroups.isEmpty {
                let groupNames = displayDay.muscleGroups.compactMap { raw in
                    MuscleGroup(rawValue: raw)
                }.map { group in
                    localization.currentLanguage == .japanese ? group.japaneseName : group.englishName
                }
                if !groupNames.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(groupNames.joined(separator: "・"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }

            // Dayタブバー（2日以上ある場合のみ表示）
            if allDays.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(allDays.enumerated()), id: \.element.id) { index, day in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDayIndex = index
                                }
                                HapticManager.lightTap()
                            } label: {
                                HStack(spacing: 4) {
                                    if index == todayDayIndex {
                                        Circle()
                                            .fill(currentDayIndex == index ? Color.mmBgPrimary : Color.mmAccentPrimary)
                                            .frame(width: 5, height: 5)
                                    }
                                    Text("Day \(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(
                                    currentDayIndex == index
                                        ? Color.mmBgPrimary
                                        : Color.mmTextPrimary
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    currentDayIndex == index
                                        ? Color.mmAccentPrimary
                                        : Color.mmBgPrimary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // 種目グリッド（2列）
            let gridColumns = [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ]
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(Array(displayDay.exercises.enumerated()), id: \.element.id) { exerciseIndex, exercise in
                    let def = ExerciseStore.shared.exercise(for: exercise.exerciseId)
                    let name = exerciseName(for: exercise)
                    Button {
                        HapticManager.lightTap()
                        if let d = def {
                            selectedExerciseDefinition = d
                        }
                    } label: {
                        ZStack(alignment: .bottom) {
                            // 背景 + GIF（黒バー対策: GeometryReader + scaledToFill + frame + clipped）
                            GeometryReader { geo in
                                Color.mmBgPrimary
                                if ExerciseGifView.hasGif(exerciseId: exercise.exerciseId) {
                                    ExerciseGifView(exerciseId: exercise.exerciseId, size: .card)
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .clipped()
                                } else {
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                        .frame(width: geo.size.width, height: geo.size.height)
                                }
                            }

                            // 下部グラデーション（56pt、テキスト可読性確保）
                            LinearGradient(
                                colors: [.clear, Color.black.opacity(0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 56)

                            // 下部テキスト: 種目名（左）+ セット×レップ（右）
                            HStack(alignment: .bottom) {
                                Text(name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Spacer(minLength: 4)

                                Text("\(exercise.suggestedSets) × \(exercise.suggestedReps)")
                                    .font(.system(size: 11, weight: .heavy).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 6)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            replacingExerciseIndex = exerciseIndex
                            showingReplaceSheet = true
                        } label: {
                            Label(
                                localization.currentLanguage == .japanese ? "種目を変更" : "Replace Exercise",
                                systemImage: "arrow.left.arrow.right"
                            )
                        }

                        Button(role: .destructive) {
                            let dayIdx = currentDayIndex
                            withAnimation(.easeInOut(duration: 0.3)) {
                                RoutineManager.shared.removeExercise(dayIndex: dayIdx, exerciseIndex: exerciseIndex)
                            }
                        } label: {
                            Label(
                                localization.currentLanguage == .japanese ? "削除" : "Remove",
                                systemImage: "trash"
                            )
                        }
                    }
                }
            }

            // 「ルーティンを開始する」ボタン
            if isPremium {
                Button {
                    HapticManager.lightTap()
                    // ルーティンモードで開始するためにpendingStartDayを設定
                    RoutineManager.shared.pendingStartDay = displayDay
                    AppState.shared.selectedTab = 1
                } label: {
                    Text(L10n.startRoutine)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.mmBgPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.mmAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else {
                // 無料ユーザー: ロック付きボタン + 残回数テキスト
                VStack(spacing: 6) {
                    Button {
                        HapticManager.lightTap()
                        onShowPaywall()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text(L10n.startRoutine)
                                .font(.system(size: 15, weight: .bold))
                            Text("Pro")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mmAccentPrimary)
                                .clipShape(Capsule())
                        }
                        .foregroundStyle(Color.mmTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.mmBgPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.mmTextSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // 無料枠残回数（ボタン直下にインライン表示）
                    let remaining = max(0, PurchaseManager.weeklyFreeLimit - PurchaseManager.shared.weeklyWorkoutCount)
                    HStack(spacing: 4) {
                        Image(systemName: remaining > 0 ? "checkmark.circle" : "lock.circle")
                            .font(.system(size: 10))
                        Text(remaining > 0
                             ? (localization.currentLanguage == .japanese ? "今週あと\(remaining)回無料" : "\(remaining) free this week")
                             : (localization.currentLanguage == .japanese ? "今週の無料枠を使い切りました" : "Free workouts used this week"))
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(remaining > 0 ? Color.mmAccentPrimary : Color.mmWarning)
                }
            }

            // 次のDay予告（今日のDay表示時のみ、2日以上のルーティンがある場合）
            if isToday, allDays.count > 1 {
                let nextIndex = (todayDayIndex + 1) % allDays.count
                let nextDay = allDays[nextIndex]
                let nextGroupNames = nextDay.muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
                    .map { localization.currentLanguage == .japanese ? $0.japaneseName : $0.englishName }

                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmTextSecondary)

                    Text(localization.currentLanguage == .japanese ? "次回" : "Next")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.mmTextSecondary)

                    Text(nextDay.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)

                    if !nextGroupNames.isEmpty {
                        Text(nextGroupNames.joined(separator: "・"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mmTextSecondary)
                    }

                    Spacer()
                }
                .padding(10)
                .background(Color.mmBgPrimary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(item: $selectedExerciseDefinition) { def in
            ExerciseDetailView(exercise: def)
        }
        .sheet(isPresented: $showingReplaceSheet) {
            RoutineExerciseReplacePicker(
                dayIndex: currentDayIndex,
                exerciseIndex: replacingExerciseIndex ?? 0
            )
        }
    }

    /// ルーティン種目名を取得
    private func exerciseName(for exercise: RoutineExercise) -> String {
        guard let def = ExerciseStore.shared.exercise(for: exercise.exerciseId) else {
            return exercise.exerciseId
        }
        return localization.currentLanguage == .japanese ? def.nameJA : def.nameEN
    }

    // MARK: - Pro版 詳細提案カード

    private func proRecommendationCard(menu: SuggestedMenu, recommendation: RecommendedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack(spacing: 8) {
                Text(L10n.todayMenu)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Text(recommendation.muscleGroup)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmAccentPrimary)

                Spacer()
            }

            // 目標連動コピー
            if let goalCopy = goalLinkedCopy(muscleGroup: recommendation.muscleGroup) {
                Text(goalCopy)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)
            }

            // 種目リスト（最大3種目）
            ForEach(recommendation.exercises) { exercise in
                HStack(spacing: 10) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    if exercise.suggestedWeight > 0 {
                        Text(weightText(exercise))
                            .font(.system(size: 14).monospacedDigit())
                            .foregroundStyle(Color.mmTextSecondary)

                        if exercise.previousWeight != nil {
                            Text(L10n.weightChallenge(formatWeight(exercise.weightIncrease)))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    } else {
                        Text("\(exercise.suggestedSets) × \(exercise.suggestedReps)")
                            .font(.system(size: 14).monospacedDigit())
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }

            // 「メニューを確認する」ボタン → プレビューシートを表示
            Button {
                HapticManager.lightTap()
                if let onReviewMenu {
                    onReviewMenu(recommendation, menu)
                } else {
                    onStartWithMenu(recommendation.exercises)
                }
            } label: {
                Text(L10n.reviewMenu)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 無料版カード（ブラー付き）

    private func freeRecommendationCard(menu: SuggestedMenu) -> some View {
        Button {
            HapticManager.lightTap()
            onShowPaywall()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack(spacing: 8) {
                    Text(L10n.todayMenu)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)

                    Text(inlineGroupNames(menu: menu))
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmAccentPrimary)

                    Spacer()
                }

                // 目標連動コピー
                if let goalCopy = goalLinkedCopy(muscleGroup: inlineGroupNames(menu: menu)) {
                    Text(goalCopy)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmTextSecondary)
                        .lineLimit(1)
                }

                // ブラー付き種目プレビュー
                ZStack {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(menu.exercises.prefix(3), id: \.id) { ex in
                            let name = localization.currentLanguage == .japanese ? ex.definition.nameJA : ex.definition.nameEN
                            HStack {
                                Text(name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.mmTextPrimary)
                                Spacer()
                                Text("\(ex.suggestedSets) × \(ex.suggestedReps)")
                                    .font(.system(size: 14).monospacedDigit())
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                    }
                    .blur(radius: 6)

                    // ブラー上のCTA
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text(localization.currentLanguage == .japanese ? "Proでメニューを見る" : "View Menu with Pro")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(Color.mmTextPrimary)
                }
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - シンプルカード（Pro提案なし時のフォールバック）

    private func simpleRecommendationCard(menu: SuggestedMenu) -> some View {
        Button {
            HapticManager.lightTap()
            onStart()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.todayRecommendation)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(inlineGroupNames(menu: menu))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)
                    let reason = inlineReason(menu: menu)
                    if !reason.isEmpty {
                        Text(reason)
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(L10n.startWorkout)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmBgPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mmAccentPrimary)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 初回ユーザー向けメニュー提案カード

    private func firstTimeRecommendationCard(recommendation: RecommendedWorkout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー: 「まずはこのメニューから」
            HStack(spacing: 8) {
                Text(L10n.firstTimeMenuHeader)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()
            }

            // 目標連動コピー
            if let goalCopy = goalLinkedCopy(muscleGroup: recommendation.muscleGroup) {
                Text(goalCopy)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)
            }

            // 種目リスト（最大3種目）
            ForEach(recommendation.exercises) { exercise in
                HStack(spacing: 10) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text("\(exercise.suggestedSets) × \(exercise.suggestedReps)")
                        .font(.system(size: 14).monospacedDigit())
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            // 開始ボタン
            Button {
                HapticManager.lightTap()
                onStartWithMenu(recommendation.exercises)
            } label: {
                Text(L10n.startWorkout)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 休息日カード（ルーティンあり・今日の種目なし）

    private var restDayCard: some View {
        let isJP = localization.currentLanguage == .japanese
        let routineDays = RoutineManager.shared.routine.days
        // 次の種目ありDayを探す
        let nextDay = routineDays.first { !$0.exercises.isEmpty }

        return VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.mmAccentPrimary)

                Text(isJP ? "今日は休息日" : "Rest Day")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()
            }

            Text(isJP
                ? "筋肉を回復させて、次のトレーニングに備えましょう"
                : "Let your muscles recover for the next session")
                .font(.system(size: 13))
                .foregroundStyle(Color.mmTextSecondary)

            // 次のトレーニング日
            if let next = nextDay {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmAccentPrimary)

                    Text(isJP
                        ? "次回: \(next.name)（\(next.exercises.count)種目）"
                        : "Next: \(next.name) (\(next.exercises.count) exercises)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.mmTextPrimary)

                    Spacer()
                }
                .padding(10)
                .background(Color.mmBgPrimary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 「それでもトレーニングする」ボタン
            Button {
                HapticManager.lightTap()
                onStart()
            } label: {
                Text(isJP ? "それでもトレーニングする" : "Train Anyway")
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
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ルーティン未設定カード（フォールバック）

    private var noRoutineCard: some View {
        let isJP = localization.currentLanguage == .japanese

        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.mmAccentPrimary)

                Text(isJP ? "今日のおすすめ" : "Today's Recommendation")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()
            }

            Text(isJP
                ? "ルーティンを設定すると、毎日最適なメニューを提案します"
                : "Set up a routine to get daily personalized suggestions")
                .font(.system(size: 13))
                .foregroundStyle(Color.mmTextSecondary)

            // ルーティン作成ボタン
            Button {
                HapticManager.lightTap()
                showRoutineEdit = true
            } label: {
                Text(isJP ? "ルーティンを作成" : "Create Routine")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            // ルーティンなしでトレーニング開始
            Button {
                HapticManager.lightTap()
                onStart()
            } label: {
                Text(isJP ? "ルーティンなしで始める" : "Start Without Routine")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showRoutineEdit) {
            NavigationStack {
                RoutineEditView()
            }
        }
    }

    // MARK: - ヘルパー

    /// 目標連動コピー生成
    private func goalLinkedCopy(muscleGroup: String) -> String? {
        guard let goalRaw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: goalRaw) else { return nil }
        let isJP = localization.currentLanguage == .japanese
        switch goal {
        case .getBig:
            return isJP ? "\(goal.localizedName) → 今日は\(muscleGroup)でサイズアップ"
                        : "\(goal.localizedName) → \(muscleGroup) for size today"
        case .dontGetDisrespected:
            return isJP ? "威圧感・存在感 → 今日は\(muscleGroup)で幅を作る"
                        : "Presence → Build \(muscleGroup) width today"
        case .martialArts:
            return isJP ? "\(goal.localizedName) → 今日は\(muscleGroup)でパワー強化"
                        : "\(goal.localizedName) → \(muscleGroup) for power today"
        case .sports:
            return isJP ? "\(goal.localizedName) → 今日は\(muscleGroup)でパフォーマンスアップ"
                        : "\(goal.localizedName) → \(muscleGroup) for performance today"
        case .getAttractive:
            return isJP ? "\(goal.localizedName) → 今日は\(muscleGroup)でシルエット強化"
                        : "\(goal.localizedName) → Shape \(muscleGroup) today"
        case .moveWell:
            return isJP ? "\(goal.localizedName) → 今日は\(muscleGroup)で動ける体に"
                        : "\(goal.localizedName) → \(muscleGroup) for mobility today"
        case .health:
            return isJP ? "\(goal.localizedName) → 今日は\(muscleGroup)で基礎体力アップ"
                        : "\(goal.localizedName) → \(muscleGroup) for fitness today"
        }
    }

    /// ペアリングされたグループ名を表示用に結合
    private func inlineGroupNames(menu: SuggestedMenu) -> String {
        let groups = MenuSuggestionService.pairedGroups(for: menu.primaryGroup)
        let names = groups.map { group in
            localization.currentLanguage == .japanese ? group.japaneseName : group.englishName
        }
        return names.joined(separator: "・")
    }

    /// 回復状態の簡潔な理由テキスト
    private func inlineReason(menu: SuggestedMenu) -> String {
        let groupName = localization.currentLanguage == .japanese
            ? menu.primaryGroup.japaneseName
            : menu.primaryGroup.englishName
        return localization.currentLanguage == .japanese
            ? "\(groupName)が回復済み"
            : "\(groupName) recovered"
    }

    /// 重量テキスト（例: "62.5kg × 10 × 3"）
    private func weightText(_ exercise: RecommendedExercise) -> String {
        let w = formatWeight(exercise.suggestedWeight)
        return "\(w)kg × \(exercise.suggestedReps) × \(exercise.suggestedSets)"
    }

    /// 重量フォーマット（小数点以下不要なら省略）
    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }
}

// MARK: - Strength Mapストリップバナー（非Proユーザー向け）

/// isPremium == false 時に回復マップ直下に表示するコンパクトな1行ストリップ
struct StrengthMapPreviewBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticManager.lightTap()
            onTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.shield.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Strength Map")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)

                        // Proバッジ
                        Text("Pro")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.mmBgPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mmAccentPrimary)
                            .clipShape(Capsule())
                    }
                    Text(LocalizationManager.shared.currentLanguage == .japanese ? "筋力レベルを見る" : "View strength levels")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ルーティン種目差替えピッカー

/// 長押し「種目を変更」から表示されるシンプルな種目選択シート
private struct RoutineExerciseReplacePicker: View {
    let dayIndex: Int
    let exerciseIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ExerciseListViewModel()
    @State private var searchText = ""

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // フィルターチップ（カテゴリのみ）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            replaceFilterChip(
                                title: localization.currentLanguage == .japanese ? "すべて" : "All",
                                isSelected: viewModel.selectedCategory == nil
                            ) {
                                viewModel.clearAllFilters()
                            }

                            ForEach(viewModel.categories, id: \.self) { category in
                                replaceFilterChip(
                                    title: L10n.localizedCategory(category),
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // 種目リスト
                    List(viewModel.filteredExercises) { exercise in
                        Button {
                            HapticManager.lightTap()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                RoutineManager.shared.replaceExercise(
                                    dayIndex: dayIndex,
                                    exerciseIndex: exerciseIndex,
                                    newExerciseId: exercise.id
                                )
                            }
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                // GIFサムネイル
                                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                    ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                } else {
                                    Image(systemName: "dumbbell.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                        .frame(width: 56, height: 56)
                                        .background(Color.mmBgCard)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(Color.mmTextPrimary)
                                        .lineLimit(1)

                                    HStack(spacing: 8) {
                                        Label(exercise.localizedEquipment, systemImage: "dumbbell")
                                        if let primary = exercise.primaryMuscle {
                                            Label(
                                                localization.currentLanguage == .japanese ? primary.japaneseName : primary.englishName,
                                                systemImage: "figure.strengthtraining.traditional"
                                            )
                                        }
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(Color.mmTextSecondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.mmBgSecondary)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(localization.currentLanguage == .japanese ? "種目を変更" : "Replace Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: L10n.searchExercises)
            .onChange(of: searchText) { _, newValue in
                viewModel.searchText = newValue
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
            .onAppear {
                viewModel.load()
            }
        }
    }

    private func replaceFilterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.mmAccentPrimary : Color.mmBgCard)
                .foregroundStyle(isSelected ? Color.mmBgPrimary : Color.mmTextSecondary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - FlowLayout（タグ表示用）

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
