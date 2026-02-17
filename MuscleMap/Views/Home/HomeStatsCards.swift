import SwiftUI

// MARK: - 統計を見るボタン

struct ViewStatsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title3)
                    .foregroundStyle(Color.mmAccentPrimary)

                Text(L10n.viewStats)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 初回ユーザー向けCTA

struct FirstWorkoutCTA: View {
    let onStartWorkout: () -> Void

    var body: some View {
        Button(action: onStartWorkout) {
            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.mmAccentPrimary)

                Text(L10n.startFirstWorkout)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)

                Text(L10n.firstWorkoutHint)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
                    .multilineTextAlignment(.center)

                // 開始ボタン
                HStack {
                    Image(systemName: "play.fill")
                    Text(L10n.startWorkout)
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.mmBgPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.mmAccentPrimary)
                .clipShape(Capsule())
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - マッスル・ジャーニーカード

struct MuscleJourneyCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentSecondary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentSecondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.muscleJourney)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.journeyCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - トレーニングヒートマップカード

struct TrainingHeatmapCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.trainingHeatmap)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.heatmapCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 筋肉バランス診断カード

struct BalanceDiagnosisCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // アイコン
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title2)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.mmAccentPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // テキスト
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.muscleBalanceDiagnosis)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.diagnosisCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                // 矢印
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
