import SwiftUI
import UIKit

// MARK: - ワークアウト完了画面コンポーネント

/// 統計ボックス
struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.mmAccentPrimary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - シェア用カード（画像レンダリング用）

/// PR更新情報（シェアカード表示用）
struct SharePRItem {
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let increasePercent: Int
}

/// シェア用ワークアウトカード（390×693pt、@3x書き出し）
struct WorkoutShareCard: View {
    let totalVolume: Double
    let totalSets: Int
    let exerciseCount: Int
    let date: Date
    let muscleMapping: [String: Int]
    /// 今回更新したPR一覧（最大2件表示）
    let prItems: [SharePRItem]

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 上部グラデーションアクセント
            LinearGradient(
                colors: [Color.mmAccentPrimary, Color.mmAccentSecondary],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)

            VStack(spacing: 0) {
                // 1. ヘッダー: 「MuscleMap」左 + 日付右
                HStack {
                    Text("MuscleMap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(dateString)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // 2. タイトル: 「WORKOUT COMPLETE」
                Text("WORKOUT COMPLETE")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .padding(.bottom, 16)

                // 3. 筋肉図（220pt）: 前面・背面を並列
                ShareMuscleMapView(muscleMapping: muscleMapping, mapHeight: 210)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // 4. メインスタット: ボリューム数値を大きく中央
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formatVolume(totalVolume))
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text("kg")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                    Text("TOTAL VOLUME")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.bottom, prItems.isEmpty ? 20 : 16)

                // 5. 前回比セクション（PR更新がある場合のみ表示）
                if !prItems.isEmpty {
                    prSection
                        .padding(.bottom, 16)
                }

                // 6. サブスタット: 種目数・セット数を小さく横並び
                HStack(spacing: 0) {
                    subStatItem(value: "\(exerciseCount)", label: L10n.exercises)
                    subStatDivider
                    subStatItem(value: "\(totalSets)", label: L10n.sets)
                }
                .padding(.horizontal, 40)

                Spacer(minLength: 8)

                // 7. フッター: 「MuscleMap」ロゴのみ
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    Text("MuscleMap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: 390, height: 693)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.mmAccentPrimary.opacity(0.3), lineWidth: 2)
        }
        .padding(8)
        .background(Color.mmBgPrimary)
    }

    // MARK: - PR更新セクション

    private var prSection: some View {
        VStack(spacing: 8) {
            // セクションヘッダー
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmAccentPrimary)
                Text("PR UPDATE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(Color.mmAccentPrimary)
            }
            .padding(.bottom, 2)

            // PR更新行（最大2件）
            ForEach(Array(prItems.prefix(2).enumerated()), id: \.offset) { _, item in
                prRow(item: item)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.mmAccentPrimary.opacity(0.06))
        )
        .padding(.horizontal, 20)
    }

    private func prRow(item: SharePRItem) -> some View {
        HStack(spacing: 0) {
            Text(item.exerciseName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            // 重量遷移
            Text(formatWeight(item.previousWeight))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
            Text(" → ")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
            Text(formatWeight(item.newWeight))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.mmAccentPrimary)

            // 増加率
            Text(" ↑\(item.increasePercent)%")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.mmAccentPrimary)
        }
    }

    // MARK: - サブスタット

    private func subStatItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.mmTextPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var subStatDivider: some View {
        Rectangle()
            .fill(Color.mmTextSecondary.opacity(0.3))
            .frame(width: 1, height: 32)
    }

    // MARK: - フォーマット

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 10000 {
            return String(format: "%.1fk", volume / 1000)
        } else if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fkg", weight)
        }
        return String(format: "%.1fkg", weight)
    }
}

// MARK: - シェアシート

/// システムシェアシート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onComplete?()
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Stat Box") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        HStack {
            StatBox(value: "10,500kg", label: "Volume", icon: "scalemass")
            StatBox(value: "45", label: "Sets", icon: "number")
            StatBox(value: "8", label: "Exercises", icon: "dumbbell")
        }
        .padding()
    }
}

#Preview("Workout Share Card - with PR") {
    ScrollView {
        WorkoutShareCard(
            totalVolume: 12500,
            totalSets: 24,
            exerciseCount: 6,
            date: Date(),
            muscleMapping: [
                "chest_upper": 100,
                "chest_lower": 85,
                "deltoid_anterior": 60,
                "triceps": 45,
                "biceps": 30,
                "lats": 70,
                "glutes": 50
            ],
            prItems: [
                SharePRItem(exerciseName: "インクラインダンベルプレス", previousWeight: 90, newWeight: 100, increasePercent: 11),
                SharePRItem(exerciseName: "ベンチプレス", previousWeight: 80, newWeight: 85, increasePercent: 6)
            ]
        )
    }
}

#Preview("Workout Share Card - no PR") {
    ScrollView {
        WorkoutShareCard(
            totalVolume: 8200,
            totalSets: 18,
            exerciseCount: 5,
            date: Date(),
            muscleMapping: [
                "lats": 100,
                "traps_upper": 70,
                "biceps": 60,
                "forearms": 40
            ],
            prItems: []
        )
    }
}
