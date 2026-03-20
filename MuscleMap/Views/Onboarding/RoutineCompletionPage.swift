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

    /// カバー率（マッピングされた筋肉数 / 全21筋肉）
    private var coveragePercent: Int {
        let coveredCount = combinedMuscleMapping.count
        return min(100, coveredCount * 100 / max(1, Muscle.allCases.count))
    }

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

            Spacer().frame(height: 6)

            // 筋肉マップ（カバー率オーバーレイ付き）
            muscleMapSection
                .opacity(mapAppeared ? 1 : 0)
                .scaleEffect(mapAppeared ? 1 : 0.92)

            Spacer().frame(height: 6)

            // Dayサマリー（縦リスト）
            VStack(spacing: 8) {
                ForEach(Array(routine.days.enumerated()), id: \.element.id) { index, day in
                    dayInfoRow(index: index, day: day)
                        .opacity(cardsAppeared ? 1 : 0)
                        .offset(y: cardsAppeared ? 0 : 10)
                        .animation(
                            .easeOut(duration: 0.3).delay(Double(index) * 0.08),
                            value: cardsAppeared
                        )
                }
            }
            .padding(.horizontal, 24)

            // 合計行（1行）
            totalSummaryRow
                .opacity(cardsAppeared ? 1 : 0)
                .padding(.horizontal, 24)
                .padding(.top, 6)

            Spacer(minLength: 4)

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
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                buttonGlow = true
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView(isHardPaywall: true)
        }
    }

    // MARK: - 筋肉マップ（大きく + カバー率オーバーレイ）

    private var muscleMapSection: some View {
        ZStack(alignment: .bottom) {
            // 筋肉マップ（前面+背面）
            MuscleMapView(muscleStates: programMuscleStates)
                .frame(height: 200)
                .padding(.horizontal, 16)

            // カバー率オーバーレイ（マップ中央下部）
            Text(isJapanese ? "\(coveragePercent)%の筋肉をカバー" : "\(coveragePercent)% muscle coverage")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.mmOnboardingAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.mmOnboardingBg.opacity(0.8))
                .clipShape(Capsule())
                .padding(.bottom, 4)
        }
    }

    // MARK: - Day情報行（横幅フル、情報リッチ）

    @ViewBuilder
    private func dayInfoRow(index: Int, day: RoutineDay) -> some View {
        let groups = muscleGroupsForDay(day)

        HStack(spacing: 8) {
            // Day番号
            Text("Day \(index + 1)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingAccent)
                .frame(width: 50, alignment: .leading)

            // 部位チップ
            HStack(spacing: 4) {
                ForEach(groups.prefix(3), id: \.self) { group in
                    Text(group.localizedName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.mmOnboardingAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // 種目数（大きく）
            Text("\(day.exercises.count)")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingTextMain)
            Text(isJapanese ? "種目" : "ex")
                .font(.system(size: 11))
                .foregroundStyle(Color.mmOnboardingTextSub)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 合計行

    private var totalSummaryRow: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.mmOnboardingAccent)
            Text(L10n.routineTotalExercises(totalExercises, routine.days.count))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mmOnboardingAccent)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.mmOnboardingAccent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        RoutineCompletionPage(onComplete: {})
    }
}
