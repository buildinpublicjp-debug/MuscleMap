import SwiftUI

// MARK: - 種目辞典タブ（筋肉マップ + 全種目GIF付きリスト）

struct ExerciseDictionaryView: View {
    @State private var selectedMuscle: Muscle?
    @State private var searchText = ""
    @State private var muscleStates: [Muscle: MuscleVisualState] = [:]

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    /// 全種目（検索フィルタ付き）
    private var filteredExercises: [ExerciseDefinition] {
        let all = ExerciseStore.shared.exercises
        if searchText.isEmpty { return all }
        return all.filter {
            $0.localizedName.localizedCaseInsensitiveContains(searchText) ||
            $0.localizedEquipment.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 筋肉マップ（タップ可能）
                    MuscleMapView(
                        muscleStates: muscleStates,
                        onMuscleTapped: { muscle in
                            selectedMuscle = muscle
                            HapticManager.lightTap()
                        }
                    )
                    .frame(height: 200)
                    .padding(.horizontal, 16)

                    // ヒント
                    if selectedMuscle == nil {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap")
                                .font(.caption)
                            Text(isJapanese ? "筋肉をタップして種目を見る" : "Tap a muscle to see exercises")
                                .font(.caption)
                        }
                        .foregroundStyle(Color.mmTextSecondary)
                    }

                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.mmTextSecondary)
                        TextField(
                            isJapanese ? "種目を検索" : "Search exercises",
                            text: $searchText
                        )
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextPrimary)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.mmBgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                    // 種目数ヘッダー
                    HStack {
                        Text(isJapanese
                            ? "すべての種目（\(filteredExercises.count)種目）"
                            : "All Exercises (\(filteredExercises.count))")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    // 種目リスト
                    LazyVStack(spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            ExerciseDictionaryRow(exercise: exercise)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
            }
            .background(Color.mmBgPrimary)
            .navigationTitle(isJapanese ? "種目辞典" : "Exercise Dictionary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            ExerciseStore.shared.loadIfNeeded()
            if muscleStates.isEmpty {
                for muscle in Muscle.allCases {
                    muscleStates[muscle] = .inactive
                }
            }
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleExerciseDictionarySheet(muscle: muscle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - 種目行

private struct ExerciseDictionaryRow: View {
    let exercise: ExerciseDefinition

    var body: some View {
        HStack(spacing: 12) {
            // GIFサムネイル 80x80
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mmBgSecondary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "dumbbell")
                            .font(.title2)
                            .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.localizedName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(1)

                Text(exercise.localizedEquipment)
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)

                // 筋肉チップ（最大3つ）
                HStack(spacing: 4) {
                    ForEach(
                        Array(exercise.muscleMapping.keys.sorted().prefix(3)),
                        id: \.self
                    ) { muscleId in
                        if let muscle = Muscle(rawValue: muscleId) {
                            Text(muscle.localizedName)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mmAccentPrimary.opacity(0.15))
                                .clipShape(Capsule())
                                .foregroundStyle(Color.mmAccentPrimary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(12)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 筋肉タップ → 種目シート

private struct MuscleExerciseDictionarySheet: View {
    let muscle: Muscle
    @Environment(\.dismiss) private var dismiss

    private var isJapanese: Bool {
        LocalizationManager.shared.currentLanguage == .japanese
    }

    private var exercises: [ExerciseDefinition] {
        ExerciseStore.shared.exercises(targeting: muscle)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(exercises) { exercise in
                        HStack(spacing: 12) {
                            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            } else {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.mmBgSecondary)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "dumbbell")
                                            .font(.title2)
                                            .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.localizedName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                Text(exercise.localizedEquipment)
                                    .font(.caption)
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(16)
            }
            .background(Color.mmBgPrimary)
            .navigationTitle(isJapanese
                ? "\(muscle.japaneseName) — \(exercises.count)種目"
                : "\(muscle.englishName) — \(exercises.count) exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
    }
}

#Preview {
    ExerciseDictionaryView()
}
