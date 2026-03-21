import SwiftUI

// MARK: - ルーティン完了 + ハードペイウォールページ

/// ルーティンサマリーを表示し、Pro契約を促すオンボーディング最終ページ
/// 種目→筋肉ライトアップアニメーション付き
struct RoutineCompletionPage: View {
    let onComplete: () -> Void

    @State private var showingPaywall = false
    @State private var headerAppeared = false
    @State private var contentAppeared = false
    @State private var buttonGlow = false

    // アニメーション状態
    @State private var flatExerciseIndex: Int = -1
    @State private var highlightedMuscles: Set<String> = []
    @State private var animationCompleted = false
    @State private var timerHolder = TimerHolder()

    /// 保存済みルーティン
    private var routine: UserRoutine {
        RoutineManager.shared.routine
    }

    /// 全Day合計の種目数
    private var totalExercises: Int {
        routine.days.reduce(0) { $0 + $1.exercises.count }
    }

    /// 全Day・全種目をフラット化（dayIndex付き）
    private var allFlatExercises: [(dayIndex: Int, exercise: RoutineExercise)] {
        routine.days.enumerated().flatMap { dayIdx, day in
            day.exercises.map { (dayIndex: dayIdx, exercise: $0) }
        }
    }

    /// 現在ハイライト中の種目が属するDayのインデックス
    private var currentDayIndex: Int? {
        guard flatExerciseIndex >= 0, flatExerciseIndex < allFlatExercises.count else { return nil }
        return allFlatExercises[flatExerciseIndex].dayIndex
    }

    /// 筋肉カバレッジ%
    private var muscleCoverage: Double {
        let allMuscleCount = Muscle.allCases.count
        guard allMuscleCount > 0 else { return 0 }
        let covered = highlightedMuscles.filter { Muscle(rawValue: $0) != nil }.count
        return Double(covered) / Double(allMuscleCount)
    }

    private var coveragePercent: Int {
        Int(muscleCoverage * 100)
    }

    /// アニメーション連動の筋肉マップ状態
    private var animatedMuscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            if highlightedMuscles.contains(muscle.rawValue) {
                states[muscle] = .recovering(progress: 0.05)
            } else {
                states[muscle] = .inactive
            }
        }
        return states
    }

    /// Day別の筋肉グループ集計
    private func muscleGroupsForDay(_ day: RoutineDay) -> [MuscleGroup] {
        var groups: Set<MuscleGroup> = []
        let store = ExerciseStore.shared

        for exercise in day.exercises {
            guard let def = store.exercise(for: exercise.exerciseId) else { continue }
            for muscleId in def.muscleMapping.keys {
                if let muscle = Muscle(rawValue: muscleId) {
                    groups.insert(muscle.group)
                }
            }
        }
        return MuscleGroup.allCases.filter { groups.contains($0) }
    }

    private var isJapanese: Bool { LocalizationManager.shared.currentLanguage == .japanese }

    /// 目標に合わせたキャッチコピー
    private var goalBasedHeadline: String {
        guard let raw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: raw) else {
            return isJapanese ? "あなた専用プログラム完成" : "Your Program is Ready"
        }
        switch goal {
        case .getBig:
            return isJapanese ? "デカくなる準備完了。" : "Ready to Get Big."
        case .dontGetDisrespected:
            return isJapanese ? "強くなる準備完了。" : "Ready to Get Strong."
        case .martialArts:
            return isJapanese ? "闘う体の準備完了。" : "Fight-Ready Program."
        case .getAttractive:
            return isJapanese ? "変わる準備完了。" : "Ready to Transform."
        case .sports:
            return isJapanese ? "アスリートの準備完了。" : "Athletic Program Ready."
        case .moveWell:
            return isJapanese ? "動ける体の準備完了。" : "Mobility Program Ready."
        case .health:
            return isJapanese ? "健康への第一歩。" : "Your Health Journey Starts."
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            // 目標別キャッチコピー + サブタイトル
            VStack(spacing: 6) {
                Text(goalBasedHeadline)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingAccent)
                    .multilineTextAlignment(.center)

                Text(isJapanese
                    ? "あなたの目標・経験・環境から最適な分割法を作成しました"
                    : "Optimized for your goals, experience & equipment")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 10)

            // 筋肉マップ（前面+背面）+ カバレッジバー
            muscleMapSection
                .opacity(contentAppeared ? 1 : 0)
                .scaleEffect(contentAppeared ? 1 : 0.92)

            Spacer().frame(height: 10)

            // カバレッジプログレスバー
            coverageProgressBar
                .padding(.horizontal, 24)
                .opacity(contentAppeared ? 1 : 0)

            Spacer().frame(height: 10)

            // Day別種目リスト（スクロール）
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(routine.days.enumerated()), id: \.element.id) { dayIndex, day in
                        daySection(dayIndex: dayIndex, day: day)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .opacity(contentAppeared ? 1 : 0)

            Spacer(minLength: 4)

            // CTAボタンエリア
            ctaButtons
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentAppeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonGlow = true
            }
            // アニメーション開始（ページ遷移後に少し待つ）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                startAnimation()
            }
        }
        .onDisappear {
            timerHolder.timer?.invalidate()
            timerHolder.timer = nil
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView(isHardPaywall: true)
        }
    }

    // MARK: - 筋肉マップセクション

    private var muscleMapSection: some View {
        MuscleMapView(muscleStates: animatedMuscleStates)
            .frame(height: 200)
            .padding(.horizontal, 16)
    }

    // MARK: - カバレッジプログレスバー

    private var coverageProgressBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text(isJapanese ? "筋肉カバレッジ" : "Muscle Coverage")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                Spacer()
                Text("\(coveragePercent)%")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(animationCompleted ? Color.mmOnboardingAccent : Color.mmOnboardingTextMain)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: coveragePercent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.mmOnboardingCard)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            animationCompleted
                                ? Color.mmOnboardingAccent
                                : Color.mmMuscleCoral
                        )
                        .frame(width: geo.size.width * muscleCoverage, height: 6)
                        .animation(.easeInOut(duration: 0.4), value: muscleCoverage)
                }
            }
            .frame(height: 6)

            // 完了メッセージ
            if animationCompleted {
                Text(isJapanese
                    ? "全身をバランスよくカバー！"
                    : "Full body coverage!")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingAccent)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Dayセクション（Day名 + 種目チップ横スクロール）

    @ViewBuilder
    private func daySection(dayIndex: Int, day: RoutineDay) -> some View {
        let groups = muscleGroupsForDay(day)

        VStack(alignment: .leading, spacing: 6) {
            // Dayヘッダー
            HStack(spacing: 6) {
                Text("Day \(dayIndex + 1)")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingAccent)

                ForEach(groups.prefix(3), id: \.self) { group in
                    Text(group.localizedName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.mmOnboardingAccent.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                Text("\(day.exercises.count)")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Text(isJapanese ? "種目" : "ex")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }

            // 種目チップ（横スクロール）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(day.exercises.enumerated()), id: \.element.id) { exIndex, routineExercise in
                        let flatIndex = flatIndexFor(dayIndex: dayIndex, exerciseIndex: exIndex)
                        let chipState = exerciseChipState(flatIndex: flatIndex)

                        exerciseChip(
                            routineExercise: routineExercise,
                            state: chipState
                        )
                    }
                }
            }
        }
        .padding(10)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 種目チップ

    private enum ChipState {
        case pending   // 未到達
        case current   // ハイライト中
        case done      // 通過済み
    }

    private func exerciseChipState(flatIndex: Int) -> ChipState {
        if flatIndex < flatExerciseIndex {
            return .done
        } else if flatIndex == flatExerciseIndex {
            return .current
        } else {
            return .pending
        }
    }

    @ViewBuilder
    private func exerciseChip(routineExercise: RoutineExercise, state: ChipState) -> some View {
        let def = ExerciseStore.shared.exercise(for: routineExercise.exerciseId)
        let name = def?.localizedName ?? routineExercise.exerciseId

        HStack(spacing: 6) {
            // ステータスアイコン
            switch state {
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingAccent)
            case .current:
                Image(systemName: "play.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.mmOnboardingAccent)
            case .pending:
                Circle()
                    .stroke(Color.mmOnboardingTextSub.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 10, height: 10)
            }

            // GIFサムネイル
            if ExerciseGifView.hasGif(exerciseId: routineExercise.exerciseId) {
                ExerciseGifView(exerciseId: routineExercise.exerciseId, size: .thumbnail)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Text(name)
                .font(.system(size: 11, weight: state == .current || state == .done ? .semibold : .medium))
                .foregroundStyle(
                    state == .done ? Color.mmOnboardingAccent :
                    state == .current ? Color.mmOnboardingTextMain :
                    Color.mmOnboardingTextSub
                )
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            state == .current ? Color.mmOnboardingAccent.opacity(0.2) :
            state == .done ? Color.mmOnboardingAccent.opacity(0.08) :
            Color.mmOnboardingBg.opacity(0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(state == .current ? Color.mmOnboardingAccent : .clear, lineWidth: 2)
        )
        .opacity(state == .pending ? 0.3 : 1.0)
        .scaleEffect(state == .current ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: state == .current)
    }

    // MARK: - CTAボタン

    private var ctaButtons: some View {
        VStack(spacing: 12) {
            // Pro版ボタン
            Button {
                HapticManager.lightTap()
                showingPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                    Text(L10n.routineUnlockPro)
                }
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
                .shadow(
                    color: Color.mmOnboardingAccent.opacity(buttonGlow ? 0.35 : 0.15),
                    radius: buttonGlow ? 6 : 2
                )
            }
            .buttonStyle(.plain)

            // 無料ではじめる
            Button {
                HapticManager.lightTap()
                onComplete()
            } label: {
                Text(L10n.ctaGetStartedFree)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .buttonStyle(.plain)

            // 利用規約・プライバシーポリシー
            HStack(spacing: 4) {
                if let termsURL = URL(string: LegalURL.termsOfUse) {
                    Link(destination: termsURL) {
                        Text(L10n.termsOfUse)
                            .underline()
                    }
                }
                Text("|")
                if let privacyURL = URL(string: LegalURL.privacyPolicy) {
                    Link(destination: privacyURL) {
                        Text(L10n.privacyPolicy)
                            .underline()
                    }
                }
            }
            .font(.caption2)
            .foregroundStyle(Color.mmOnboardingTextSub)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - アニメーションロジック

    /// フラットインデックスを計算
    private func flatIndexFor(dayIndex: Int, exerciseIndex: Int) -> Int {
        var index = 0
        for d in 0..<dayIndex {
            index += routine.days[d].exercises.count
        }
        return index + exerciseIndex
    }

    /// アニメーション開始
    private func startAnimation() {
        flatExerciseIndex = -1
        highlightedMuscles = []
        animationCompleted = false

        timerHolder.timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [self] _ in
            Task { @MainActor in
                self.advanceAnimation()
            }
        }
    }

    /// アニメーション1ステップ進行
    private func advanceAnimation() {
        flatExerciseIndex += 1

        if flatExerciseIndex < allFlatExercises.count {
            let entry = allFlatExercises[flatExerciseIndex]
            highlightExercise(entry.exercise)
        } else {
            // 全種目通過 → 完了演出
            timerHolder.timer?.invalidate()
            timerHolder.timer = nil
            withAnimation(.easeInOut(duration: 0.5)) {
                animationCompleted = true
            }
            HapticManager.setCompleted()
        }
    }

    /// 種目の筋肉をハイライト（累積）
    private func highlightExercise(_ routineExercise: RoutineExercise) {
        guard let def = ExerciseStore.shared.exercise(for: routineExercise.exerciseId) else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            for muscleId in def.muscleMapping.keys {
                highlightedMuscles.insert(muscleId)
            }
        }
        HapticManager.lightTap()
    }
}

// MARK: - Timer保持用（@Stateで参照型を保持）

private class TimerHolder {
    var timer: Timer?

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        RoutineCompletionPage(onComplete: {})
    }
}
