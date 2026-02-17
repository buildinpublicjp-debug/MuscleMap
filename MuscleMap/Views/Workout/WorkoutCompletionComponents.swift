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

/// シェア用ワークアウトカード（Instagram Stories最適サイズ: 9:16比率 390 x 693）
struct WorkoutShareCard: View {
    let totalVolume: Double
    let totalSets: Int
    let exerciseCount: Int
    let duration: String
    let exerciseNames: [String]
    let date: Date
    let muscleMapping: [String: Int]

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

            VStack(spacing: 16) {
                // ヘッダー（統一デザイン）
                HStack {
                    Text("MuscleMap")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.mmTextPrimary)
                    Spacer()
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // タイトル
                Text("WORKOUT COMPLETE")
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmAccentPrimary)

                // 筋肉マップ（大きく表示）
                ShareMuscleMapView(muscleMapping: muscleMapping)
                    .padding(.vertical, 8)

                // 統計（より目立つスタイル）
                HStack(spacing: 8) {
                    ShareStatItemBold(value: formatVolume(totalVolume), unit: "kg", label: L10n.volume)
                    ShareStatItemBold(value: "\(exerciseCount)", unit: nil, label: L10n.exercises)
                    ShareStatItemBold(value: "\(totalSets)", unit: nil, label: L10n.sets)
                    ShareStatItemBold(value: duration, unit: nil, label: L10n.time)
                }
                .padding(.horizontal, 20)

                // 種目リスト
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(exerciseNames.prefix(4), id: \.self) { name in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.mmAccentPrimary)
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(Color.mmTextPrimary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    if exerciseNames.count > 4 {
                        Text(L10n.andMoreCount(exerciseNames.count - 4))
                            .font(.caption2)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // フッター（シンプル）
                VStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.mmAccentPrimary.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    Text("MuscleMap")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.6))
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

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - シェア統計アイテム

/// シェア用統計アイテム（通常）
private struct ShareStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.mmTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// シェアカード用の目立つ統計アイテム
private struct ShareStatItemBold: View {
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)
                if let unit = unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
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

#Preview("Share Stat Items") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        VStack(spacing: 20) {
            HStack {
                ShareStatItem(value: "10.5k", label: "Volume")
                ShareStatItem(value: "45", label: "Sets")
                ShareStatItem(value: "8", label: "Exercises")
            }

            HStack {
                ShareStatItemBold(value: "10.5", unit: "k", label: "Volume")
                ShareStatItemBold(value: "45", unit: nil, label: "Sets")
                ShareStatItemBold(value: "8", unit: nil, label: "Exercises")
            }
        }
        .padding()
    }
}
