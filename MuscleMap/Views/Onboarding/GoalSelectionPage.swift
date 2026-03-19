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

// MARK: - 目標選択画面（筋肉マップ + インタラクティブハイライト）

struct GoalSelectionPage: View {
    let onNext: () -> Void

    @State private var selectedGoal: OnboardingGoal?
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: OnboardingGoal.allCases.count)
    @State private var isProceeding = false
    @State private var headerAppeared = false
    @State private var tappedMuscle: Muscle?

    private var localization: LocalizationManager { LocalizationManager.shared }

    /// 選択した目標の重点筋肉リスト
    private var priorityMuscles: [Muscle] {
        guard let goal = selectedGoal else { return [] }
        return GoalMusclePriority.data(for: goal).muscles
    }

    /// 筋肉マップの状態（選択目標に応じてハイライト）
    private var muscleStates: [Muscle: MuscleVisualState] {
        guard let goal = selectedGoal else {
            // 未選択: 全筋肉 inactive
            var states: [Muscle: MuscleVisualState] = [:]
            for muscle in Muscle.allCases {
                states[muscle] = .inactive
            }
            return states
        }
        let priority = GoalMusclePriority.data(for: goal)
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if priority.muscles.contains(muscle) {
                states[muscle] = .recovering(progress: 0.1)
            } else {
                states[muscle] = .inactive
            }
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
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedGoal)

            // 重点筋肉チップ（横スクロール）
            if !priorityMuscles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text(localization.currentLanguage == .japanese ? "重点部位" : "Key Targets")
                            .font(.caption2)
                            .foregroundStyle(Color.mmOnboardingTextSub)

                        ForEach(priorityMuscles, id: \.self) { muscle in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.mmOnboardingAccent)
                                    .frame(width: 6, height: 6)
                                Text(localization.currentLanguage == .japanese ? muscle.japaneseName : muscle.englishName)
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
                .animation(.easeOut(duration: 0.3), value: selectedGoal)
            }

            Spacer().frame(height: 12)

            // 目標カード（コンパクト、スクロール不要）
            VStack(spacing: 6) {
                ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                    CompactGoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal,
                        onTap: {
                            guard !isProceeding else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedGoal = goal
                            }
                            HapticManager.lightTap()
                            AppState.shared.primaryOnboardingGoal = goal.rawValue
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
                guard !isProceeding, selectedGoal != nil else { return }
                isProceeding = true
                HapticManager.lightTap()
                onNext()
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selectedGoal != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(selectedGoal != nil ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(selectedGoal == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selectedGoal)
        }
        .sheet(item: $tappedMuscle) { muscle in
            MuscleExercisePopover(muscle: muscle)
                .presentationDetents([.height(280)])
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

// MARK: - 筋肉タップ → 種目ポップオーバー

private struct MuscleExercisePopover: View {
    let muscle: Muscle
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var exercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー
            HStack {
                Text(localization.currentLanguage == .japanese ? muscle.japaneseName : muscle.englishName)
                    .font(.headline.bold())
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Spacer()
                Text(localization.currentLanguage == .japanese
                     ? "\(exercises.count)種目"
                     : "\(exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }

            // 上位3種目（GIF付き）
            ForEach(exercises.prefix(3)) { exercise in
                HStack(spacing: 8) {
                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                        ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.mmOnboardingCard)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "dumbbell")
                                    .font(.caption)
                                    .foregroundStyle(Color.mmOnboardingTextSub)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.localizedName)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmOnboardingTextMain)
                            .lineLimit(1)
                        Text(exercise.localizedEquipment)
                            .font(.caption2)
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    Spacer()
                }
            }

            // 残りの種目数
            if exercises.count > 3 {
                Text(localization.currentLanguage == .japanese
                     ? "他 \(exercises.count - 3)種目"
                     : "+\(exercises.count - 3) more")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
        }
        .padding(20)
        .background(Color.mmOnboardingBg)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalSelectionPage(onNext: {})
    }
}
