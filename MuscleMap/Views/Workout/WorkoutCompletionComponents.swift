import SwiftUI
import UIKit

// MARK: - シェア用データ

/// PR更新情報（シェアカード表示用、現状は他画面互換のため残す）
struct SharePRItem {
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let increasePercent: Int
}

/// シェアカード用 1セット表示エントリ
struct ShareSetEntry: Identifiable {
    let id = UUID()
    let setNumber: Int
    let weight: Double
    let reps: Int
    let isPR: Bool
}

/// シェアカード用 種目グループ (種目名 + 全セット)
struct ShareExerciseEntry: Identifiable {
    let id = UUID()
    let exerciseName: String
    let sets: [ShareSetEntry]
}

// MARK: - シェア用ワークアウトカード（Stories 9:16、360×640pt → @3x 1080×1920px）
//
// 用途: Instagram Stories 等への投稿。完了画面 (in-app) と異なり技術指標は出さない。
// 含める: マッスルマップ、ヒーロー数値 (種目/セット/分)、全種目全セットリスト、PR王冠。
// 含めない: e1RM、過去最高、BW比、PR差分、編集/シェアボタン (画像内には出さない)。

struct WorkoutShareCard: View {
    let exerciseEntries: [ShareExerciseEntry]
    let totalSets: Int
    let exerciseCount: Int
    let durationMinutes: Int
    let date: Date
    let muscleMapping: [String: Int]

    private enum Layout {
        static let cardWidth: CGFloat = 360
        static let cardHeight: CGFloat = 640
        static let cornerRadius: CGFloat = 24
        static let horizontalPadding: CGFloat = 24
    }

    private var dateString: String {
        let formatter = DateFormatter()
        if LocalizationManager.shared.currentLanguage == .japanese {
            formatter.dateFormat = "M/d (E)"
            formatter.locale = Locale(identifier: "ja_JP")
        } else {
            formatter.dateFormat = "M/d (E)"
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            // 背景
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color.mmBgCard)

            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                // 1. マッスルマップ + FRONT/BACK ラベル
                muscleMapSection

                Spacer().frame(height: 12)

                // 2. ヒーロー数値: 6 / 17 / 110
                heroNumbersSection

                Spacer().frame(height: 12)

                divider

                // 3. 種目リスト (全種目全セット)
                exerciseListSection
                    .padding(.horizontal, Layout.horizontalPadding)

                Spacer(minLength: 8)

                divider

                Spacer().frame(height: 12)

                // 4. フッター
                footerSection

                Spacer().frame(height: 16)
            }
        }
        .frame(width: Layout.cardWidth, height: Layout.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .environment(\.colorScheme, .dark)
    }

    // MARK: - マッスルマップ section

    private var muscleMapSection: some View {
        VStack(spacing: 6) {
            ShareMuscleMapView(
                muscleMapping: muscleMapping,
                mapHeight: 130,
                glowEnabled: false
            )
            HStack(spacing: 0) {
                Text("FRONT")
                    .frame(maxWidth: .infinity)
                Text("BACK")
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 10, weight: .regular))
            .tracking(2)
            .foregroundStyle(Color.mmTextSecondary)
            .padding(.horizontal, 80)
        }
    }

    // MARK: - ヒーロー数値 section

    private var heroNumbersSection: some View {
        HStack(spacing: 0) {
            heroColumn(value: "\(exerciseCount)", label: L10n.exercises)
            heroDivider
            heroColumn(value: "\(totalSets)", label: L10n.sets)
            heroDivider
            heroColumn(value: "\(durationMinutes)", label: L10n.shareCardMinLabel)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private func heroColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color.mmAccentPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(Color.mmTextSecondary.opacity(0.2))
            .frame(width: 0.5, height: 32)
    }

    // MARK: - 種目リスト section (全種目全セット)

    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(exerciseEntries) { exercise in
                exerciseGroup(exercise)
            }
        }
    }

    private func exerciseGroup(_ exercise: ShareExerciseEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.exerciseName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.mmTextOnDark)
                .lineLimit(1)
            ForEach(exercise.sets) { set in
                shareSetRow(set)
            }
        }
    }

    /// 1セット分の行 — 3列 (set# / 重量×回数 / 王冠)
    private func shareSetRow(_ set: ShareSetEntry) -> some View {
        HStack(spacing: 6) {
            Text("\(set.setNumber)")
                .frame(width: 14, alignment: .leading)
                .foregroundStyle(Color.mmTextSecondary)

            Text(formatWeightReps(weight: set.weight, reps: set.reps))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .foregroundStyle(Color.mmTextOnDark)

            Image(systemName: "crown.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.mmAccentPrimary)
                .opacity(set.isPR ? 1 : 0)
                .frame(width: 12, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .regular, design: .monospaced))
    }

    private func formatWeightReps(weight: Double, reps: Int) -> String {
        if weight > 0 {
            let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", weight)
                : String(format: "%.1f", weight)
            return "\(weightStr) kg × \(reps)"
        } else {
            return LocalizationManager.shared.currentLanguage == .japanese
                ? "自重 × \(reps)"
                : "BW × \(reps)"
        }
    }

    // MARK: - 区切り線

    private var divider: some View {
        Rectangle()
            .fill(Color.mmTextSecondary.opacity(0.15))
            .frame(height: 0.5)
            .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - フッター

    private var footerSection: some View {
        HStack {
            Text("MuscleMap")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
            Spacer()
            Text(dateString)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.horizontal, Layout.horizontalPadding)
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

#Preview("Workout Share Card - 6種目17セット") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        WorkoutShareCard(
            exerciseEntries: [
                ShareExerciseEntry(exerciseName: "インクラインチェストプレス (マシン)", sets: [
                    ShareSetEntry(setNumber: 1, weight: 70, reps: 11, isPR: false),
                    ShareSetEntry(setNumber: 2, weight: 70, reps: 8, isPR: false),
                    ShareSetEntry(setNumber: 3, weight: 70, reps: 5, isPR: false)
                ]),
                ShareExerciseEntry(exerciseName: "バーベルベンチプレス", sets: [
                    ShareSetEntry(setNumber: 1, weight: 50, reps: 8, isPR: false),
                    ShareSetEntry(setNumber: 2, weight: 50, reps: 4, isPR: false),
                    ShareSetEntry(setNumber: 3, weight: 50, reps: 4, isPR: false)
                ]),
                ShareExerciseEntry(exerciseName: "リアデルトフライ", sets: [
                    ShareSetEntry(setNumber: 1, weight: 14, reps: 10, isPR: false),
                    ShareSetEntry(setNumber: 2, weight: 14, reps: 10, isPR: false),
                    ShareSetEntry(setNumber: 3, weight: 14, reps: 10, isPR: false)
                ]),
                ShareExerciseEntry(exerciseName: "サイドレイズ", sets: [
                    ShareSetEntry(setNumber: 1, weight: 14, reps: 13, isPR: true),
                    ShareSetEntry(setNumber: 2, weight: 14, reps: 12, isPR: false),
                    ShareSetEntry(setNumber: 3, weight: 14, reps: 12, isPR: false)
                ]),
                ShareExerciseEntry(exerciseName: "シーテッドケーブルロウ", sets: [
                    ShareSetEntry(setNumber: 1, weight: 50, reps: 10, isPR: true),
                    ShareSetEntry(setNumber: 2, weight: 50, reps: 8, isPR: false)
                ]),
                ShareExerciseEntry(exerciseName: "トライセプスプッシュダウン", sets: [
                    ShareSetEntry(setNumber: 1, weight: 31.2, reps: 8, isPR: false),
                    ShareSetEntry(setNumber: 2, weight: 31.2, reps: 6, isPR: false),
                    ShareSetEntry(setNumber: 3, weight: 31.2, reps: 6, isPR: false)
                ])
            ],
            totalSets: 17,
            exerciseCount: 6,
            durationMinutes: 110,
            date: Date(),
            muscleMapping: [
                "chest_upper": 100,
                "chest_lower": 85,
                "deltoid_anterior": 60,
                "deltoid_lateral": 80,
                "deltoid_posterior": 70,
                "triceps": 65,
                "lats": 55,
                "traps_middle_lower": 45
            ]
        )
    }
}
