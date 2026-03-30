import SwiftUI

// MARK: - メニュー詳細プレビューシート

/// 「メニューを確認する」から表示されるハーフモーダル
/// 各種目のGIF・対象筋肉・提案重量を確認してからワークアウト開始できる
struct MenuPreviewSheet: View {
    let recommendation: RecommendedWorkout
    let suggestedMenu: SuggestedMenu
    let onStart: ([RecommendedExercise]) -> Void

    @Environment(\.dismiss) private var dismiss

    /// RoutineDayからMenuPreviewSheetを生成する便利イニシャライザ
    init(routineDay: RoutineDay, previousWeightProvider: @escaping (String) -> Double?, onStart: @escaping ([RecommendedExercise]) -> Void) {
        let loc = LocalizationManager.shared
        let exercises: [RecommendedExercise] = routineDay.exercises.compactMap { re in
            guard let def = ExerciseStore.shared.exercise(for: re.exerciseId) else { return nil }
            let name = loc.currentLanguage == .japanese ? def.nameJA : def.nameEN
            let prevW = previousWeightProvider(re.exerciseId)
            return RecommendedExercise(
                exerciseId: re.exerciseId,
                exerciseName: name,
                suggestedWeight: prevW ?? 0,
                suggestedReps: re.suggestedReps,
                suggestedSets: re.suggestedSets,
                previousWeight: prevW,
                weightIncrease: 0
            )
        }
        self.recommendation = RecommendedWorkout(
            muscleGroup: routineDay.name,
            exercises: exercises
        )
        // RoutineDay経由の場合、SuggestedMenuはダミー
        let primaryGroup = MuscleGroup(rawValue: routineDay.muscleGroups.first ?? "") ?? .chest
        self.suggestedMenu = SuggestedMenu(
            primaryGroup: primaryGroup,
            reason: routineDay.name,
            exercises: [],
            neglectedWarning: nil
        )
        self.onStart = onStart
    }

    /// 標準イニシャライザ
    init(recommendation: RecommendedWorkout, suggestedMenu: SuggestedMenu, onStart: @escaping ([RecommendedExercise]) -> Void) {
        self.recommendation = recommendation
        self.suggestedMenu = suggestedMenu
        self.onStart = onStart
    }

    /// 全種目の対象筋肉をまとめたマッピング（ミニ筋肉マップ用）
    private var combinedMuscleMapping: [String: Int] {
        var mapping: [String: Int] = [:]
        let store = ExerciseStore.shared
        for exercise in recommendation.exercises {
            guard let def = store.exercise(for: exercise.exerciseId) else { continue }
            for (muscleId, intensity) in def.muscleMapping {
                mapping[muscleId] = max(mapping[muscleId] ?? 0, intensity)
            }
        }
        return mapping
    }

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerSection

            // 種目リスト + 筋肉マップ
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(recommendation.exercises) { exercise in
                        ExercisePreviewCard(exercise: exercise)
                    }

                    // 鍛える筋肉マップ
                    muscleMapSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100) // ボタン分の余白
            }

            Spacer(minLength: 0)

            // 「このメニューで始める」ボタン
            startButton
        }
        .background(Color.mmBgSecondary)
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.todayMenuTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)

                Text(recommendation.muscleGroup)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.mmBgCard)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - 筋肉マップセクション

    private var muscleMapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.trainedMuscles)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.mmTextSecondary)

            MiniMuscleMapView(muscleMapping: combinedMuscleMapping)
                .frame(height: 120)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 開始ボタン

    private var startButton: some View {
        VStack(spacing: 0) {
            // 上部グラデーションフェード
            LinearGradient(
                colors: [Color.mmBgSecondary.opacity(0), Color.mmBgSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            Button {
                HapticManager.lightTap()
                onStart(recommendation.exercises)
            } label: {
                Text(L10n.startWithThisMenu)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.mmBgPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.mmAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .background(Color.mmBgSecondary)
        }
    }
}

// MARK: - 種目プレビューカード

/// メニュー内の各種目をGIF + 筋肉情報 + 重量提案で表示
private struct ExercisePreviewCard: View {
    let exercise: RecommendedExercise

    /// 種目定義（ExerciseStoreから取得）
    private var definition: ExerciseDefinition? {
        ExerciseStore.shared.exercise(for: exercise.exerciseId)
    }

    /// 対象筋肉名のカンマ区切り
    private var targetMuscleNames: String {
        guard let def = definition else { return "" }
        let muscles = def.muscleMapping
            .sorted { $0.value > $1.value }
            .compactMap { Muscle(rawValue: $0.key)?.localizedName }
        return muscles.prefix(3).joined(separator: "、")
    }

    /// 重量フォーマット
    private func formatWeight(_ weight: Double) -> String {
        if weight == floor(weight) {
            return "\(Int(weight))"
        }
        return String(format: "%.1f", weight)
    }

    var body: some View {
        HStack(spacing: 12) {
            // 左: GIF画像 or プレースホルダー
            gifThumbnail

            // 右: 種目情報
            VStack(alignment: .leading, spacing: 4) {
                // 種目名
                Text(exercise.exerciseName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)

                // 対象筋肉
                if !targetMuscleNames.isEmpty {
                    Text(targetMuscleNames)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.mmTextSecondary)
                        .lineLimit(1)
                }

                // 提案の重量×レップ×セット
                HStack(spacing: 8) {
                    if exercise.suggestedWeight > 0 {
                        Text("\(formatWeight(exercise.suggestedWeight))kg × \(exercise.suggestedReps) × \(exercise.suggestedSets)")
                            .font(.system(size: 14).monospacedDigit())
                            .foregroundStyle(Color.mmAccentPrimary)
                    } else {
                        Text("\(exercise.suggestedSets) × \(exercise.suggestedReps)")
                            .font(.system(size: 14).monospacedDigit())
                            .foregroundStyle(Color.mmAccentPrimary)
                    }
                }

                // 前回記録
                if let prev = exercise.previousWeight, prev > 0 {
                    Text(L10n.previousRecord("\(formatWeight(prev))kg × \(exercise.suggestedReps) × \(exercise.suggestedSets)"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mmTextSecondary.opacity(0.7))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - GIFサムネイル

    @ViewBuilder
    private var gifThumbnail: some View {
        if ExerciseGifView.hasGif(exerciseId: exercise.exerciseId) {
            ExerciseGifView(exerciseId: exercise.exerciseId, size: .thumbnail)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            // プレースホルダー
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mmBgPrimary)
                    .frame(width: 80, height: 80)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let exercises = [
        RecommendedExercise(
            exerciseId: "barbell_bench_press",
            exerciseName: "ベンチプレス",
            suggestedWeight: 62.5,
            suggestedReps: 8,
            suggestedSets: 3,
            previousWeight: 60.0,
            weightIncrease: 2.5
        ),
        RecommendedExercise(
            exerciseId: "incline_dumbbell_press",
            exerciseName: "インクラインダンベルプレス",
            suggestedWeight: 22.5,
            suggestedReps: 10,
            suggestedSets: 3,
            previousWeight: 20.0,
            weightIncrease: 2.5
        ),
        RecommendedExercise(
            exerciseId: "cable_crossover",
            exerciseName: "ケーブルクロスオーバー",
            suggestedWeight: 0,
            suggestedReps: 12,
            suggestedSets: 3,
            previousWeight: nil,
            weightIncrease: 0
        ),
    ]

    let recommendation = RecommendedWorkout(
        muscleGroup: "胸・三頭",
        exercises: exercises
    )

    let menu = SuggestedMenu(
        primaryGroup: .chest,
        reason: "胸が回復済み",
        exercises: [],
        neglectedWarning: nil
    )

    MenuPreviewSheet(
        recommendation: recommendation,
        suggestedMenu: menu,
        onStart: { _ in }
    )
    .presentationDetents([.large])
}
