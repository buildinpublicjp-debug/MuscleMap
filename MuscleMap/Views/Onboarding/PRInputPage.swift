import SwiftUI

// MARK: - PR入力画面（経験者向け: oneYearPlus / veteran のみ表示）

struct PRInputPage: View {
    let onNext: () -> Void

    /// BIG3種目の定義
    private let big3Exercises: [(id: String, name: String)] = [
        ("barbell_bench_press", L10n.prBenchPress),
        ("barbell_back_squat", L10n.prSquat),
        ("deadlift", L10n.prDeadlift),
    ]

    @State private var benchPressText: String = ""
    @State private var squatText: String = ""
    @State private var deadliftText: String = ""
    @State private var appeared = false
    @State private var isProceeding = false

    /// デフォルト体重（体重未入力時の暫定値）
    private var bodyweightKg: Double {
        let weight = AppState.shared.userProfile.weightKg
        return weight > 0 ? weight : 70.0
    }

    /// 各種目の入力テキストへのバインディング配列
    private var textBindings: [Binding<String>] {
        [$benchPressText, $squatText, $deadliftText]
    }

    /// 入力値をDoubleに変換（kg）
    private func weightValue(from text: String) -> Double? {
        guard !text.isEmpty else { return nil }
        return Double(text)
    }

    /// 総合レベルの算出
    private var overallLevel: StrengthLevel? {
        let values = big3Exercises.enumerated().compactMap { index, exercise -> (String, Double)? in
            let text = [benchPressText, squatText, deadliftText][index]
            guard let weight = weightValue(from: text), weight > 0 else { return nil }
            return (exercise.id, weight)
        }
        guard !values.isEmpty else { return nil }

        // 各種目のスコアの平均を算出
        var totalScore = 0.0
        for (exerciseId, estimated1RM) in values {
            let result = StrengthScoreCalculator.exerciseStrengthLevel(
                exerciseId: exerciseId,
                estimated1RM: estimated1RM,
                bodyweightKg: bodyweightKg
            )
            totalScore += result.level.minimumScore
        }
        let avgScore = totalScore / Double(values.count)
        return StrengthScoreCalculator.level(score: avgScore)
    }

    /// 入力が1つ以上あるか
    private var hasAnyInput: Bool {
        [benchPressText, squatText, deadliftText].contains { weightValue(from: $0) != nil && weightValue(from: $0)! > 0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトルエリア
            VStack(spacing: 8) {
                Text(L10n.prInputTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.prInputSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 32)

            // BIG3入力フィールド
            VStack(spacing: 16) {
                ForEach(Array(big3Exercises.enumerated()), id: \.element.id) { index, exercise in
                    PRInputRow(
                        exerciseName: exercise.name,
                        exerciseId: exercise.id,
                        text: textBindings[index],
                        bodyweightKg: bodyweightKg
                    )
                }
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 32)

            // 総合レベル表示
            if let level = overallLevel {
                VStack(spacing: 8) {
                    Text(L10n.prOverallLevel)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmOnboardingTextSub)

                    HStack(spacing: 8) {
                        Text(level.emoji)
                            .font(.system(size: 32))
                        Text(level.localizedName)
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundStyle(level.color)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: overallLevel?.rawValue)
            }

            Spacer()

            // スキップ + 次へボタン
            VStack(spacing: 12) {
                // 次へボタン
                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    savePRs()
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
                                colors: [.mmOnboardingAccent, .mmOnboardingAccentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                // スキップボタン
                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    HapticManager.lightTap()
                    onNext()
                } label: {
                    Text(L10n.skip)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
    }

    // MARK: - Private

    /// PR入力値をUserProfileに保存
    private func savePRs() {
        var prs: [String: Double] = [:]
        for (index, exercise) in big3Exercises.enumerated() {
            let text = [benchPressText, squatText, deadliftText][index]
            if let weight = weightValue(from: text), weight > 0 {
                prs[exercise.id] = weight
            }
        }
        AppState.shared.userProfile.initialPRs = prs
    }
}

// MARK: - PR入力行

private struct PRInputRow: View {
    let exerciseName: String
    let exerciseId: String
    @Binding var text: String
    let bodyweightKg: Double

    /// 入力値に対応するレベル
    private var currentLevel: StrengthLevel? {
        guard let weight = Double(text), weight > 0 else { return nil }
        let result = StrengthScoreCalculator.exerciseStrengthLevel(
            exerciseId: exerciseId,
            estimated1RM: weight,
            bodyweightKg: bodyweightKg
        )
        return result.level
    }

    @State private var showLevel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.mmOnboardingTextMain)

            HStack(spacing: 12) {
                // 入力フィールド
                HStack(spacing: 4) {
                    TextField("0", text: $text)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .onChange(of: text) { _, newValue in
                            // 数字以外を除去
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { text = filtered }

                            withAnimation(.easeInOut(duration: 0.3)) {
                                showLevel = Double(filtered) != nil && Double(filtered)! > 0
                            }
                        }

                    Text("kg")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.mmOnboardingBg.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // レベルバッジ
                if showLevel, let level = currentLevel {
                    HStack(spacing: 4) {
                        Text(level.emoji)
                            .font(.system(size: 16))
                        Text(level.localizedName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(level.color)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(level.color.opacity(0.15))
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        PRInputPage(onNext: {})
    }
}
