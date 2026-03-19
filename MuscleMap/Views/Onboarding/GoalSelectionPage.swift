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
        switch self {
        case .getBig: return "Tシャツが似合う体に"
        case .dontGetDisrespected: return "存在感のある体で生きる"
        case .martialArts: return "パンチ力・タックル・組み力"
        case .sports: return "ゴルフ飛距離、スイング速度"
        case .getAttractive: return "自信のある体が全てを変える"
        case .moveWell: return "階段で息切れしない"
        case .health: return "家族のために"
        }
    }
}

// MARK: - 目標選択画面（複数選択 + 筋肉マップ + インタラクティブハイライト）

struct GoalSelectionPage: View {
    let onNext: () -> Void

    @State private var selectedGoals: Set<OnboardingGoal> = []
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: OnboardingGoal.allCases.count)
    @State private var isProceeding = false
    @State private var headerAppeared = false
    @State private var tappedMuscle: Muscle?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// 全選択目標の重点筋肉を合算
    private var priorityMuscles: [Muscle] {
        guard !selectedGoals.isEmpty else { return [] }
        var muscles: [Muscle] = []
        var seen: Set<Muscle> = []
        for goal in selectedGoals {
            for muscle in GoalMusclePriority.data(for: goal).muscles {
                if seen.insert(muscle).inserted {
                    muscles.append(muscle)
                }
            }
        }
        return muscles
    }

    /// 筋肉マップの状態（全選択目標の筋肉を合算ハイライト）
    private var muscleStates: [Muscle: MuscleVisualState] {
        guard !selectedGoals.isEmpty else {
            var states: [Muscle: MuscleVisualState] = [:]
            for muscle in Muscle.allCases {
                states[muscle] = .inactive
            }
            return states
        }
        var prioritySet: Set<Muscle> = []
        for goal in selectedGoals {
            let priority = GoalMusclePriority.data(for: goal)
            prioritySet.formUnion(priority.muscles)
        }
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            states[muscle] = prioritySet.contains(muscle)
                ? .recovering(progress: 0.1)
                : .inactive
        }
        return states
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            // ヘッダー（コンパクト）
            Text(L10n.goalSelectionHeadline)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .multilineTextAlignment(.center)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 12)
                .padding(.horizontal, 24)

            Spacer().frame(height: 12)

            // 筋肉マップ（前面+背面横並び、タップ可能）
            MuscleMapView(
                muscleStates: muscleStates,
                onMuscleTapped: { muscle in
                    tappedMuscle = muscle
                }
            )
            .frame(height: 200)
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedGoals)

            // 重点筋肉チップ（横スクロール）
            if !priorityMuscles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text(isJapanese ? "重点部位" : "Key Targets")
                            .font(.caption2)
                            .foregroundStyle(Color.mmOnboardingTextSub)

                        ForEach(priorityMuscles, id: \.self) { muscle in
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
                .animation(.easeOut(duration: 0.3), value: selectedGoals)
            }

            Spacer().frame(height: 12)

            // 目標カード（コンパクト、スクロール不要）
            VStack(spacing: 6) {
                ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                    CompactGoalCard(
                        goal: goal,
                        isSelected: selectedGoals.contains(goal),
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                if selectedGoals.contains(goal) {
                                    selectedGoals.remove(goal)
                                } else {
                                    selectedGoals.insert(goal)
                                }
                            }
                            HapticManager.lightTap()
                            // 最初の選択を primaryOnboardingGoal に保存（互換性）
                            if let first = selectedGoals.first {
                                AppState.shared.primaryOnboardingGoal = first.rawValue
                            }
                        }
                    )
                    .opacity(cardAppearances.indices.contains(index) && cardAppearances[index] ? 1 : 0)
                    .offset(y: cardAppearances.indices.contains(index) && cardAppearances[index] ? 0 : 12)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // 次へボタン
            Button {
                guard !isProceeding, !selectedGoals.isEmpty else { return }
                isProceeding = true
                HapticManager.lightTap()
                // 全選択目標の筋肉を合算してgoPriorityMusclesに保存
                var allMuscles: [String] = []
                var seen: Set<String> = []
                for goal in selectedGoals {
                    for muscle in GoalMusclePriority.data(for: goal).muscles {
                        if seen.insert(muscle.rawValue).inserted {
                            allMuscles.append(muscle.rawValue)
                        }
                    }
                }
                AppState.shared.userProfile.goalPriorityMuscles = allMuscles
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(!selectedGoals.isEmpty ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(!selectedGoals.isEmpty ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(selectedGoals.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selectedGoals)
        }
        .sheet(item: $tappedMuscle) { muscle in
            MuscleExerciseSheet(muscle: muscle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
            // カードの順次フェードイン
            for index in OnboardingGoal.allCases.indices {
                withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.06 + 0.2)) {
                    cardAppearances[index] = true
                }
            }
        }
    }
}

// MARK: - コンパクト目標カード（48pt、1行テキスト）

private struct CompactGoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // 左アクセントバー
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3, height: 24)

                // SFシンボル
                Image(systemName: goal.sfSymbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                    .frame(width: 24)

                // テキスト（1行）
                Text(goal.localizedName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Spacer()

                // チェックマーク
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.mmOnboardingAccent)
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingBg)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 筋肉タップ → フルシート（全種目GIF付き）

private struct MuscleExerciseSheet: View {
    let muscle: Muscle

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var exercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        HStack(spacing: 12) {
                            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.mmOnboardingCard)
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Image(systemName: "dumbbell")
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.localizedName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmOnboardingTextMain)
                                Text(exercise.localizedEquipment)
                                    .font(.caption)
                                    .foregroundStyle(Color.mmOnboardingTextSub)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.mmOnboardingBg)
            .navigationTitle(isJapanese
                ? "\(muscle.japaneseName) — \(exercises.count)種目"
                : "\(muscle.englishName) — \(exercises.count) exercises")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalSelectionPage(onNext: {})
    }
}
