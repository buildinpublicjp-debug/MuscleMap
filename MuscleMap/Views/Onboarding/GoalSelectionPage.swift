import SwiftUI

// MARK: - オンボーディング用目標（7つのエモーショナルな選択肢）

@MainActor
enum OnboardingGoal: String, CaseIterable, Identifiable {
    case getBig = "get_big"
    case dontGetDisrespected = "dont_get_disrespected"
    case martialArts = "martial_arts"
    case sports = "sports"
    case getAttractive = "get_attractive"
    case moveWell = "move_well"
    case health = "health"

    nonisolated var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .getBig: return "figure.strengthtraining.traditional"
        case .dontGetDisrespected: return "shield.fill"
        case .martialArts: return "figure.martial.arts"
        case .sports: return "sportscourt.fill"
        case .getAttractive: return "star.fill"
        case .moveWell: return "figure.walk"
        case .health: return "heart.fill"
        }
    }

    var localizedName: String {
        let isJa = LocalizationManager.shared.currentLanguage == .japanese
        switch self {
        case .getBig: return isJa ? "デカくなりたい" : "Get Big"
        case .dontGetDisrespected: return isJa ? "舐められたくない" : "Command Respect"
        case .martialArts: return isJa ? "格闘技・武道" : "Martial Arts"
        case .sports: return isJa ? "スポーツに活かす" : "Sports Performance"
        case .getAttractive: return isJa ? "モテたい" : "Look Attractive"
        case .moveWell: return isJa ? "動ける体がほしい" : "Move Better"
        case .health: return isJa ? "健康に長生き" : "Health & Longevity"
        }
    }

    var localizedDescription: String {
        let isJa = LocalizationManager.shared.currentLanguage == .japanese
        switch self {
        case .getBig: return isJa ? "Tシャツが似合う体に" : "A body that fills out a T-shirt"
        case .dontGetDisrespected: return isJa ? "存在感のある体で生きる" : "Command presence with your physique"
        case .martialArts: return isJa ? "パンチ力・タックル・組み力" : "Punch power, tackles & grappling"
        case .sports: return isJa ? "ゴルフ飛距離、スイング速度" : "Drive distance & swing speed"
        case .getAttractive: return isJa ? "自信のある体が全てを変える" : "A confident body changes everything"
        case .moveWell: return isJa ? "階段で息切れしない" : "No more breathlessness on stairs"
        case .health: return isJa ? "家族のために" : "For your family"
        }
    }
}

// MARK: - 目標選択画面（スライダー + 筋肉マップグラデーション）

struct GoalSelectionPage: View {
    let onNext: () -> Void
    var currentPage: Int = 0

    @State private var goalValues: [String: Double] = [:]
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: OnboardingGoal.allCases.count)
    @State private var isProceeding = false
    @State private var headerAppeared = false
    @State private var tappedMuscle: Muscle?

    /// 少なくとも1つのスライダーが0より大きいか
    private var hasAnyGoal: Bool {
        goalValues.values.contains { $0 > 0 }
    }

    /// 全目標のスライダー値からグラデーション筋肉マップ状態を計算
    private var muscleStates: [Muscle: MuscleVisualState] {
        // 筋肉ごとの強度を合算
        var muscleIntensity: [Muscle: Double] = [:]
        for goal in OnboardingGoal.allCases {
            let sliderValue = goalValues[goal.rawValue] ?? 0
            guard sliderValue > 0 else { continue }
            let muscles = GoalMusclePriority.data(for: goal).muscles
            for muscle in muscles {
                let current = muscleIntensity[muscle] ?? 0
                muscleIntensity[muscle] = min(1.0, current + sliderValue)
            }
        }

        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if let intensity = muscleIntensity[muscle], intensity > 0 {
                // intensity 0→1 を progress 0.6→1.0 にマッピング（緑系のグラデーション）
                let progress = 0.6 + intensity * 0.4
                states[muscle] = .recovering(progress: progress)
            } else {
                states[muscle] = .inactive
            }
        }
        return states
    }

    /// 重点筋肉チップ用（強度順）
    private var priorityMuscles: [Muscle] {
        var muscleIntensity: [Muscle: Double] = [:]
        for goal in OnboardingGoal.allCases {
            let sliderValue = goalValues[goal.rawValue] ?? 0
            guard sliderValue > 0 else { continue }
            let muscles = GoalMusclePriority.data(for: goal).muscles
            for muscle in muscles {
                let current = muscleIntensity[muscle] ?? 0
                muscleIntensity[muscle] = min(1.0, current + sliderValue)
            }
        }
        return muscleIntensity
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            // ヘッダー
            Text(L10n.goalSelectionHeadline)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .multilineTextAlignment(.center)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 12)
                .padding(.horizontal, 24)

            Spacer().frame(height: 8)

            // 筋肉マップ（グラデーションハイライト）
            MuscleMapView(
                muscleStates: muscleStates,
                onMuscleTapped: { muscle in
                    tappedMuscle = muscle
                }
            )
            .frame(height: 220)
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.3), value: goalValues.map { "\($0.key):\($0.value)" })

            // 重点筋肉チップ（横スクロール）
            if !priorityMuscles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text(L10n.keyTargets)
                            .font(.caption2)
                            .foregroundStyle(Color.mmOnboardingTextSub)

                        ForEach(priorityMuscles.prefix(8), id: \.self) { muscle in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.mmOnboardingAccent)
                                    .frame(width: 6, height: 6)
                                Text(muscle.localizedName)
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.mmOnboardingTextMain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mmOnboardingCard)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 28)
                .transition(.opacity)
            }

            Spacer().frame(height: 4)

            // 目標カード（スライダー付き、スクロール可能）
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                        GoalSliderCard(
                            goal: goal,
                            value: Binding(
                                get: { goalValues[goal.rawValue] ?? 0 },
                                set: { goalValues[goal.rawValue] = $0 }
                            )
                        )
                        .opacity(cardAppearances.indices.contains(index) && cardAppearances[index] ? 1 : 0)
                        .offset(y: cardAppearances.indices.contains(index) && cardAppearances[index] ? 0 : 12)
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)

            Spacer(minLength: 4)

            // 未選択ヒント
            if !hasAnyGoal {
                Text(L10n.tapToSelectGoals)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .padding(.bottom, 4)
            }

            // 次へボタン
            Button {
                guard !isProceeding, hasAnyGoal else { return }
                isProceeding = true
                HapticManager.mediumTap()
                saveGoalData()
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(hasAnyGoal ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(hasAnyGoal ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .disabled(!hasAnyGoal)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: hasAnyGoal)
        }
        .sheet(item: $tappedMuscle) { muscle in
            MuscleExerciseSheet(muscle: muscle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            isProceeding = false
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
            for index in OnboardingGoal.allCases.indices {
                withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.06 + 0.2)) {
                    cardAppearances[index] = true
                }
            }
        }
        .onChange(of: currentPage) {
            isProceeding = false
        }
    }

    // MARK: - 保存

    private func saveGoalData() {
        // goalWeightsをUserProfileに保存
        let weights = goalValues.filter { $0.value > 0 }
        AppState.shared.userProfile.goalWeights = weights

        // primaryOnboardingGoal: 最も高いスライダー値の目標
        if let topGoal = weights.max(by: { $0.value < $1.value }) {
            AppState.shared.primaryOnboardingGoal = topGoal.key
        }

        // goalPriorityMuscles: 重み付き合算（後方互換）
        var muscleIntensity: [Muscle: Double] = [:]
        for (goalId, sliderValue) in weights {
            guard let goal = OnboardingGoal(rawValue: goalId) else { continue }
            for muscle in GoalMusclePriority.data(for: goal).muscles {
                let current = muscleIntensity[muscle] ?? 0
                muscleIntensity[muscle] = min(1.0, current + sliderValue)
            }
        }
        let sorted = muscleIntensity.sorted { $0.value > $1.value }
        AppState.shared.userProfile.goalPriorityMuscles = sorted.map { $0.key.rawValue }
    }
}

// MARK: - スライダー付き目標カード

private struct GoalSliderCard: View {
    let goal: OnboardingGoal
    @Binding var value: Double

    private var isActive: Bool { value > 0 }

    var body: some View {
        VStack(spacing: 0) {
            // カードヘッダー（タップで選択/解除）
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isActive {
                        value = 0
                    } else {
                        value = 0.5
                    }
                }
                HapticManager.lightTap()
            } label: {
                HStack(spacing: 10) {
                    // 左アクセントバー
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isActive ? Color.mmOnboardingAccent.opacity(0.3 + value * 0.7) : Color.clear)
                        .frame(width: 3, height: 24)

                    // SFシンボル
                    Image(systemName: goal.sfSymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isActive ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 24)

                    // テキスト
                    Text(goal.localizedName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)

                    Spacer()

                    // 値インジケータ or チェックマーク
                    if isActive {
                        HStack(spacing: 6) {
                            Text("\(Int(value * 100))%")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(Color.mmOnboardingAccent)
                                .monospacedDigit()

                            ZStack {
                                Circle()
                                    .fill(Color.mmOnboardingAccent)
                                    .frame(width: 20, height: 20)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.mmOnboardingBg)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)

            // スライダー（選択時のみ展開）
            if isActive {
                Slider(value: $value, in: 0.1...1.0, step: 0.05)
                    .tint(Color.mmOnboardingAccent.opacity(0.3 + value * 0.7))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .background(isActive ? Color.mmOnboardingAccent.opacity(0.05 + value * 0.05) : Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? Color.mmOnboardingAccent.opacity(0.2 + value * 0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.25), value: isActive)
        .animation(.easeOut(duration: 0.15), value: value)
    }
}

// MARK: - 筋肉タップ → フルシート（全種目GIF付き）

private struct MuscleExerciseSheet: View {
    let muscle: Muscle
    @State private var selectedExercise: ExerciseDefinition?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var exercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
            .filter { ExerciseGifView.hasGif(exerciseId: $0.id) }
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(exercises) { exercise in
                        Button {
                            HapticManager.lightTap()
                            selectedExercise = exercise
                        } label: {
                            ZStack {
                                Color.mmOnboardingBg

                                ExerciseGifView(exerciseId: exercise.id, size: .card)
                                    .scaledToFill()

                                // オーバーレイ: 種目名（左上）+ 器具名（右下）
                                VStack {
                                    HStack {
                                        Text(exercise.localizedName)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.black.opacity(0.55))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        Spacer()
                                    }
                                    .padding(6)

                                    Spacer()

                                    HStack {
                                        Spacer()
                                        Text(exercise.localizedEquipment)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.black.opacity(0.55))
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    .padding(6)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.mmOnboardingBg)
            .navigationTitle(isJapanese
                ? "\(muscle.japaneseName) — \(exercises.count)種目"
                : "\(muscle.englishName) — \(exercises.count) exercises")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise, hideStartWorkoutButton: true)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalSelectionPage(onNext: {})
    }
}
