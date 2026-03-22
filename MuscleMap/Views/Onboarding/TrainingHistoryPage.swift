import SwiftUI

// MARK: - プロフィール入力画面（トレ歴 + 体重 + ニックネーム統合）

/// TrainingHistoryPage + WeightInputPage を1ページに統合
/// コンパクト横並び経験セレクター + 体重ステッパー + ニックネーム
struct ProfileInputPage: View {
    let onNext: () -> Void

    @State private var selectedExperience: TrainingExperience?
    @State private var heightCm: Int = Int(AppState.shared.userProfile.heightCm)
    @State private var weightKg: Int = Int(AppState.shared.userProfile.weightKg)
    @State private var nickname: String = AppState.shared.userProfile.nickname
    @State private var selectedUnit: WeightUnit = AppState.shared.weightUnit
    @State private var bodyFatEnabled = AppState.shared.userProfile.bodyFatPercentage != nil
    @State private var bodyFatPct: Int = Int(AppState.shared.userProfile.bodyFatPercentage ?? 18)
    @State private var isProceeding = false
    @State private var appeared = false

    /// 経験選択肢の定義
    private struct ExpOption {
        let experience: TrainingExperience
        let icon: String
        let shortName: String
    }

    private var expOptions: [ExpOption] {
        [
            ExpOption(experience: .beginner, icon: "leaf.fill",
                      shortName: L10n.expNewbie),
            ExpOption(experience: .halfYear, icon: "dumbbell.fill",
                      shortName: L10n.expSixMonths),
            ExpOption(experience: .oneYearPlus, icon: "flame.fill",
                      shortName: L10n.expOneYearPlus),
            ExpOption(experience: .veteran, icon: "bolt.fill",
                      shortName: L10n.expVeteran),
        ]
    }

    /// 経験レベルに応じた筋肉マップ状態
    private var experienceMapStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            switch selectedExperience {
            case .beginner, .none:
                states[muscle] = .inactive
            case .halfYear:
                // 初心者が最初に鍛えがちな部位だけうっすら
                let earlyMuscles: Set<Muscle> = [.chestUpper, .chestLower, .biceps, .deltoidAnterior]
                states[muscle] = earlyMuscles.contains(muscle) ? .recovering(progress: 0.6) : .inactive
            case .oneYearPlus:
                // 主要部位がしっかり色付く
                let mainMuscles: Set<Muscle> = [.chestUpper, .chestLower, .lats, .quadriceps, .biceps, .triceps, .deltoidAnterior, .deltoidLateral]
                states[muscle] = mainMuscles.contains(muscle) ? .recovering(progress: 0.3) : .inactive
            case .veteran:
                // 全身がバランス良く色付く
                states[muscle] = .recovering(progress: 0.2)
            }
        }
        return states
    }

    /// 体重の表示値（単位に応じて変換）
    private var displayWeight: Int {
        switch selectedUnit {
        case .kg: return weightKg
        case .lb: return Int(round(Double(weightKg) * 2.20462))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    Spacer().frame(height: 16)

                    // タイトル
                    VStack(spacing: 6) {
                        Text(L10n.profileInputTitle)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color.mmOnboardingTextMain)
                            .multilineTextAlignment(.center)

                        Text(L10n.profileInputSubtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    // 筋肉マップミニビュー（経験レベルで色が変わる）
                    MuscleMapView(muscleStates: experienceMapStates)
                        .frame(height: 100)
                        .frame(maxWidth: 240)
                        .frame(maxWidth: .infinity)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedExperience)
                        .opacity(appeared ? 1 : 0)

                    // セクション1: トレーニング経験（横並び4択）
                    experienceSection

                    // セクション2: 身長ステッパー
                    heightStepperSection

                    // セクション3: 体重ステッパー
                    weightStepperSection

                    // セクション3.5: 体脂肪率（任意）
                    bodyFatSection

                    // 体組成表示
                    bodyCompositionSection

                    // セクション4: ニックネーム
                    nicknameSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            // 次へボタン
            nextButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmOnboardingBg)
        .onAppear {
            isProceeding = false  // スワイプ戻り時にボタンを有効化

            // 既存の値を読み込み
            let profile = AppState.shared.userProfile
            if profile.trainingExperience != .beginner || profile.weightKg != 70 {
                selectedExperience = profile.trainingExperience
            }
            heightCm = max(140, min(220, Int(profile.heightCm)))
            weightKg = max(30, Int(profile.weightKg))
            bodyFatEnabled = profile.bodyFatPercentage != nil
            bodyFatPct = Int(profile.bodyFatPercentage ?? 18)
            nickname = profile.nickname

            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
    }

    // MARK: - トレーニング経験セクション

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.trainingExpTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.mmOnboardingTextMain)

            HStack(spacing: 8) {
                ForEach(expOptions, id: \.experience) { option in
                    expButton(option)
                }
            }

            if selectedExperience == nil {
                Text(L10n.expRecommendNewbie)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.7))
            }
        }
    }

    private func expButton(_ option: ExpOption) -> some View {
        let isSelected = selectedExperience == option.experience

        return Button {
            guard !isProceeding else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedExperience = option.experience
            }
            HapticManager.lightTap()
            AppState.shared.userProfile.trainingExperience = option.experience
        } label: {
            VStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)

                Text(option.shortName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.1) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 身長ステッパーセクション

    private var heightStepperSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.heightLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(L10n.heightUsedForBMI)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.7))

                Spacer()
            }

            // ステッパー本体
            HStack {
                // マイナスボタン（タップ-1cm、長押し-5cm）
                Button {
                    guard heightCm > 140 else { return }
                    heightCm -= 1
                    AppState.shared.userProfile.heightCm = Double(heightCm)
                    HapticManager.lightTap()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .frame(width: 48, height: 48)
                        .background(Color.mmOnboardingAccent.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: 0.3) {
                    heightCm = max(140, heightCm - 5)
                    AppState.shared.userProfile.heightCm = Double(heightCm)
                    HapticManager.lightTap()
                }

                Spacer()

                // 身長表示
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(heightCm)")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: heightCm)

                    Text("cm")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }

                Spacer()

                // プラスボタン（タップ+1cm、長押し+5cm）
                Button {
                    guard heightCm < 220 else { return }
                    heightCm += 1
                    AppState.shared.userProfile.heightCm = Double(heightCm)
                    HapticManager.lightTap()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .frame(width: 48, height: 48)
                        .background(Color.mmOnboardingAccent.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .onLongPressGesture(minimumDuration: 0.3) {
                    heightCm = min(220, heightCm + 5)
                    AppState.shared.userProfile.heightCm = Double(heightCm)
                    HapticManager.lightTap()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - 体重ステッパーセクション

    private var weightStepperSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.profileWeightLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(L10n.weightUsedForSuggestion)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.7))

                Spacer()

                // kg/lb トグル
                HStack(spacing: 0) {
                    ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedUnit = unit
                                AppState.shared.weightUnit = unit
                            }
                            HapticManager.lightTap()
                        } label: {
                            Text(unit.displayName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(
                                    selectedUnit == unit
                                        ? Color.mmOnboardingBg
                                        : Color.mmOnboardingTextSub
                                )
                                .frame(width: 40, height: 28)
                                .background(
                                    selectedUnit == unit
                                        ? Color.mmOnboardingAccent
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(Color.mmOnboardingBg.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // ステッパー本体
            HStack {
                // マイナスボタン
                Button {
                    guard weightKg > 30 else { return }
                    weightKg -= 1
                    AppState.shared.userProfile.weightKg = Double(weightKg)
                    HapticManager.lightTap()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .frame(width: 48, height: 48)
                        .background(Color.mmOnboardingAccent.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                // 体重表示
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(displayWeight)")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: weightKg)

                    Text(selectedUnit.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }

                Spacer()

                // プラスボタン
                Button {
                    guard weightKg < 200 else { return }
                    weightKg += 1
                    AppState.shared.userProfile.weightKg = Double(weightKg)
                    HapticManager.lightTap()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .frame(width: 48, height: 48)
                        .background(Color.mmOnboardingAccent.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - 体脂肪率セクション（任意）

    private var bodyFatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(L10n.bodyFatLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(L10n.profileOptional)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mmOnboardingTextSub)

                Spacer()

                // ON/OFFトグル
                Toggle("", isOn: $bodyFatEnabled)
                    .labelsHidden()
                    .tint(Color.mmOnboardingAccent)
                    .onChange(of: bodyFatEnabled) { _, enabled in
                        if enabled {
                            AppState.shared.userProfile.bodyFatPercentage = Double(bodyFatPct)
                        } else {
                            AppState.shared.userProfile.bodyFatPercentage = nil
                        }
                    }
            }

            if bodyFatEnabled {
                // ステッパー本体
                HStack {
                    Button {
                        guard bodyFatPct > 5 else { return }
                        bodyFatPct -= 1
                        AppState.shared.userProfile.bodyFatPercentage = Double(bodyFatPct)
                        HapticManager.lightTap()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingAccent)
                            .frame(width: 48, height: 48)
                            .background(Color.mmOnboardingAccent.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(bodyFatPct)")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundStyle(Color.mmOnboardingTextMain)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.2), value: bodyFatPct)

                        Text("%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    Spacer()

                    Button {
                        guard bodyFatPct < 50 else { return }
                        bodyFatPct += 1
                        AppState.shared.userProfile.bodyFatPercentage = Double(bodyFatPct)
                        HapticManager.lightTap()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.mmOnboardingAccent)
                            .frame(width: 48, height: 48)
                            .background(Color.mmOnboardingAccent.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.mmOnboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - 体組成表示セクション

    /// BMI値
    private var bmiValue: Double {
        let h = Double(heightCm) / 100.0
        guard h > 0 else { return 0 }
        return Double(weightKg) / (h * h)
    }

    /// 体脂肪率ベースの評価ラベル
    private var bodyFatCategory: String {
        let pct = Double(bodyFatPct)
        // 男性基準（一般的なトレーニーの場合）
        if pct < 10 {
            return L10n.bfAthlete
        } else if pct < 15 {
            return L10n.bfFitness
        } else if pct < 20 {
            return L10n.bfAverage
        } else if pct < 25 {
            return L10n.bfAboveAverage
        } else {
            return L10n.bfHigh
        }
    }

    private var bodyCompositionSection: some View {
        HStack(spacing: 12) {
            // BMI数値のみ（ラベルなし）
            HStack(spacing: 4) {
                Text("BMI")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                Text(String(format: "%.1f", bmiValue))
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmOnboardingTextMain)
            }

            // 体脂肪率入力時はカテゴリ表示
            if bodyFatEnabled {
                HStack(spacing: 4) {
                    Text(L10n.bodyFatShort)
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                    Text("\(bodyFatPct)%")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmOnboardingAccent)
                    Text("(\(bodyFatCategory))")
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - ニックネームセクション

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(L10n.profileNicknameLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                Text(L10n.profileOptional)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }

            TextField(L10n.nicknamePlaceholder, text: $nickname)
                .font(.system(size: 18))
                .foregroundStyle(Color.mmOnboardingTextMain)
                .padding(16)
                .background(Color.mmOnboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: nickname) { _, newValue in
                    AppState.shared.userProfile.nickname = newValue
                }
        }
    }

    // MARK: - 次へボタン

    private var nextButton: some View {
        Button {
            guard !isProceeding, selectedExperience != nil else { return }
            isProceeding = true
            AppState.shared.userProfile.heightCm = Double(heightCm)
            AppState.shared.userProfile.weightKg = Double(weightKg)
            AppState.shared.userProfile.bodyFatPercentage = bodyFatEnabled ? Double(bodyFatPct) : nil
            AppState.shared.userProfile.nickname = nickname
            HapticManager.mediumTap()
            onNext()
        } label: {
            Text(L10n.next)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(selectedExperience != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if selectedExperience != nil {
                            LinearGradient(
                                colors: [.mmOnboardingAccent, .mmOnboardingAccentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.mmOnboardingCard
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(selectedExperience == nil)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .animation(.easeInOut(duration: 0.2), value: selectedExperience != nil)
        .opacity(appeared ? 1 : 0)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        ProfileInputPage(onNext: {})
    }
}
