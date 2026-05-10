import SwiftUI
import SwiftData

// MARK: - 種目詳細ビュー

struct ExerciseDetailView: View {
    let exercise: ExerciseDefinition
    var hideStartWorkoutButton: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var favorites = FavoritesManager.shared

    private var prWeight: Double? {
        PRManager.shared.getWeightPR(exerciseId: exercise.id, context: modelContext)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // 1. ヒーロー GIF アニメーション (フル幅 300px) — 現状維持
                        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                            ExerciseGifView(exerciseId: exercise.id, size: .fullWidth)
                        }

                        // 2. 「過去のあなた」セクション (履歴 0件は非表示、3+件で e1RM トレンドグラフ)
                        ExerciseHistorySection(exerciseId: exercise.id)

                        // 3. YouTube 独立行ボタン
                        YouTubeFormButton(exercise: exercise)

                        // 4. タグ行 (器具/難易度/カテゴリ + PR、YouTube削除)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                DetailInfoTag(icon: "dumbbell", text: exercise.localizedEquipment)
                                DetailInfoTag(icon: "chart.bar", text: exercise.localizedDifficulty)
                                DetailInfoTag(icon: "tag", text: exercise.localizedCategory)
                                if let pr = prWeight {
                                    DetailInfoTag(icon: "trophy.fill", text: String(format: "%.1f kg", pr), highlight: true)
                                }
                            }
                        }

                        // 5. 「対象筋肉」セクション (マップ + 刺激度バー、現状維持)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.targetMuscles)
                                .font(.headline)
                                .foregroundStyle(Color.mmTextPrimary)

                            ExerciseMuscleMapView(muscleMapping: exercise.muscleMapping)
                                .padding(.vertical, 8)
                                .background(Color.mmBgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            let sorted = exercise.muscleMapping
                                .sorted { $0.value > $1.value }

                            ForEach(sorted, id: \.key) { muscleId, percentage in
                                if let muscle = Muscle(rawValue: muscleId) ?? Muscle(snakeCase: muscleId) {
                                    DetailMuscleStimulationBar(
                                        muscle: muscle,
                                        percentage: percentage
                                    )
                                }
                            }
                        }

                        // 6. この種目でワークアウト開始 (UX フロー維持のため保持、オンボーディング中は非表示)
                        if !hideStartWorkoutButton {
                            Button {
                                AppState.shared.pendingExerciseId = exercise.id
                                AppState.shared.selectedTab = 1
                                HapticManager.lightTap()
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                    Text(L10n.startWorkoutWithExercise)
                                }
                                .font(.headline)
                                .foregroundStyle(Color.mmBgPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.mmAccentPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // ハートアイコンでお気に入り切替
                    Button {
                        favorites.toggle(exercise.id)
                        HapticManager.lightTap()
                    } label: {
                        Image(systemName: favorites.isFavorite(exercise.id) ? "heart.fill" : "heart")
                            .foregroundStyle(favorites.isFavorite(exercise.id) ? Color.mmDestructive : Color.mmTextSecondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(exercise.localizedName)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.mmTextSecondary)
                            .contentShape(Rectangle())
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Muscle Extension for snake_case support

extension Muscle {
    init?(snakeCase: String) {
        // snake_case → camelCase
        let parts = snakeCase.split(separator: "_")
        guard !parts.isEmpty else { return nil }

        let camelCase = parts.enumerated().map { index, part in
            index == 0 ? String(part) : part.capitalized
        }.joined()

        self.init(rawValue: camelCase)
    }
}

#Preview {
    ExerciseDetailView(exercise: ExerciseDefinition(
        id: "bench_press",
        nameEN: "Barbell Bench Press",
        nameJA: "ベンチプレス",
        nameZH: "杠铃卧推",
        nameKO: "바벨 벤치프레스",
        nameES: "Press de banca con barra",
        nameFR: "Développé couché barre",
        nameDE: "Langhantel-Bankdrücken",
        category: "胸",
        equipment: "バーベル",
        difficulty: "中級",
        muscleMapping: [
            "chest_upper": 65,
            "chest_lower": 100,
            "deltoid_anterior": 50,
            "triceps": 40
        ]
    ))
}
