import SwiftUI

// MARK: - 週間トレーニング頻度

@MainActor
enum WeeklyFrequency: Int, CaseIterable, Codable {
    case twice = 2
    case thrice = 3
    case four = 4
    case fivePlus = 5

    var title: String {
        let isJapanese = LocalizationManager.shared.currentLanguage == .japanese
        switch self {
        case .twice: return isJapanese ? "週2回" : "2× / week"
        case .thrice: return isJapanese ? "週3回" : "3× / week"
        case .four: return isJapanese ? "週4回" : "4× / week"
        case .fivePlus: return isJapanese ? "週5回以上" : "5+ / week"
        }
    }

    var subtitle: String {
        let isJapanese = LocalizationManager.shared.currentLanguage == .japanese
        switch self {
        case .twice: return isJapanese ? "上半身と下半身を分けて鍛える" : "Upper body & lower body split"
        case .thrice: return isJapanese ? "胸・背中・脚の3分割" : "Chest, back & legs — 3 day split"
        case .four: return isJapanese ? "部位ごとにしっかり追い込む" : "Dedicated day for each muscle group"
        case .fivePlus: return isJapanese ? "毎日違う部位をフルで鍛える" : "Full volume per muscle group daily"
        }
    }

    /// 医学的根拠テキスト
    var evidenceText: String {
        let isJapanese = LocalizationManager.shared.currentLanguage == .japanese
        switch self {
        case .twice: return isJapanese ? "各部位に十分な回復時間。初心者に最適" : "Full recovery time. Best for beginners"
        case .thrice: return isJapanese ? "胸・背中・脚の王道3分割" : "Classic 3-day split for balanced growth"
        case .four: return isJapanese ? "部位ごとにしっかり追い込む" : "Dedicated focus per muscle group"
        case .fivePlus: return isJapanese ? "各部位を個別にフルで鍛える" : "Maximum volume per muscle group"
        }
    }

    /// スケジュールプレビュー用の曜日割り当て（日英対応）
    var schedulePreview: [String] {
        let isJapanese = LocalizationManager.shared.currentLanguage == .japanese
        switch self {
        case .twice:
            return isJapanese
                ? ["上半身", "OFF", "下半身", "OFF", "OFF", "OFF", "OFF"]
                : ["Upper", "OFF", "Lower", "OFF", "OFF", "OFF", "OFF"]
        case .thrice:
            return isJapanese
                ? ["胸・肩", "OFF", "背中", "OFF", "脚", "OFF", "OFF"]
                : ["Chest", "OFF", "Back", "OFF", "Legs", "OFF", "OFF"]
        case .four:
            return isJapanese
                ? ["胸", "背中", "OFF", "肩・腕", "脚", "OFF", "OFF"]
                : ["Chest", "Back", "OFF", "Arms", "Legs", "OFF", "OFF"]
        case .fivePlus:
            return isJapanese
                ? ["胸", "背中", "肩", "腕", "脚", "OFF", "OFF"]
                : ["Chest", "Back", "Shldrs", "Arms", "Legs", "OFF", "OFF"]
        }
    }

    /// アニメーション用: 各曜日にどのパートを刺激するか（0-indexed day → SplitPart index, nil=OFF）
    var trainingDays: [Int: Int] {
        switch self {
        case .twice: return [0: 0, 2: 1] // 月: 上半身, 水: 下半身
        case .thrice: return [0: 0, 2: 1, 4: 2] // 月: Push, 水: Pull, 金: Legs
        case .four: return [0: 0, 1: 1, 3: 2, 4: 3] // 月: 胸肩三頭, 火: 背中二頭, 木: 脚, 金: 肩腕
        case .fivePlus: return [0: 0, 1: 1, 2: 2, 3: 3, 4: 4] // 月〜金
        }
    }
}

// MARK: - 頻度選択画面（超回復アニメーション付き）

struct FrequencySelectionPage: View {
    let onNext: (WeeklyFrequency) -> Void

    @State private var selected: WeeklyFrequency?
    @State private var appeared = false
    @State private var isProceeding = false

    // 超回復アニメーション
    @State private var animationDay: Int = 0
    @State private var muscleStates: [Muscle: MuscleVisualState] = [:]
    @State private var animationTimerRef: Timer?

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            // ヘッダー
            VStack(spacing: 8) {
                Text(isJapanese ? "週にどれくらいやれる？" : "How often can you train?")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(isJapanese ? "あなたに合った分割法を提案します" : "We'll suggest the best split for you")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 16)

            // 筋肉マップ（超回復アニメーション）
            MuscleMapView(
                muscleStates: muscleStates,
                onMuscleTapped: nil
            )
            .frame(height: 220)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)

            // 色のレジェンド（マップとタイムラインの間）
            HStack(spacing: 16) {
                legendItem(color: Color.red.opacity(0.8), text: isJapanese ? "刺激" : "Stimulus")
                legendItem(color: Color.yellow.opacity(0.8), text: isJapanese ? "回復中" : "Recovering")
                legendItem(color: Color.mmOnboardingTextSub.opacity(0.3), text: isJapanese ? "未刺激" : "Inactive")
            }
            .font(.system(size: 9))
            .padding(.top, 4)
            .opacity(appeared ? 1 : 0)

            // ヒントテキスト or タイムラインバー
            if selected == nil {
                Text(isJapanese ? "頻度を選ぶとサイクルが動きます" : "Select to see the recovery cycle")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
            } else {
                // 超回復の1行説明
                Text(isJapanese
                    ? "赤＝刺激 → 黄＝回復中 → 暗い＝回復完了。このサイクルで鍛える"
                    : "Red = stimulated → Yellow = recovering → Dark = recovered")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .transition(.opacity)

                timelineBar
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .transition(.opacity)
            }

            Spacer().frame(height: 16)

            // 選択カード（コンパクトリスト）
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(WeeklyFrequency.allCases.enumerated()), id: \.element) { index, frequency in
                        FrequencyCompactCard(
                            frequency: frequency,
                            isSelected: selected == frequency,
                            onTap: {
                                guard !isProceeding else { return }
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selected = frequency
                                }
                                HapticManager.lightTap()
                                startRecoveryAnimation(frequency: frequency)
                            }
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08 + 0.3), value: appeared)
                    }
                }
                .padding(.horizontal, 24)

                // 医学的根拠テキスト
                if let freq = selected {
                    evidenceSection(for: freq)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .scrollIndicators(.hidden)

            Spacer()

            // 次へボタン
            Button {
                guard !isProceeding, let freq = selected else { return }
                isProceeding = true
                HapticManager.lightTap()
                stopAnimation()
                onNext(freq)
            } label: {
                Text(L10n.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(selected != nil ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if selected != nil {
                                LinearGradient(
                                    colors: [Color.mmOnboardingAccent, Color.mmOnboardingAccentDark],
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
            .disabled(selected == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .onAppear {
            isProceeding = false  // スワイプ戻り時にボタンを有効化

            // 初期状態: 全筋肉inactive
            var initial: [Muscle: MuscleVisualState] = [:]
            for muscle in Muscle.allCases {
                initial[muscle] = .inactive
            }
            muscleStates = initial

            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }

    // MARK: - タイムラインバー

    private var timelineBar: some View {
        let dayLabels = isJapanese
            ? ["月", "火", "水", "木", "金", "土", "日"]
            : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let schedule = selected?.schedulePreview ?? []

        return HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { day in
                let content = day < schedule.count ? schedule[day] : "OFF"
                let isTrainingDay = content != "OFF"
                let isCurrentAnimDay = day == animationDay && selected != nil

                VStack(spacing: 4) {
                    // 曜日
                    Text(dayLabels[day])
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isCurrentAnimDay ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)

                    // トレーニング内容（「胸」「背中」等）or 「−」
                    if isTrainingDay {
                        Text(content)
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(isCurrentAnimDay ? Color.mmOnboardingAccent : Color.mmOnboardingTextMain)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } else {
                        Text("−")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.3))
                    }

                    // バー（トレーニング日は太く、OFFは細く）
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isCurrentAnimDay ? Color.mmOnboardingAccent
                              : isTrainingDay ? Color.mmOnboardingCard
                              : Color.mmOnboardingCard.opacity(0.3))
                        .frame(height: isTrainingDay ? 8 : 3)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 医学的根拠セクション

    private func evidenceSection(for frequency: WeeklyFrequency) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 14))
                .foregroundStyle(Color.mmOnboardingAccent.opacity(0.7))

            Text(frequency.evidenceText)
                .font(.system(size: 13))
                .foregroundStyle(Color.mmOnboardingTextSub)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - レジェンドアイテム

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).foregroundStyle(Color.mmOnboardingTextSub)
        }
    }

    // MARK: - 超回復アニメーション

    private func startRecoveryAnimation(frequency: WeeklyFrequency) {
        stopAnimation()
        animationDay = 0

        let parts = WorkoutRecommendationEngine.splitParts(for: frequency.rawValue)
        let trainingDays = frequency.trainingDays

        updateMuscleStatesForDay(0, parts: parts, trainingDays: trainingDays)

        let timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [trainingDays] _ in
            Task { @MainActor in
                animationDay = (animationDay + 1) % 7
                updateMuscleStatesForDay(animationDay, parts: parts, trainingDays: trainingDays)
            }
        }
        animationTimerRef = timer
    }

    private func stopAnimation() {
        animationTimerRef?.invalidate()
        animationTimerRef = nil
    }

    private func updateMuscleStatesForDay(_ day: Int, parts: [SplitPart], trainingDays: [Int: Int]) {
        // まず全筋肉をinactiveに（刺激なし = 暗いまま）
        var states: [Muscle: MuscleVisualState] = [:]
        for muscle in Muscle.allCases {
            states[muscle] = .inactive
        }

        // 刺激があった筋肉だけ色を設定
        for muscle in Muscle.allCases {
            let daysSince = calculateDaysSinceStimulation(
                muscle: muscle, currentDay: day, trainingDays: trainingDays, parts: parts
            )

            if daysSince == 0 {
                // 今日刺激 → 赤（疲労開始）
                states[muscle] = .recovering(progress: 0.05)
            } else if daysSince > 0 {
                // 回復中 → 経過時間に応じて赤→黄
                let recoveryHours = Double(muscle.baseRecoveryHours)
                let elapsedHours = Double(daysSince) * 24.0
                let progress = elapsedHours / recoveryHours
                if progress >= 1.0 {
                    // 回復完了 → 暗い色に戻す（inactiveのまま）
                    states[muscle] = .inactive
                } else {
                    // まだ回復中 → 赤→黄のグラデーション
                    states[muscle] = .recovering(progress: progress)
                }
            }
            // daysSince < 0 → .inactive のまま（暗い色）
        }

        withAnimation(.easeInOut(duration: 0.4)) {
            muscleStates = states
        }
    }

    /// この筋肉が最後に刺激されてから何日経ったか計算（-1 = まだ刺激されてない）
    private func calculateDaysSinceStimulation(
        muscle: Muscle,
        currentDay: Int,
        trainingDays: [Int: Int],
        parts: [SplitPart]
    ) -> Int {
        // currentDay から過去方向に探索（currentDayまでの範囲のみ、ラップアラウンドしない）
        for offset in 0...currentDay {
            let checkDay = currentDay - offset
            if let partIndex = trainingDays[checkDay], partIndex < parts.count {
                let part = parts[partIndex]
                // このパートに筋肉が含まれるか
                let musclesInPart = part.muscleGroups.flatMap { $0.muscles }
                if musclesInPart.contains(muscle) {
                    return offset
                }
            }
        }
        return -1 // まだ刺激されてない（今週まだトレーニングされていない）
    }
}

// MARK: - コンパクト頻度カード

private struct FrequencyCompactCard: View {
    let frequency: WeeklyFrequency
    let isSelected: Bool
    let onTap: () -> Void

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 左アクセントバー
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 12)

                HStack(spacing: 12) {
                    // 回数バッジ
                    Text("\(frequency.rawValue)")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingTextSub)
                        .frame(width: 36, height: 36)

                    // テキスト
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(frequency.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingTextMain)

                            if frequency == .twice {
                                Text(isJapanese ? "初心者におすすめ" : "Recommended")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.mmOnboardingAccent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.mmOnboardingAccent.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(frequency.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    Spacer()

                    // チェックマーク
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 24, height: 24)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 50)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.08) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.mmOnboardingAccent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        FrequencySelectionPage(onNext: { _ in })
    }
}
