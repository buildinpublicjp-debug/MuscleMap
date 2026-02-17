import SwiftUI
import SwiftData

// MARK: - セッション未開始時のコンポーネント

/// ワークアウト未開始時のメインビュー
struct WorkoutIdleView: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let onStart: () -> Void
    let onSelectExercise: (ExerciseDefinition) -> Void

    @ObservedObject private var favorites = FavoritesManager.shared
    @State private var selectedMuscle: Muscle?
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var favoriteExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        return favorites.favoriteIds.compactMap { store.exercise(for: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 筋肉マップ（タップで種目選択）
                    MuscleMapView(
                        muscleStates: muscleStates,
                        onMuscleTapped: { muscle in
                            selectedMuscle = muscle
                        }
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.55)
                    .padding(.horizontal)

                    // ヒントテキスト
                    Text(L10n.tapMuscleHint)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .multilineTextAlignment(.center)

                    // お気に入り種目
                    if !favoriteExercises.isEmpty {
                        FavoriteExercisesSection(
                            exercises: favoriteExercises,
                            onSelect: onSelectExercise
                        )
                    }
                }
                .padding(.vertical)
            }

            // 開始ボタン（固定）
            Button(action: onStart) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text(L10n.startFreeWorkout)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleExercisePickerSheet(muscle: muscle) { exercise in
                onSelectExercise(exercise)
                selectedMuscle = nil
            }
        }
    }
}

// MARK: - お気に入り種目セクション

struct FavoriteExercisesSection: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.mmMuscleModerate)
                Text(L10n.favoriteExercises)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        Button {
                            onSelect(exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)

                                HStack(spacing: 4) {
                                    Image(systemName: "dumbbell")
                                    Text(exercise.localizedEquipment)
                                }
                                .font(.caption2)
                                .foregroundStyle(Color.mmTextSecondary)

                                if let primary = exercise.primaryMuscle {
                                    Text(primary.localizedName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.mmAccentPrimary.opacity(0.15))
                                        .foregroundStyle(Color.mmAccentPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(width: 140, alignment: .leading)
                            .padding(12)
                            .background(Color.mmBgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 筋肉タップ時の種目選択シート

struct MuscleExercisePickerSheet: View {
    let muscle: Muscle
    let onSelect: (ExerciseDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var relatedExercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    private func lastRecord(for exerciseId: String) -> WorkoutSet? {
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                if relatedExercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.5))
                        Text(L10n.noData)
                            .font(.headline)
                            .foregroundStyle(Color.mmTextSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(relatedExercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // GIF - カード型で大きく
                                        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                            ExerciseGifView(exerciseId: exercise.id, size: .card)
                                        } else {
                                            MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                                                .frame(height: 120)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.mmBgSecondary)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }

                                        // 種目名 + 器具 + 前回記録
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(Color.mmTextPrimary)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                                Text(exercise.localizedEquipment)
                                                    .font(.caption)
                                                    .foregroundStyle(Color.mmTextSecondary)
                                            }
                                            Spacer()
                                            if let record = lastRecord(for: exercise.id) {
                                                Text(L10n.lastRecordLabel(record.weight, record.reps))
                                                    .font(.caption.monospaced().bold())
                                                    .foregroundStyle(Color.mmAccentPrimary)
                                            }
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(Color.mmTextSecondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color.mmBgCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(muscle.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
