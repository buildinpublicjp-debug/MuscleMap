import SwiftUI

// MARK: - 完了アイコン（紙吹雪エフェクト付き）

struct CompletionIcon: View {
    @State private var showConfetti = false

    // 紙吹雪パーティクル定義（6個）
    private let confettiItems: [(color: Color, offsetX: CGFloat, offsetY: CGFloat, rotation: Double)] = [
        (.mmAccentPrimary, -50, -40, 45),
        (.mmPRGold, 45, -50, -30),
        (.mmAccentSecondary, -40, 30, 60),
        (.mmAccentPrimary, 55, 20, -45),
        (.mmPRGold, -20, -55, 120),
        (.mmAccentSecondary, 30, 45, -60),
    ]

    var body: some View {
        ZStack {
            // 紙吹雪パーティクル
            ForEach(Array(confettiItems.enumerated()), id: \.offset) { index, item in
                Circle()
                    .fill(item.color)
                    .frame(width: CGFloat.random(in: 5...9), height: CGFloat.random(in: 5...9))
                    .offset(
                        x: showConfetti ? item.offsetX : 0,
                        y: showConfetti ? item.offsetY : 0
                    )
                    .opacity(showConfetti ? 0 : 1)
                    .scaleEffect(showConfetti ? 0.3 : 0.01)
                    .animation(
                        .easeOut(duration: 1.5)
                        .delay(Double(index) * 0.05),
                        value: showConfetti
                    )
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - 統計カード

struct CompletionStatsCard: View {
    let totalVolume: Double
    let uniqueExercises: Int
    let totalSets: Int
    let duration: String

    var body: some View {
        HStack(spacing: 0) {
            StatBox(value: formatVolume(totalVolume), label: L10n.totalVolume, icon: "scalemass")
            StatBox(value: "\(uniqueExercises)", label: L10n.exercises, icon: "figure.strengthtraining.traditional")
            StatBox(value: "\(totalSets)", label: L10n.sets, icon: "number")
            StatBox(value: duration, label: L10n.time, icon: "clock")
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - 刺激した筋肉セクション

struct StimulatedMusclesSection: View {
    let muscleMapping: [String: Int]

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
                .frame(height: 220)

                // 背面
                MiniMuscleMapView(
                    muscleMapping: muscleMapping,
                    showFront: false
                )
                .aspectRatio(0.6, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
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

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title3)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text("90日で体の変化を証明する")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                }

                Text("Strength Map + 種目別グラフで成長を可視化")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Proを始める")
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

                Text(L10n.nextRecommendedDay)
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

            Text(L10n.basedOnRecoveryPrediction)
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
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

// MARK: - 完了ボタンセクション（レガシー互換用、新レイアウトではWorkoutCompletionViewで直接配置）

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

// MARK: - Preview

#Preview("Completion Icon") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        CompletionIcon()
    }
}

#Preview("Stats Card") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        CompletionStatsCard(
            totalVolume: 5250,
            uniqueExercises: 5,
            totalSets: 20,
            duration: "45分"
        )
        .padding()
    }
}
