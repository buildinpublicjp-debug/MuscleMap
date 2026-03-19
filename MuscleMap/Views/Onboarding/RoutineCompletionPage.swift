import SwiftUI

// MARK: - ルーティン完了 + ハードペイウォールページ

/// ルーティンサマリーを表示し、Pro契約を促すオンボーディング最終ページ
/// 閉じるボタンなし — 「無料ではじめる」で完了 or PaywallViewから課金
struct RoutineCompletionPage: View {
    let onComplete: () -> Void

    @State private var showingPaywall = false
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
    @State private var mapAppeared = false
    @State private var graphAppeared = false
    @State private var buttonGlow = false

    /// 保存済みルーティン
    private var routine: UserRoutine {
        RoutineManager.shared.routine
    }

    /// 全Day合計の種目数
    private var totalExercises: Int {
        routine.days.reduce(0) { $0 + $1.exercises.count }
    }

    /// ルーティン全体の筋肉マッピング（全種目のmuscleMappingを統合）
    private var combinedMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        let store = ExerciseStore.shared

        for day in routine.days {
            for exercise in day.exercises {
                guard let def = store.exercise(for: exercise.exerciseId) else { continue }
                for (muscleId, intensity) in def.muscleMapping {
                    mapping[muscleId] = max(mapping[muscleId] ?? 0, intensity)
                }
            }
        }
        return mapping
    }

    /// MuscleMapView用: 全Dayの種目が刺激する筋肉をハイライト
    private var programMuscleStates: [Muscle: MuscleVisualState] {
        var stimulated: Set<Muscle> = []
        let store = ExerciseStore.shared

        for day in routine.days {
            for exercise in day.exercises {
                if let def = store.exercise(for: exercise.exerciseId) {
                    for (muscleId, _) in def.muscleMapping {
                        if let muscle = Muscle(rawValue: muscleId) {
                            stimulated.insert(muscle)
                        }
                    }
                }
            }
        }

        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            states[muscle] = stimulated.contains(muscle) ? .recovering(progress: 0.1) : .inactive
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
            return L10n.routineCompletionDefaultHeadline
        }
        switch goal {
        case .getBig:
            return isJapanese ? "90日後、鏡の前で笑える。" : "In 90 days, you'll smile in the mirror."
        case .martialArts:
            return isJapanese ? "パンチ力も、全部フィジカルが土台。" : "Power starts with your physique."
        case .getAttractive:
            return isJapanese ? "変わる旅を始めよう。" : "Start your transformation."
        case .dontGetDisrespected:
            return isJapanese ? "存在感は、体が作る。" : "Presence is built by your body."
        case .sports:
            return isJapanese ? "パフォーマンスの土台を作ろう。" : "Build the foundation for performance."
        case .moveWell:
            return isJapanese ? "動ける体は、日々の積み重ね。" : "A body that moves well, built daily."
        case .health:
            return isJapanese ? "健康な体が、全ての基盤。" : "A healthy body is the foundation of everything."
        }
    }

    /// カバー率（マッピングされた筋肉数 / 全21筋肉）
    private var coveragePercent: Int {
        let coveredCount = combinedMuscleMapping.count
        return min(100, coveredCount * 100 / max(1, Muscle.allCases.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // 目標別キャッチコピー
            Text(goalBasedHeadline)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 6)

            Text(L10n.routineCompletionSub)
                .font(.subheadline)
                .foregroundStyle(Color.mmOnboardingTextSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(headerAppeared ? 1 : 0)

            Spacer().frame(height: 16)

            // インタラクティブ筋肉マップ（前面+背面横並び）
            muscleMapSection
                .opacity(mapAppeared ? 1 : 0)
                .scaleEffect(mapAppeared ? 1 : 0.92)

            Spacer().frame(height: 16)

            // Dayサマリーカード + 成長グラフ
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(routine.days) { day in
                        daySummaryCard(day)
                    }

                    // 合計
                    totalSummaryRow

                    // 成長グラフ
                    growthGraphSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)

            Spacer()

            // CTAボタンエリア
            ctaButtons
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                mapAppeared = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                cardsAppeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                graphAppeared = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonGlow = true
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView(isHardPaywall: true)
        }
    }

    // MARK: - インタラクティブ筋肉マップ（前面+背面）

    private var muscleMapSection: some View {
        VStack(spacing: 8) {
            Text(isJapanese ? "あなたのプログラムで鍛えられる筋肉" : "Muscles trained by your program")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mmOnboardingTextSub)

            // インタラクティブ筋肉マップ（前面+背面）
            MuscleMapView(muscleStates: programMuscleStates)
                .frame(height: 180)
                .padding(.horizontal, 24)

            // カバー率バッジ
            Text(isJapanese ? "\(coveragePercent)%の筋肉をカバー" : "\(coveragePercent)% muscle coverage")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.mmOnboardingAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.mmOnboardingAccent.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    // MARK: - Dayサマリーカード（筋肉チップ付き）

    @ViewBuilder
    private func daySummaryCard(_ day: RoutineDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Spacer()
                Text(L10n.routineExerciseCountShort(day.exercises.count))
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmOnboardingAccent)
            }

            // 筋肉グループチップ（横スクロール）
            let groups = muscleGroupsForDay(day)
            if !groups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(groups, id: \.self) { group in
                            Text(group.localizedName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.mmOnboardingAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.mmOnboardingAccent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // 種目名をコンパクトに表示
            let exerciseNames = day.exercises.compactMap {
                ExerciseStore.shared.exercise(for: $0.exerciseId)?.localizedName
            }
            Text(exerciseNames.joined(separator: " / "))
                .font(.system(size: 13))
                .foregroundStyle(Color.mmOnboardingTextSub)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 合計行

    private var totalSummaryRow: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color.mmOnboardingAccent)
            Text(L10n.routineTotalExercises(totalExercises, routine.days.count))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.mmOnboardingAccent)
            Spacer()
        }
        .padding(12)
        .background(Color.mmOnboardingAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 成長グラフ

    private var growthGraphSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isJapanese ? "4週間後の予測" : "4-Week Projection")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)

            ZStack(alignment: .bottomLeading) {
                // グラフ背景グリッド
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        Divider()
                            .background(Color.mmOnboardingTextSub.opacity(0.15))
                        Spacer()
                    }
                    Divider()
                        .background(Color.mmOnboardingTextSub.opacity(0.15))
                }
                .frame(height: 48)

                // 成長カーブ
                GrowthCurvePath()
                    .trim(from: 0, to: graphAppeared ? 1 : 0)
                    .stroke(
                        LinearGradient(
                            colors: [Color.mmOnboardingAccent.opacity(0.5), Color.mmOnboardingAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(height: 48)
                    .animation(.easeOut(duration: 1.0), value: graphAppeared)

                // グロー効果
                GrowthCurvePath()
                    .trim(from: 0, to: graphAppeared ? 1 : 0)
                    .stroke(
                        Color.mmOnboardingAccent.opacity(0.2),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(height: 48)
                    .blur(radius: 3)
                    .animation(.easeOut(duration: 1.0), value: graphAppeared)
            }

            // 週ラベル
            HStack {
                Text(isJapanese ? "Week 1" : "Week 1")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                Spacer()
                Text(isJapanese ? "Week 4" : "Week 4")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingAccent)
            }

            Text(isJapanese ? "着実にレベルアップ" : "Steady progress ahead")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.mmOnboardingTextSub)
        }
        .padding(12)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    .font(.system(size: 15))
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
        .padding(.bottom, 32)
    }
}

// MARK: - 成長カーブ Shape

/// 右肩上がりの成長カーブ（trim可能なShape）
private struct GrowthCurvePath: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.height))
            path.addCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.1),
                control1: CGPoint(x: rect.width * 0.3, y: rect.height * 0.85),
                control2: CGPoint(x: rect.width * 0.65, y: rect.height * 0.2)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        RoutineCompletionPage(onComplete: {})
    }
}
