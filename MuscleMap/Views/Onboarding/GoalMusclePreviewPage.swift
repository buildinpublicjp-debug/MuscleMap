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

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

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
            return [0: 0, 2: 1]
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
            return L10n.gmProgBulk
        case .dontGetDisrespected:
            return L10n.gmProgStrength
        case .martialArts:
            return L10n.gmProgFight
        case .getAttractive:
            return L10n.gmProgTransform
        case .sports:
            return L10n.gmProgAthlete
        case .moveWell:
            return L10n.gmProgMobility
        case .health:
            return L10n.gmProgHealth
        }
    }

    /// SplitPartの筋肉グループに対応する代表種目を取得
    private func exercisesForPart(_ part: SplitPart) -> [ExerciseDefinition] {
        let store = ExerciseStore.shared
        store.loadIfNeeded()
        let targetGroups = Set(part.muscleGroups)
        let maxCount = targetGroups.count >= 2 ? 4 : 3
        var result: [ExerciseDefinition] = []
        var seenIds: Set<String> = []

        // primaryMuscle のグループがターゲットに含まれる種目を取得
        for ex in store.exercises {
            guard seenIds.count < maxCount else { break }
            if let primary = ex.primaryMuscle,
               targetGroups.contains(primary.group),
               !seenIds.contains(ex.id),
               ExerciseGifView.hasGif(exerciseId: ex.id) {
                seenIds.insert(ex.id)
                result.append(ex)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // スクロール可能コンテンツ
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)

                    // ヘッダー: 目標連動キャッチコピー
                    Text(goalBasedHeadline)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)

                    Spacer().frame(height: 4)

                    // サブタイトル
                    Text(L10n.gmPreviewSubtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 6)

                    // 筋肉マップ（回復サイクルアニメーション）
                    MuscleMapView(muscleStates: muscleStates)
                        .frame(height: 300)
                        .padding(.horizontal, 12)
                        .opacity(mapAppeared ? 1 : 0)
                        .scaleEffect(mapAppeared ? 1 : 0.92)

                    Spacer().frame(height: 4)

                    // カバー率バッジ
                    Text(L10n.muscleCoveragePercent(coveragePercent))
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.mmOnboardingAccent.opacity(0.12))
                        .clipShape(Capsule())
                        .opacity(mapAppeared ? 1 : 0)

                    Spacer().frame(height: 12)

                    // Day別GIFグリッド
                    VStack(spacing: 16) {
                        ForEach(Array(splitParts.enumerated()), id: \.offset) { index, part in
                            daySectionView(index: index, part: part)
                                .opacity(cardsAppeared ? 1 : 0)
                                .offset(y: cardsAppeared ? 0 : 10)
                                .animation(
                                    .easeOut(duration: 0.3).delay(Double(index) * 0.08),
                                    value: cardsAppeared
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)
                }
            }

            // 固定フッター: 次へボタン
            Button {
                guard !isProceeding else { return }
                isProceeding = true
                HapticManager.mediumTap()
                stopAnimation()
                onNext()
            } label: {
                Text(L10n.reviewExercises)
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

    // MARK: - Day別セクション（ヘッダー + GIFグリッド）

    private func daySectionView(index: Int, part: SplitPart) -> some View {
        let partName = isJapanese ? part.name : splitPartEnglishName(part.name)
        let exercises = exercisesForPart(part)
        let isActive = index == currentAnimDayIndex

        return VStack(alignment: .leading, spacing: 8) {
            // Dayヘッダー
            HStack {
                Text("Day \(index + 1)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingAccent)

                Text(partName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .lineLimit(1)

                Spacer()

                // 筋肉グループチップ
                ForEach(part.muscleGroups.prefix(2), id: \.self) { group in
                    Text(group.localizedName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.mmOnboardingAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // 2カラムGIFグリッド
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(exercises, id: \.id) { exercise in
                    ZStack(alignment: .bottom) {
                        GeometryReader { geo in
                            Color.mmOnboardingBg
                            ExerciseGifView(exerciseId: exercise.id, size: .card)
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }

                        // グラデーション + 種目名
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 48)

                        Text(exercise.localizedName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.bottom, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(12)
        .background(isActive ? Color.mmOnboardingAccent.opacity(0.1) : Color.mmOnboardingCard)
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
