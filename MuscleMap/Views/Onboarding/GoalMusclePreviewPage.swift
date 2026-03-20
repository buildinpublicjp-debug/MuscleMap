import SwiftUI

// MARK: - 週間回復サイクルプレビュー画面

struct GoalMusclePreviewPage: View {
    let onNext: () -> Void

    @State private var appeared = false
    @State private var mapAppeared = false
    @State private var cardsAppeared = false
    @State private var isProceeding = false

    // 超回復アニメーション
    @State private var animationDay: Int = 0
    @State private var muscleStates: [Muscle: MuscleVisualState] = [:]
    @State private var animationTimerRef: Timer?

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

    /// 選択済みの頻度
    private var frequency: Int {
        AppState.shared.userProfile.weeklyFrequency
    }

    /// 分割法パーツ
    private var splitParts: [SplitPart] {
        WorkoutRecommendationEngine.splitParts(for: frequency)
    }

    /// WeeklyFrequencyからtrainingDaysを取得
    private var trainingDays: [Int: Int] {
        guard let wf = WeeklyFrequency(rawValue: frequency) else {
            return [0: 0, 2: 1] // デフォルト: 週2
        }
        return wf.trainingDays
    }

    /// カバーされる筋肉の割合
    private var coveragePercent: Int {
        let allMuscles = Set(splitParts.flatMap { $0.muscleGroups.flatMap { $0.muscles } })
        let total = Muscle.allCases.count
        guard total > 0 else { return 0 }
        return Int(Double(allMuscles.count) / Double(total) * 100)
    }

    /// 目標連動ヘッドライン
    private var goalBasedHeadline: String {
        switch currentGoal {
        case .getBig:
            return isJapanese ? "デカくなるプログラム" : "Program to Get Big"
        case .dontGetDisrespected:
            return isJapanese ? "強くなるプログラム" : "Program to Get Strong"
        case .martialArts:
            return isJapanese ? "闘う体のプログラム" : "Fighter's Program"
        case .getAttractive:
            return isJapanese ? "変わるためのプログラム" : "Transformation Program"
        case .sports:
            return isJapanese ? "アスリートのプログラム" : "Athlete's Program"
        case .moveWell:
            return isJapanese ? "動ける体のプログラム" : "Mobility Program"
        case .health:
            return isJapanese ? "健康のためのプログラム" : "Health Program"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            // ヘッダー: 目標連動キャッチコピー
            Text(goalBasedHeadline)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)

            Spacer().frame(height: 4)

            // サブタイトル
            Text(isJapanese
                ? "あなたの目標・経験・環境から最適な分割法を作成しました"
                : "Optimized split based on your goals, experience & equipment")
                .font(.system(size: 13))
                .foregroundStyle(Color.mmOnboardingTextSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 8)

            // 筋肉マップ（大きく、回復サイクルアニメーション）
            MuscleMapView(muscleStates: muscleStates)
                .frame(height: 350)
                .padding(.horizontal, 12)
                .opacity(mapAppeared ? 1 : 0)
                .scaleEffect(mapAppeared ? 1 : 0.92)

            Spacer().frame(height: 6)

            // カバー率バッジ
            Text(isJapanese ? "\(coveragePercent)%の筋肉をカバー" : "\(coveragePercent)% muscle coverage")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.mmOnboardingAccent.opacity(0.12))
                .clipShape(Capsule())
                .opacity(mapAppeared ? 1 : 0)

            Spacer().frame(height: 10)

            // Day構成カード（横スクロール）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(splitParts.enumerated()), id: \.offset) { index, part in
                        dayCard(index: index, part: part)
                            .opacity(cardsAppeared ? 1 : 0)
                            .offset(y: cardsAppeared ? 0 : 10)
                            .animation(
                                .easeOut(duration: 0.3).delay(Double(index) * 0.08),
                                value: cardsAppeared
                            )
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)

            // ティーザーテキスト
            HStack(spacing: 4) {
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 11))
                Text(isJapanese ? "次のページで種目を確認できます" : "You'll see exercises on the next page")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Color.mmOnboardingTextSub)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 6)

            // 次へボタン
            Button {
                guard !isProceeding else { return }
                isProceeding = true
                HapticManager.lightTap()
                stopAnimation()
                onNext()
            } label: {
                Text(isJapanese ? "種目を確認する →" : "Review Exercises →")
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
            .padding(.bottom, 20)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            isProceeding = false
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
                mapAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                cardsAppeared = true
            }
            startRecoveryAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    /// 現在アニメーション中のDayカードインデックス
    private var currentAnimDayIndex: Int? {
        trainingDays[animationDay]
    }

    // MARK: - Dayカード

    private func dayCard(index: Int, part: SplitPart) -> some View {
        let groups = part.muscleGroups
        let partName = isJapanese ? part.name : splitPartEnglishName(part.name)
        let exerciseCount = groups.count >= 2 ? 4 : 3
        let isActive = index == currentAnimDayIndex

        return VStack(spacing: 6) {
            Text("Day \(index + 1)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingAccent)

            Text(partName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .lineLimit(1)

            // 筋肉グループチップ
            HStack(spacing: 4) {
                ForEach(groups.prefix(3), id: \.self) { group in
                    Text(group.localizedName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.mmOnboardingAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // 種目数
            Text(isJapanese ? "\(exerciseCount)種目" : "\(exerciseCount) exercises")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmOnboardingTextSub)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isActive ? Color.mmOnboardingAccent.opacity(0.15) : Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? Color.mmOnboardingAccent : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: currentAnimDayIndex)
    }

    // MARK: - 超回復アニメーション（FrequencySelectionPageと同じロジック）

    private func startRecoveryAnimation() {
        stopAnimation()
        animationDay = 0

        let parts = splitParts
        let days = trainingDays

        updateMuscleStatesForDay(0, parts: parts, trainingDays: days)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [days] _ in
            Task { @MainActor in
                animationDay = (animationDay + 1) % 7
                updateMuscleStatesForDay(animationDay, parts: parts, trainingDays: days)
            }
        }
        animationTimerRef = timer
    }

    private func stopAnimation() {
        animationTimerRef?.invalidate()
        animationTimerRef = nil
    }

    private func updateMuscleStatesForDay(_ day: Int, parts: [SplitPart], trainingDays: [Int: Int]) {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            states[muscle] = .inactive
        }

        for muscle in Muscle.allCases {
            let daysSince = calculateDaysSinceStimulation(
                muscle: muscle, currentDay: day, trainingDays: trainingDays, parts: parts
            )

            if daysSince == 0 {
                states[muscle] = .recovering(progress: 0.05)
            } else if daysSince > 0 {
                let recoveryHours = Double(muscle.baseRecoveryHours)
                let elapsedHours = Double(daysSince) * 24.0
                let progress = elapsedHours / recoveryHours
                if progress >= 1.0 {
                    states[muscle] = .inactive
                } else {
                    states[muscle] = .recovering(progress: progress)
                }
            }
        }

        withAnimation(.easeInOut(duration: 0.4)) {
            muscleStates = states
        }
    }

    private func calculateDaysSinceStimulation(
        muscle: Muscle,
        currentDay: Int,
        trainingDays: [Int: Int],
        parts: [SplitPart]
    ) -> Int {
        for offset in 0...currentDay {
            let checkDay = currentDay - offset
            if let partIndex = trainingDays[checkDay], partIndex < parts.count {
                let part = parts[partIndex]
                let musclesInPart = part.muscleGroups.flatMap { $0.muscles }
                if musclesInPart.contains(muscle) {
                    return offset
                }
            }
        }
        return -1
    }

    // MARK: - ヘルパー

    private func splitPartEnglishName(_ jaName: String) -> String {
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

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        GoalMusclePreviewPage(onNext: {})
    }
}
