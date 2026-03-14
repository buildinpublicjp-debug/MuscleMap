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
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
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

/// シェア用ワークアウトカード（360×360pt → @3x 1080×1080px 正方形）
struct WorkoutShareCard: View {
    let totalVolume: Double
    let totalSets: Int
    let exerciseCount: Int
    let date: Date
    let muscleMapping: [String: Int]
    /// 今回更新したPR一覧（最大2件表示）
    let prItems: [SharePRItem]
    /// トレーニング時間（分）
    var durationMinutes: Int = 0
    /// 現在の総合レベル
    var currentLevel: StrengthLevel?
    /// レベルアップがあったか
    var didLevelUp: Bool = false

    // MARK: - 定数

    private enum Layout {
        static let cardSize: CGFloat = 360
        static let cornerRadius: CGFloat = 24
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            // ダークグラデーション背景
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.mmBgPrimary, Color.mmBgSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // グリッド装飾（薄い）
            gridOverlay

            VStack(spacing: 0) {
                // 1. ヘッダー: ロゴ + 日付
                headerSection
                    .padding(.top, 16)

                // 2. タイトル: 「WORKOUT COMPLETE」
                Text("WORKOUT COMPLETE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .padding(.top, 8)

                // 3. 筋肉マップ（前後同時表示 + グロー効果）
                ShareMuscleMapView(
                    muscleMapping: muscleMapping,
                    mapHeight: 140,
                    glowEnabled: true
                )
                .padding(.horizontal, 40)
                .padding(.top, 8)

                // 4. メインスタット: 総ボリューム大表示
                volumeSection
                    .padding(.top, 8)

                // 5. PR更新セクション（ある場合のみ）
                if !prItems.isEmpty {
                    prSection
                        .padding(.top, 8)
                }

                // 6. サブスタット: 種目数・セット数・時間を横並び
                subStatsRow
                    .padding(.top, prItems.isEmpty ? 12 : 8)

                // 6.5 レベルバッジ
                if let level = currentLevel {
                    levelBadge(level: level, didLevelUp: didLevelUp)
                        .padding(.top, 6)
                }

                Spacer(minLength: 4)

                // 7. フッター: ウォーターマーク
                footerSection
                    .padding(.bottom, 14)
            }
        }
        .frame(width: Layout.cardSize, height: Layout.cardSize)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .environment(\.colorScheme, .dark)
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        HStack {
            // ロゴマーク
            HStack(spacing: 4) {
                // 簡易ロゴアイコン
                ZStack {
                    Circle()
                        .fill(Color.mmAccentPrimary.opacity(0.15))
                        .frame(width: 18, height: 18)
                    Text("M")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Color.mmAccentPrimary)
                }
                Text("MuscleMap")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            Spacer()

            // 日付
            Text(dateString)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.mmBorder)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - ボリュームセクション

    private var volumeSection: some View {
        VStack(spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(formatVolume(totalVolume))
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(Color.mmAccentPrimary)
                Text("kg")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.mmBorder)
            }
            Text("TOTAL VOLUME")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.mmBorder)
        }
    }

    // MARK: - PR更新セクション

    private var prSection: some View {
        VStack(spacing: 4) {
            // ヘッダー「🏆 NEW PR!」
            HStack(spacing: 4) {
                Text("🏆")
                    .font(.system(size: 10))
                Text("NEW PR!")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(Color.mmPRGold)
            }

            // PR行（最大2件）
            ForEach(Array(prItems.prefix(2).enumerated()), id: \.offset) { _, item in
                prRow(item: item)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.mmPRGold.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.mmPRGold.opacity(0.15), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 18)
    }

    private func prRow(item: SharePRItem) -> some View {
        HStack(spacing: 0) {
            Text(item.exerciseName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.mmTextPrimary)
                .lineLimit(1)

            Spacer(minLength: 4)

            // 重量遷移
            Text(formatWeight(item.previousWeight))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.mmBorder)
            Text(" → ")
                .font(.system(size: 11))
                .foregroundStyle(Color.mmBorder)
            Text(formatWeight(item.newWeight))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.mmPRGold)

            Text(" ↑\(item.increasePercent)%")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.mmPRGold)
        }
    }

    // MARK: - サブスタット横並び

    private var subStatsRow: some View {
        HStack(spacing: 0) {
            subStatItem(value: "\(exerciseCount)", label: "EXERCISES")
            subStatDivider
            subStatItem(value: "\(totalSets)", label: "SETS")
            if durationMinutes > 0 {
                subStatDivider
                subStatItem(value: "\(durationMinutes)", label: "MIN")
            }
        }
        .padding(.horizontal, 28)
    }

    private func subStatItem(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.mmTextPrimary)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Color.mmBorder)
        }
        .frame(maxWidth: .infinity)
    }

    private var subStatDivider: some View {
        Rectangle()
            .fill(Color.mmBorder.opacity(0.3))
            .frame(width: 0.5, height: 24)
    }

    // MARK: - フッター（ウォーターマーク）

    private var footerSection: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(Color.mmAccentPrimary.opacity(0.1))
                .frame(height: 0.5)
                .padding(.horizontal, 20)

            Text("MuscleMap — Track Your Muscles")
                .font(.system(size: 8, weight: .medium))
                .tracking(1)
                .foregroundStyle(Color.mmBorder.opacity(0.5))
        }
    }

    // MARK: - レベルバッジ

    private func levelBadge(level: StrengthLevel, didLevelUp: Bool) -> some View {
        Group {
            if didLevelUp {
                // レベルアップ表示
                HStack(spacing: 4) {
                    Text("💪→\(level.emoji)")
                        .font(.system(size: 10))
                    Text(L10n.levelUp)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Color.mmPRGold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.mmPRGold.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(Color.mmPRGold.opacity(0.25), lineWidth: 0.5)
                        )
                )
            } else {
                // 現在のレベル表示
                HStack(spacing: 3) {
                    Text(level.emoji)
                        .font(.system(size: 9))
                    Text(level.localizedName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(level.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(level.color.opacity(0.10))
                )
            }
        }
    }

    // MARK: - グリッド装飾

    private var gridOverlay: some View {
        Canvas { context, size in
            let lineColor = Color.white.opacity(0.02)
            let spacing: CGFloat = 20
            // 縦線
            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                x += spacing
            }
            // 横線
            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                y += spacing
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
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

#Preview("Workout Share Card - with PR (1:1)") {
    ZStack {
        Color.black.ignoresSafeArea()
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
                SharePRItem(exerciseName: "インクラインDB プレス", previousWeight: 90, newWeight: 100, increasePercent: 11),
                SharePRItem(exerciseName: "ベンチプレス", previousWeight: 80, newWeight: 85, increasePercent: 6)
            ],
            durationMinutes: 52
        )
    }
}

#Preview("Workout Share Card - no PR (1:1)") {
    ZStack {
        Color.black.ignoresSafeArea()
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
            prItems: [],
            durationMinutes: 38
        )
    }
}
