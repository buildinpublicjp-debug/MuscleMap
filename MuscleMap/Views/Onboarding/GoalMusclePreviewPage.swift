import SwiftUI

// MARK: - 目標×筋肉プレビュー画面（オンボーディングのクライマックス）

struct GoalMusclePreviewPage: View {
    let onNext: () -> Void

    @State private var appeared = false
    @State private var mapAppeared = false
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

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            // 上部: 選んだ目標
            VStack(spacing: 4) {
                Text("あなたの目標:")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmOnboardingTextSub)

                Text("\(currentGoal.emoji) \(currentGoal.localizedName)")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer().frame(height: 16)

            // 中央: 筋肉マップ（前後同時表示）
            MuscleMapView(muscleStates: muscleStates)
                .frame(maxHeight: 300)
                .padding(.horizontal, 16)
                .opacity(mapAppeared ? 1 : 0)
                .scaleEffect(mapAppeared ? 1 : 0.92)

            Spacer().frame(height: 16)

            // 下部: 重点筋肉の説明
            VStack(alignment: .leading, spacing: 12) {
                // ヘッドライン
                Text(priorityData.headline)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                // 筋肉×理由の箇条書き
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(priorityData.reasons, id: \.muscle) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 6, height: 6)

                            Text(item.muscle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.mmOnboardingTextMain)

                            Text("—")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.mmOnboardingTextSub)

                            Text(item.reason)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.mmOnboardingTextSub)
                        }
                    }
                }

                // 提案メッセージ
                Text("MuscleMapがこの筋肉を優先的に提案します")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.mmOnboardingAccent)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            Spacer()

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
        }
    }
}

// MARK: - 目標別の重点筋肉データ

struct GoalMusclePriority {
    let muscles: [Muscle]
    let headline: String
    let reasons: [MuscleReason]

    struct MuscleReason {
        let muscle: String
        let reason: String
    }

    static func data(for goal: OnboardingGoal) -> GoalMusclePriority {
        switch goal {
        case .getBig:
            return GoalMusclePriority(
                muscles: [.chestUpper, .chestLower, .lats, .quadriceps, .hamstrings, .glutes],
                headline: "大きい筋肉から鍛えれば効率最大",
                reasons: [
                    MuscleReason(muscle: "大胸筋", reason: "上半身のボリューム"),
                    MuscleReason(muscle: "広背筋", reason: "背中の広がり"),
                    MuscleReason(muscle: "脚", reason: "体の60%の筋肉量"),
                ]
            )
        case .dontGetDisrespected:
            return GoalMusclePriority(
                muscles: [.deltoidAnterior, .deltoidLateral, .chestUpper, .trapsUpper],
                headline: "存在感は上半身の幅で決まる",
                reasons: [
                    MuscleReason(muscle: "三角筋", reason: "肩幅を広げる"),
                    MuscleReason(muscle: "大胸筋", reason: "厚みを出す"),
                    MuscleReason(muscle: "僧帽筋", reason: "首回りの迫力"),
                ]
            )
        case .martialArts:
            return GoalMusclePriority(
                muscles: [.lats, .quadriceps, .hamstrings, .rectusAbdominis, .obliques],
                headline: "打撃力は背中と脚から生まれる",
                reasons: [
                    MuscleReason(muscle: "広背筋", reason: "パンチの引き"),
                    MuscleReason(muscle: "脚", reason: "踏み込みの力"),
                    MuscleReason(muscle: "体幹", reason: "打撃の安定性"),
                ]
            )
        case .sports:
            return GoalMusclePriority(
                muscles: [.quadriceps, .hamstrings, .glutes, .rectusAbdominis, .deltoidAnterior],
                headline: "パフォーマンスは下半身と体幹が土台",
                reasons: [
                    MuscleReason(muscle: "脚", reason: "爆発的なパワー"),
                    MuscleReason(muscle: "体幹", reason: "動きの安定性"),
                    MuscleReason(muscle: "肩", reason: "腕の振りの起点"),
                ]
            )
        case .getAttractive:
            return GoalMusclePriority(
                muscles: [.chestUpper, .deltoidAnterior, .deltoidLateral, .biceps, .rectusAbdominis],
                headline: "Tシャツ映えは胸と肩のシルエット",
                reasons: [
                    MuscleReason(muscle: "大胸筋", reason: "胸板の厚み"),
                    MuscleReason(muscle: "三角筋", reason: "肩のライン"),
                    MuscleReason(muscle: "腹直筋", reason: "引き締まったウエスト"),
                ]
            )
        case .moveWell:
            return GoalMusclePriority(
                muscles: [.quadriceps, .glutes, .rectusAbdominis, .erectorSpinae, .lats],
                headline: "日常の動きは全部ここから",
                reasons: [
                    MuscleReason(muscle: "脚", reason: "階段・歩行の基盤"),
                    MuscleReason(muscle: "体幹", reason: "姿勢の維持"),
                    MuscleReason(muscle: "背中", reason: "物を持つ力"),
                ]
            )
        case .health:
            return GoalMusclePriority(
                muscles: [.quadriceps, .hamstrings, .glutes, .erectorSpinae, .rectusAbdominis],
                headline: "抗老化に最も効くのは大筋群",
                reasons: [
                    MuscleReason(muscle: "脚", reason: "転倒予防・代謝維持"),
                    MuscleReason(muscle: "背中", reason: "姿勢と骨密度"),
                    MuscleReason(muscle: "体幹", reason: "腰痛予防"),
                ]
            )
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
