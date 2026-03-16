import SwiftUI

// MARK: - オンボーディング用目標（7つのエモーショナルな選択肢・複数選択可）

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

    var emoji: String {
        switch self {
        case .getBig: return "💪"
        case .dontGetDisrespected: return "😎"
        case .martialArts: return "🥊"
        case .sports: return "⛳"
        case .getAttractive: return "❤️‍🔥"
        case .moveWell: return "🏃"
        case .health: return "❤️"
        }
    }

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
        switch self {
        case .getBig: return "デカくなりたい"
        case .dontGetDisrespected: return "舐められたくない"
        case .martialArts: return "格闘技・武道"
        case .sports: return "スポーツに活かす"
        case .getAttractive: return "モテたい"
        case .moveWell: return "動ける体がほしい"
        case .health: return "健康に長生き"
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

// MARK: - 目標選択画面（左バー方式・筋肉マッププレビュー付き）

struct GoalSelectionPage: View {
    let onNext: () -> Void

    @State private var selectedGoal: OnboardingGoal?
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: OnboardingGoal.allCases.count)
    @State private var isProceeding = false
    @State private var headerAppeared = false
    @State private var showMusclePreview = false

    /// 選択した目標の重点筋肉マップ
    private var muscleStates: [Muscle: MuscleVisualState] {
        guard let goal = selectedGoal else { return [:] }
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
            Spacer().frame(height: 48)

            // ヘッダー
            VStack(spacing: 8) {
                Text(L10n.goalSelectionHeadline)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.goalSelectionSub)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 24)

            // 目標カード（スクロール可能）
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(OnboardingGoal.allCases.enumerated()), id: \.element.id) { index, goal in
                        GoalCard(
                            goal: goal,
                            isSelected: selectedGoal == goal,
                            onTap: {
                                guard !isProceeding else { return }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedGoal = goal
                                }
                                withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                                    showMusclePreview = true
                                }
                                HapticManager.lightTap()

                                AppState.shared.primaryOnboardingGoal = goal.rawValue
                            }
                        )
                        .opacity(cardAppearances.indices.contains(index) && cardAppearances[index] ? 1 : 0)
                        .offset(y: cardAppearances.indices.contains(index) && cardAppearances[index] ? 0 : 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }

            // 筋肉マッププレビュー（選択時にフェードイン）
            if selectedGoal != nil {
                GoalMuscleMapPreview(muscleStates: muscleStates)
                    .frame(height: 120)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.4), value: selectedGoal)
            }

            Spacer().frame(height: 12)

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
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
            // Staggered fade-in
            for index in OnboardingGoal.allCases.indices {
                withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.08 + 0.3)) {
                    cardAppearances[index] = true
                }
            }
        }
    }
}

// MARK: - 目標カード（左バー方式）

private struct GoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 左アクセントバー
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 12)

                HStack(spacing: 12) {
                    // SFシンボルアイコン
                    Image(systemName: goal.sfSymbol)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 36, height: 36)

                    // テキスト
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.localizedName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingTextMain)

                        Text(goal.localizedDescription)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    Spacer()

                    // チェックマーク
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 60)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 筋肉マッププレビュー（目標選択時に表示）

private struct GoalMuscleMapPreview: View {
    let muscleStates: [Muscle: MuscleVisualState]

    var body: some View {
        HStack(spacing: 8) {
            // 筋肉マップ（コンパクト）
            MuscleMapView(muscleStates: muscleStates)
                .frame(width: 100)

            // 重点筋肉のラベル
            VStack(alignment: .leading, spacing: 4) {
                Text("重点トレーニング部位")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextSub)

                let highlightedMuscles = muscleStates.filter {
                    if case .recovering = $0.value { return true }
                    return false
                }.map { $0.key }

                ForEach(highlightedMuscles.prefix(4), id: \.self) { muscle in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.mmOnboardingAccent)
                            .frame(width: 5, height: 5)
                        Text(muscle.japaneseName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.mmOnboardingTextMain)
                    }
                }

                if highlightedMuscles.count > 4 {
                    Text("+\(highlightedMuscles.count - 4) 部位")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalSelectionPage(onNext: {})
    }
}
