import SwiftUI

// MARK: - 目標×筋肉プレビュー画面（実メニュープレビュー付き）

struct GoalMusclePreviewPage: View {
    let onNext: () -> Void

    @State private var appeared = false
    @State private var mapAppeared = false
    @State private var menuAppeared = false
    @State private var isProceeding = false

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

    /// 重点筋肉に対応する種目サンプル（最大5件）
    private var sampleExercises: [(exercise: ExerciseDefinition, muscle: Muscle)] {
        ExerciseStore.shared.loadIfNeeded()
        var results: [(ExerciseDefinition, Muscle)] = []
        var usedIds: Set<String> = []

        for muscle in priorityData.muscles {
            let exercises = ExerciseStore.shared.exercises(targeting: muscle)
            if let first = exercises.first(where: { !usedIds.contains($0.id) }) {
                results.append((first, muscle))
                usedIds.insert(first.id)
            }
            if results.count >= 5 { break }
        }
        return results
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            // 上部: 選んだ目標
            VStack(spacing: 4) {
                Text("あなたの目標:")
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
                .frame(maxHeight: 220)
                .padding(.horizontal, 16)
                .opacity(mapAppeared ? 1 : 0)
                .scaleEffect(mapAppeared ? 1 : 0.92)

            Spacer().frame(height: 16)

            // 下部: 実メニュープレビュー
            VStack(alignment: .leading, spacing: 8) {
                Text("あなた向けのメニュー例")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .padding(.horizontal, 24)

                VStack(spacing: 6) {
                    ForEach(Array(sampleExercises.enumerated()), id: \.element.exercise.id) { index, item in
                        HStack(spacing: 10) {
                            // 筋肉名バッジ
                            Text(item.muscle.japaneseName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingAccent)
                                .frame(width: 56)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            // 種目名
                            Text(item.exercise.nameJA)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.mmOnboardingTextMain)
                                .lineLimit(1)

                            Spacer()

                            // 器具バッジ
                            Text(item.exercise.localizedEquipment)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.mmOnboardingTextSub)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.mmOnboardingBg.opacity(0.6))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.mmOnboardingCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(menuAppeared ? 1 : 0)
                        .offset(y: menuAppeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.06), value: menuAppeared)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // 提案メッセージ
            Text("MuscleMapがこの筋肉を優先的に提案します")
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
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalMusclePreviewPage(onNext: {})
    }
}
