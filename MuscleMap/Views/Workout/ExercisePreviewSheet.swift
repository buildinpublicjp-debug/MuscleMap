import SwiftUI

// MARK: - 種目プレビューシート（ハーフモーダル）

struct ExercisePreviewSheet: View {
    let exercise: ExerciseDefinition
    let onAddExercise: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var exerciseName: String {
        localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
    }

    private var secondaryName: String {
        localization.currentLanguage == .japanese ? exercise.nameEN : exercise.nameJA
    }

    /// Primary筋肉（刺激度60%以上）
    private var primaryMuscles: [Muscle] {
        exercise.muscleMapping
            .filter { $0.value >= 60 }
            .compactMap { Muscle(rawValue: $0.key) ?? Muscle(snakeCase: $0.key) }
            .sorted { (exercise.muscleMapping[$0.rawValue] ?? 0) > (exercise.muscleMapping[$1.rawValue] ?? 0) }
    }

    /// Secondary筋肉（刺激度60%未満）
    private var secondaryMuscles: [Muscle] {
        exercise.muscleMapping
            .filter { $0.value < 60 }
            .compactMap { Muscle(rawValue: $0.key) ?? Muscle(snakeCase: $0.key) }
            .sorted { (exercise.muscleMapping[$0.rawValue] ?? 0) > (exercise.muscleMapping[$1.rawValue] ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 種目名
                        exerciseNameSection

                        // ミニ筋肉マップ
                        muscleMapSection

                        // 対象筋肉リスト
                        targetMusclesSection

                        // YouTubeボタン
                        youtubeButtonSection

                        // この種目を追加ボタン（ワークアウトフローからの場合のみ）
                        if onAddExercise != nil {
                            addExerciseButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.exerciseInfo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 種目名セクション

    private var exerciseNameSection: some View {
        VStack(spacing: 4) {
            Text(exerciseName)
                .font(.title2.bold())
                .foregroundStyle(Color.mmTextPrimary)
                .multilineTextAlignment(.center)

            Text(secondaryName)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextSecondary)

            // 基本情報タグ
            HStack(spacing: 8) {
                InfoChip(icon: "dumbbell", text: exercise.localizedEquipment)
                InfoChip(icon: "chart.bar", text: exercise.localizedDifficulty)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - 筋肉マップセクション

    private var muscleMapSection: some View {
        VStack(spacing: 8) {
            // ラベル
            HStack {
                Text(L10n.targetMuscles)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                Spacer()
            }

            // GIF + ミニマップ横並び（GIFがある場合）
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                HStack(spacing: 10) {
                    ExerciseGifView(exerciseId: exercise.id, size: .medium)

                    PreviewMuscleMapView(
                        muscleMapping: exercise.muscleMapping,
                        primaryThreshold: 60
                    )
                    .frame(height: 150)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // GIFがない場合は従来通りMuscleMap単体
                PreviewMuscleMapView(
                    muscleMapping: exercise.muscleMapping,
                    primaryThreshold: 60
                )
                .frame(height: 180)
                .background(Color.mmBgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 凡例
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.mmMuscleJustWorked)
                        .frame(width: 10, height: 10)
                    Text(L10n.primaryTarget)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.mmMuscleAmber)
                        .frame(width: 10, height: 10)
                    Text(L10n.secondaryTarget)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
    }

    // MARK: - 対象筋肉リストセクション

    private var targetMusclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Primary
            if !primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.primaryTarget)
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmMuscleJustWorked)

                    FlowLayout(spacing: 6) {
                        ForEach(primaryMuscles, id: \.self) { muscle in
                            MuscleChip(
                                muscle: muscle,
                                percentage: exercise.muscleMapping[muscle.rawValue] ?? exercise.muscleMapping[muscle.rawValue.toSnakeCase()] ?? 0,
                                isPrimary: true
                            )
                        }
                    }
                }
            }

            // Secondary
            if !secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.secondaryTarget)
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmMuscleAmber)

                    FlowLayout(spacing: 6) {
                        ForEach(secondaryMuscles, id: \.self) { muscle in
                            MuscleChip(
                                muscle: muscle,
                                percentage: exercise.muscleMapping[muscle.rawValue] ?? exercise.muscleMapping[muscle.rawValue.toSnakeCase()] ?? 0,
                                isPrimary: false
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - YouTubeボタンセクション

    private var youtubeButtonSection: some View {
        Button {
            if let url = YouTubeSearchHelper.searchURL(for: exercise) {
                UIApplication.shared.open(url)
            }
            HapticManager.lightTap()
        } label: {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.watchFormVideo)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.openInYouTube)
                        .font(.caption2)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - この種目を追加ボタン

    private var addExerciseButton: some View {
        Button {
            HapticManager.lightTap()
            onAddExercise?()
            dismiss()
        } label: {
            Text(L10n.addThisExercise)
                .font(.headline)
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - プレビュー用筋肉マップ（Primary/Secondary色分け）

private struct PreviewMuscleMapView: View {
    let muscleMapping: [String: Int]
    let primaryThreshold: Int

    private var shouldShowFront: Bool {
        let frontMuscles = Set(MusclePathData.frontMuscles.map { $0.muscle.rawValue.toSnakeCase() })
        let backMuscles = Set(MusclePathData.backMuscles.map { $0.muscle.rawValue.toSnakeCase() })

        var frontScore = 0
        var backScore = 0

        for (muscleId, intensity) in muscleMapping {
            if frontMuscles.contains(muscleId) {
                frontScore += intensity
            }
            if backMuscles.contains(muscleId) {
                backScore += intensity
            }
        }

        return frontScore >= backScore
    }

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)

            ZStack {
                let muscles = shouldShowFront
                    ? MusclePathData.frontMuscles
                    : MusclePathData.backMuscles

                ForEach(muscles, id: \.muscle) { entry in
                    let stimulation = stimulationFor(entry.muscle)
                    let path = entry.path(rect)

                    path
                        .fill(colorFor(stimulation: stimulation))
                    path
                        .stroke(Color.mmMuscleBorder.opacity(0.3), lineWidth: 0.5)
                }
            }
        }
    }

    private func stimulationFor(_ muscle: Muscle) -> Int {
        if let value = muscleMapping[muscle.rawValue] {
            return value
        }
        let snakeCase = muscle.rawValue.toSnakeCase()
        if let value = muscleMapping[snakeCase] {
            return value
        }
        return 0
    }

    private func colorFor(stimulation: Int) -> Color {
        guard stimulation > 0 else {
            return Color.mmTextSecondary.opacity(0.15)
        }

        // Primary (60%+) = 赤系、Secondary (<60%) = オレンジ系
        if stimulation >= primaryThreshold {
            return Color.mmMuscleJustWorked.opacity(0.8)
        } else {
            return Color.mmMuscleAmber.opacity(0.7)
        }
    }
}

// MARK: - 情報チップ

private struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.mmBgCard)
        .foregroundStyle(Color.mmTextSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - 筋肉チップ

private struct MuscleChip: View {
    let muscle: Muscle
    let percentage: Int
    let isPrimary: Bool
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack(spacing: 4) {
            Text(localization.currentLanguage == .japanese ? muscle.japaneseName : muscle.englishName)
            Text("\(percentage)%")
                .fontWeight(.bold)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isPrimary ? Color.mmMuscleJustWorked.opacity(0.15) : Color.mmMuscleAmber.opacity(0.15))
        .foregroundStyle(isPrimary ? Color.mmMuscleJustWorked : Color.mmMuscleAmber)
        .clipShape(Capsule())
    }
}

// MARK: - String Extension

private extension String {
    func toSnakeCase() -> String {
        var result = ""
        for (index, char) in self.enumerated() {
            if char.isUppercase {
                if index > 0 {
                    result += "_"
                }
                result += char.lowercased()
            } else {
                result += String(char)
            }
        }
        return result
    }
}

// MARK: - Preview

#Preview {
    ExercisePreviewSheet(
        exercise: ExerciseDefinition(
            id: "barbell_bench_press",
            nameEN: "Barbell Bench Press",
            nameJA: "バーベルベンチプレス",
            category: "胸",
            equipment: "バーベル",
            difficulty: "中級",
            muscleMapping: [
                "chest_upper": 65,
                "chest_lower": 100,
                "deltoid_anterior": 50,
                "triceps": 40
            ]
        ),
        onAddExercise: {}
    )
}
