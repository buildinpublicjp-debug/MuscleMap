import SwiftUI

// MARK: - 完了アイコン（スプリングスケール + PR時紙吹雪エフェクト）

struct CompletionIcon: View {
    var hasPR: Bool = false
    @State private var showConfetti = false
    @State private var iconScale: CGFloat = 0

    // 紙吹雪パーティクル定義（30個、3色、広範囲に散布）
    private let confettiItems: [(color: Color, offsetX: CGFloat, offsetY: CGFloat, rotation: Double, isRect: Bool)] = {
        var items: [(Color, CGFloat, CGFloat, Double, Bool)] = []
        let colors: [Color] = [.mmAccentPrimary, .mmPRGold, .mmAccentSecondary]
        for i in 0..<30 {
            let angle = Double(i) * (360.0 / 30.0)
            let radius: CGFloat = CGFloat.random(in: 60...130)
            let x = cos(angle * .pi / 180) * Double(radius)
            let y = sin(angle * .pi / 180) * Double(radius)
            let rot = Double.random(in: -120...120)
            items.append((colors[i % 3], CGFloat(x), CGFloat(y), rot, i % 2 == 0))
        }
        return items
    }()

    var body: some View {
        ZStack {
            // PR時の紙吹雪パーティクル
            if hasPR {
                ForEach(Array(confettiItems.enumerated()), id: \.offset) { index, item in
                    Group {
                        if item.isRect {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.color)
                                .frame(width: 8, height: 5)
                        } else {
                            Circle()
                                .fill(item.color)
                                .frame(width: 7, height: 7)
                        }
                    }
                    .rotationEffect(.degrees(showConfetti ? item.rotation : 0))
                    .offset(
                        x: showConfetti ? item.offsetX : 0,
                        y: showConfetti ? item.offsetY : 0
                    )
                    .opacity(showConfetti ? 0 : 1)
                    .scaleEffect(showConfetti ? 0.5 : 0.01)
                    .animation(
                        .easeOut(duration: 2.0)
                        .delay(Double(index) * 0.02),
                        value: showConfetti
                    )
                }
            }

            // メインアイコン
            Circle()
                .fill(Color.mmAccentPrimary.opacity(0.2))
                .frame(width: 100, height: 100)

            Circle()
                .fill(Color.mmAccentPrimary.opacity(0.4))
                .frame(width: 80, height: 80)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.mmAccentPrimary)
        }
        .scaleEffect(iconScale)
        .onAppear {
            // スプリングスケールアニメーション（0→1）
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                iconScale = 1.0
            }
            // PR時の紙吹雪（遅延発射）
            if hasPR {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
    }
}

// MARK: - モチベーショナルサマリー

struct MotivationalSummary: View {
    let totalVolume: Double
    let hasPR: Bool
    let exerciseCount: Int

    @State private var summaryScale: CGFloat = 0.8
    @State private var summaryOpacity: Double = 0

    /// モチベーショナルテキスト
    var motivationalText: String {
        if totalVolume > 10000 {
            return L10n.beastModeActivated
        } else if hasPR {
            return L10n.newRecordsSet
        } else if exerciseCount >= 4 {
            return L10n.solidSession
        } else {
            return L10n.goodWork
        }
    }

    var body: some View {
        Text(motivationalText)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(Color.mmAccentPrimary)
            .multilineTextAlignment(.center)
            .scaleEffect(summaryScale)
            .opacity(summaryOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                    summaryScale = 1.0
                    summaryOpacity = 1.0
                }
            }
    }
}

// MARK: - PR祝福データモデル

struct PRCelebrationItem: Identifiable {
    let id = UUID()
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let increasePercent: Int
}

// MARK: - PR祝福セクション（ゴールドグラデーション + スケールアニメーション）

struct PRCelebrationSection: View {
    let prUpdates: [PRCelebrationItem]

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // ゴールドグラデーションヘッダー
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(L10n.newPR)
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(1.5)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 16
                )
                .fill(
                    LinearGradient(
                        colors: [Color.mmPRGold, Color.mmWarning],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )

            // PR行リスト
            VStack(spacing: 0) {
                ForEach(Array(prUpdates.enumerated()), id: \.element.id) { index, item in
                    prCelebrationRow(item: item, index: index)

                    if index < prUpdates.count - 1 {
                        Divider()
                            .background(Color.mmBorder.opacity(0.3))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 0
                )
                .fill(Color.mmBgCard)
            )
        }
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                appeared = true
            }
            // PR達成ハプティクス
            HapticManager.prAchieved()
        }
    }

    private func prCelebrationRow(item: PRCelebrationItem, index: Int) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formatWeight(item.previousWeight))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.mmTextSecondary)
                    Text(formatWeight(item.newWeight))
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmPRGold)
                }
            }

            Spacer()

            // 増加率バッジ
            Text("↑\(item.increasePercent)%")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .scaleEffect(appeared ? 1 : 0.8)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
            .delay(0.4 + Double(index) * 0.1),
            value: appeared
        )
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fkg", weight)
        }
        return String(format: "%.1fkg", weight)
    }
}

// MARK: - 統計カード（ボリューム巨大 + 3カード横並びカスケード）

struct CompletionStatsCard: View {
    let totalVolume: Double
    let uniqueExercises: Int
    let totalSets: Int
    let duration: String
    var animationDelay: Double = 0

    @State private var statsAppeared = false

    /// カンマ区切りフォーマッタ
    private var formattedVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalVolume)) ?? "\(Int(totalVolume))"
    }

    var body: some View {
        VStack(spacing: 16) {
            // メインボリューム表示（48px Heavy）
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedVolume)
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(Color.mmAccentPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("kg")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.mmTextSecondary)
            }

            // 3カード横並び（種目数・セット数・時間）
            HStack(spacing: 12) {
                completionStatCard(
                    value: "\(uniqueExercises)",
                    label: L10n.exercises,
                    icon: "figure.strengthtraining.traditional",
                    delay: 0
                )
                completionStatCard(
                    value: "\(totalSets)",
                    label: L10n.sets,
                    icon: "number",
                    delay: 0.1
                )
                completionStatCard(
                    value: duration,
                    label: L10n.time,
                    icon: "clock",
                    delay: 0.2
                )
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .offset(y: statsAppeared ? 0 : 20)
        .opacity(statsAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(animationDelay)) {
                statsAppeared = true
            }
        }
    }

    private func completionStatCard(value: String, label: String, icon: String, delay: Double) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.mmBgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 刺激した筋肉セクション（パルスグロー + 筋肉名表示）

struct StimulatedMusclesSection: View {
    let muscleMapping: [String: Int]

    @State private var glowPulsing = false

    /// 刺激された筋肉名リスト
    private var stimulatedMuscleNames: [String] {
        muscleMapping.compactMap { key, value -> String? in
            guard value > 0, let muscle = Muscle(rawValue: key) else { return nil }
            return muscle.localizedName
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.stimulatedMuscles)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            HStack(spacing: 12) {
                // 前面
                MiniMuscleMapView(
                    muscleMapping: muscleMapping,
                    showFront: true
                )
                .aspectRatio(0.6, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 240)

                // 背面
                MiniMuscleMapView(
                    muscleMapping: muscleMapping,
                    showFront: false
                )
                .aspectRatio(0.6, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 240)
            }
            .shadow(
                color: Color.mmAccentPrimary.opacity(glowPulsing ? 0.3 : 0.1),
                radius: glowPulsing ? 12 : 6,
                x: 0, y: 0
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulsing = true
                }
            }

            // 刺激された筋肉名をアクセントカラーで表示
            if !stimulatedMuscleNames.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(stimulatedMuscleNames, id: \.self) { name in
                        Text(name)
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.mmAccentPrimary.opacity(0.1))
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


// MARK: - 完了種目リスト

struct CompletionExerciseList: View {
    let exercises: [ExerciseDefinition]
    let setsCountProvider: (String) -> Int
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.exercisesDone)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            ForEach(exercises) { exercise in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                    Spacer()
                    Text(L10n.setsLabel(setsCountProvider(exercise.id)))
                        .font(.caption.monospaced())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 非Pro Paywall誘導バナー

/// 完了画面のExerciseListの下に常時表示（isPremium == false 時のみ）
struct CompletionProBanner: View {
    let onTap: () -> Void
    private var isJapanese: Bool { LocalizationManager.shared.currentLanguage == .japanese }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title3)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(isJapanese ? "90日で体の変化を証明する" : "Prove your transformation in 90 days")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                Text(isJapanese ? "Strength Map + 種目別グラフで成長を可視化" : "Visualize growth with Strength Map & trends")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text(isJapanese ? "Proを始める" : "Start Pro")
                            .font(.caption.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }
            }
            .padding(16)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 次回おすすめ日セクション

struct NextRecommendedDaySection: View {
    /// 今回刺激した筋肉 → セッション内セット数
    let stimulatedMuscles: [(muscle: Muscle, totalSets: Int)]
    /// 次回ルーティンDay名（あれば）
    var nextRoutineName: String?

    @State private var reminderScheduled = false

    /// 今日の刺激部位のうち最も回復が遅いものの完全回復日
    private var recommendedDate: Date {
        let now = Date()
        var maxHours: Double = 0
        for entry in stimulatedMuscles {
            let hours = RecoveryCalculator.adjustedRecoveryHours(
                muscle: entry.muscle,
                totalSets: entry.totalSets
            )
            maxHours = max(maxHours, hours)
        }
        return now.addingTimeInterval(maxHours * 3600)
    }

    private var daysUntil: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: recommendedDate)
        return max(0, cal.dateComponents([.day], from: today, to: target).day ?? 0)
    }

    private var dateLabel: String {
        if daysUntil <= 0 { return L10n.today }
        if daysUntil == 1 { return L10n.tomorrow }
        let fmt = DateFormatter()
        fmt.dateFormat = LocalizationManager.shared.currentLanguage == .japanese
            ? "M月d日（E）"
            : "MMM d (EEE)"
        fmt.locale = LocalizationManager.shared.currentLanguage.locale
        return fmt.string(from: recommendedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.headline)
                    .foregroundStyle(Color.mmAccentSecondary)

                Text(L10n.nextWorkoutSuggestion)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(dateLabel)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Color.mmAccentPrimary)

                if daysUntil > 1 {
                    Text(L10n.nextBestDateLabel(""))
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }

            // 次回ルーティンDay名
            if let routineName = nextRoutineName {
                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentSecondary)
                    Text(routineName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }
            }

            Text(L10n.basedOnRecoveryPrediction)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)

            // リマインダー設定CTA
            Button {
                HapticManager.lightTap()
                NotificationManager.shared.scheduleRecoveryReminder(
                    nextPartName: nextRoutineName ?? (LocalizationManager.shared.currentLanguage == .japanese ? "トレーニング" : "Training"),
                    recoveryDate: recommendedDate
                )
                withAnimation {
                    reminderScheduled = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: reminderScheduled ? "checkmark.circle.fill" : "bell.badge")
                        .font(.subheadline)
                    Text(reminderScheduled ? L10n.reminderScheduled : L10n.scheduleReminder)
                        .font(.subheadline.bold())
                }
                .foregroundStyle(reminderScheduled ? Color.mmAccentPrimary : Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(reminderScheduled ? Color.mmAccentPrimary.opacity(0.15) : Color.mmAccentPrimary)
                )
            }
            .buttonStyle(.plain)
            .disabled(reminderScheduled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Strength Mapシェアボタン（PR更新時のみ表示）

struct StrengthMapShareSection: View {
    let onShareStrengthMap: () -> Void

    var body: some View {
        Button(action: onShareStrengthMap) {
            HStack(spacing: 12) {
                // アイコン
                ZStack {
                    Circle()
                        .fill(Color.mmAccentSecondary.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.mmAccentSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(L10n.prUpdated)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                    Text(L10n.shareStrengthMap)
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(Color.mmAccentSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mmBgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.mmAccentSecondary.opacity(0.4), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 完了ボタンセクション（レガシー互換用）

struct CompletionButtonSection: View {
    let onShare: () -> Void
    let onDismiss: () -> Void
    var onProTap: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            // シェアボタン
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.share)
                }
                .font(.headline)
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 閉じるボタン
            Button(action: onDismiss) {
                Text(L10n.close)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - レベルアップ情報モデル

struct LevelUpInfo: Identifiable {
    let id = UUID()
    let exerciseName: String
    let previousLevel: StrengthLevel
    let newLevel: StrengthLevel
    let kgToNext: Double?
    let nextLevel: StrengthLevel?
}

// MARK: - レベルアップ祝福セクション

struct LevelUpCelebrationSection: View {
    let levelUps: [LevelUpInfo]

    @State private var appeared = false
    @State private var showConfetti = false

    private var localization: LocalizationManager { LocalizationManager.shared }

    // 紙吹雪パーティクル（レベルアップ用、新レベルカラー基調）
    private let confettiItems: [(offsetX: CGFloat, offsetY: CGFloat, rotation: Double, isRect: Bool)] = [
        (-80, -45, 40, false),
        (75, -55, -35, true),
        (-65, 35, 55, false),
        (90, 25, -50, true),
        (-25, -70, 110, false),
        (45, 60, -65, true),
        (-100, -5, 85, false),
        (110, -30, -80, true),
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(levelUps) { info in
                levelUpCard(info: info)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
            HapticManager.prAchieved()
        }
    }

    @ViewBuilder
    private func levelUpCard(info: LevelUpInfo) -> some View {
        ZStack {
            // 紙吹雪
            ForEach(Array(confettiItems.enumerated()), id: \.offset) { index, item in
                Group {
                    if item.isRect {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(info.newLevel.color)
                            .frame(width: 7, height: 4)
                    } else {
                        Circle()
                            .fill(info.newLevel.color)
                            .frame(width: 6, height: 6)
                    }
                }
                .rotationEffect(.degrees(showConfetti ? item.rotation : 0))
                .offset(
                    x: showConfetti ? item.offsetX : 0,
                    y: showConfetti ? item.offsetY : 0
                )
                .opacity(showConfetti ? 0 : 1)
                .scaleEffect(showConfetti ? 0.5 : 0.01)
                .animation(
                    .easeOut(duration: 1.2).delay(Double(index) * 0.04),
                    value: showConfetti
                )
            }

            // カード本体
            VStack(spacing: 8) {
                // ヘッダー
                Text(L10n.levelUp)
                    .font(.caption.bold())
                    .foregroundStyle(info.newLevel.color)

                // 種目名
                Text(info.exerciseName)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)

                // レベル遷移
                HStack(spacing: 8) {
                    // 旧レベル
                    HStack(spacing: 4) {
                        Text(info.previousLevel.emoji)
                            .font(.body)
                        Text(localization.currentLanguage == .japanese ? info.previousLevel.japaneseName : info.previousLevel.englishName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(info.previousLevel.color)
                    }

                    // 矢印
                    Image(systemName: "arrow.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmTextSecondary)

                    // 新レベル
                    HStack(spacing: 4) {
                        Text(info.newLevel.emoji)
                            .font(.body)
                        Text(localization.currentLanguage == .japanese ? info.newLevel.japaneseName : info.newLevel.englishName)
                            .font(.subheadline.bold())
                            .foregroundStyle(info.newLevel.color)
                    }
                }

                // 次レベルまでのヒント
                if let kgToNext = info.kgToNext, let nextLvl = info.nextLevel {
                    let nextName = localization.currentLanguage == .japanese ? nextLvl.japaneseName : nextLvl.englishName
                    Text(L10n.levelUpKgToNext(Int(ceil(kgToNext)), nextName))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(info.newLevel.color.opacity(0.4), lineWidth: 1.5)
            )
        }
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
    }
}

// MARK: - Preview

#Preview("Level Up") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        LevelUpCelebrationSection(levelUps: [
            LevelUpInfo(
                exerciseName: "ベンチプレス",
                previousLevel: .intermediate,
                newLevel: .advanced,
                kgToNext: 25,
                nextLevel: .elite
            )
        ])
        .padding()
    }
}

#Preview("Completion Icon") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        CompletionIcon(hasPR: true)
    }
}

#Preview("Stats Card") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        CompletionStatsCard(
            totalVolume: 12450,
            uniqueExercises: 5,
            totalSets: 20,
            duration: "45分",
            animationDelay: 0
        )
        .padding()
    }
}

#Preview("PR Celebration") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        PRCelebrationSection(prUpdates: [
            PRCelebrationItem(exerciseName: "ベンチプレス", previousWeight: 80, newWeight: 90, increasePercent: 13),
            PRCelebrationItem(exerciseName: "スクワット", previousWeight: 100, newWeight: 110, increasePercent: 10)
        ])
        .padding()
    }
}

#Preview("Motivational Summary") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        MotivationalSummary(totalVolume: 15000, hasPR: true, exerciseCount: 6)
    }
}
