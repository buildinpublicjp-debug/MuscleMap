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

    /// 目標に合わせたキャッチコピー
    private var goalBasedHeadline: String {
        guard let raw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: raw) else {
            return L10n.routineCompletionDefaultHeadline
        }
        switch goal {
        case .getBig:
            return "90日後、鏡の前で笑える。"
        case .martialArts:
            return "パンチ力も、全部フィジカルが土台。"
        case .getAttractive:
            return "変わる旅を始めよう。"
        case .dontGetDisrespected:
            return "存在感は、体が作る。"
        case .sports:
            return "パフォーマンスの土台を作ろう。"
        case .moveWell:
            return "動ける体は、日々の積み重ね。"
        case .health:
            return "健康な体が、全ての基盤。"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // 目標別キャッチコピー
            Text(goalBasedHeadline)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Color.mmOnboardingAccent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 8)

            Text(L10n.routineCompletionSub)
                .font(.subheadline)
                .foregroundStyle(Color.mmOnboardingTextSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(headerAppeared ? 1 : 0)

            Spacer().frame(height: 20)

            // ミニ筋肉マップ（ルーティン全体のカバー範囲）
            MiniMuscleMapView(muscleMapping: combinedMuscleMapping)
                .frame(height: 140)
                .padding(.horizontal, 60)
                .opacity(mapAppeared ? 1 : 0)
                .scaleEffect(mapAppeared ? 1 : 0.92)

            Spacer().frame(height: 20)

            // Dayサマリーカード
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(routine.days) { day in
                        daySummaryCard(day)
                    }

                    // 合計
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
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)

            Spacer()

            // CTAボタンエリア
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

    // MARK: - Dayサマリーカード

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
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        RoutineCompletionPage(onComplete: {})
    }
}
