import SwiftUI
import UIKit

// MARK: - シェア用データ

/// PR更新情報（シェアカード表示用）
struct SharePRItem {
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let increasePercent: Int
}

/// 種目エントリ（シェアカード表示用）
struct ShareExerciseEntry {
    let exerciseName: String
    let weight: Double
    let reps: Int
}

// MARK: - シェア用ワークアウトカード（種目フォーカス版、360×360pt → @3x 1080×1080px）

struct WorkoutShareCard: View {
    let exerciseEntries: [ShareExerciseEntry]
    let totalSets: Int
    let exerciseCount: Int
    let date: Date
    let muscleMapping: [String: Int]
    let prItems: [SharePRItem]
    var durationMinutes: Int = 0

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

            gridOverlay

            VStack(spacing: 0) {
                // 1. ヘッダー: ロゴ + 日付
                headerSection
                    .padding(.top, 16)

                // 2. タイトル
                Text("WORKOUT COMPLETE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(Color.mmAccentPrimary)
                    .padding(.top, 8)

                // 3. 筋肉マップ
                ShareMuscleMapView(
                    muscleMapping: muscleMapping,
                    mapHeight: 130,
                    glowEnabled: true
                )
                .padding(.horizontal, 40)
                .padding(.top, 6)

                // 4. 種目リスト（最大3種目）
                exerciseListSection
                    .padding(.top, 10)

                // 5. PR更新セクション
                if !prItems.isEmpty {
                    prSection
                        .padding(.top, 8)
                }

                // 6. サマリー1行
                summaryLine
                    .padding(.top, prItems.isEmpty ? 10 : 8)

                Spacer(minLength: 4)

                // 7. フッター
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
            HStack(spacing: 4) {
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

            Text(dateString)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.mmBorder)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 種目リスト

    private var exerciseListSection: some View {
        VStack(spacing: 3) {
            ForEach(Array(exerciseEntries.prefix(3).enumerated()), id: \.offset) { _, entry in
                HStack(spacing: 0) {
                    Text(entry.exerciseName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text("\(formatWeight(entry.weight))×\(entry.reps)")
                        .font(.system(size: 12, weight: .bold).monospaced())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - PRセクション

    private var prSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmPRGold)

            ForEach(Array(prItems.prefix(2).enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.mmPRGold.opacity(0.5))
                }
                Text("\(item.exerciseName) ↑\(item.increasePercent)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.mmPRGold)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - サマリー1行

    private var summaryLine: some View {
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

    // MARK: - フッター

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

    // MARK: - グリッド装飾

    private var gridOverlay: some View {
        Canvas { context, size in
            let lineColor = Color.white.opacity(0.02)
            let spacing: CGFloat = 20
            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                x += spacing
            }
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

    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0fkg", weight)
        }
        return String(format: "%.1fkg", weight)
    }
}

// MARK: - シェアシート

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

#Preview("Workout Share Card - with PR") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        WorkoutShareCard(
            exerciseEntries: [
                ShareExerciseEntry(exerciseName: "ベンチプレス", weight: 100, reps: 10),
                ShareExerciseEntry(exerciseName: "インクラインDBプレス", weight: 67, reps: 10),
                ShareExerciseEntry(exerciseName: "ケーブルクロス", weight: 30, reps: 12)
            ],
            totalSets: 12,
            exerciseCount: 3,
            date: Date(),
            muscleMapping: [
                "chest_upper": 100,
                "chest_lower": 85,
                "deltoid_anterior": 60,
                "triceps": 45
            ],
            prItems: [
                SharePRItem(exerciseName: "ベンチプレス", previousWeight: 90, newWeight: 100, increasePercent: 11)
            ],
            durationMinutes: 42
        )
    }
}

#Preview("Workout Share Card - no PR") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        WorkoutShareCard(
            exerciseEntries: [
                ShareExerciseEntry(exerciseName: "ラットプルダウン", weight: 60, reps: 10),
                ShareExerciseEntry(exerciseName: "バーベルロウ", weight: 70, reps: 8)
            ],
            totalSets: 18,
            exerciseCount: 5,
            date: Date(),
            muscleMapping: [
                "lats": 100,
                "traps_upper": 70,
                "biceps": 60
            ],
            prItems: [],
            durationMinutes: 38
        )
    }
}
