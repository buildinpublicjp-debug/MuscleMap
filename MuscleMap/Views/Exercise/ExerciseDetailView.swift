import SwiftUI

// MARK: - 種目詳細ビュー

struct ExerciseDetailView: View {
    let exercise: ExerciseDefinition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // ヘッダー
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.nameJA)
                                .font(.title2.bold())
                                .foregroundStyle(Color.mmTextPrimary)

                            Text(exercise.nameEN)
                                .font(.subheadline)
                                .foregroundStyle(Color.mmTextSecondary)
                        }

                        // 基本情報
                        HStack(spacing: 16) {
                            InfoTag(icon: "dumbbell", text: exercise.equipment)
                            InfoTag(icon: "chart.bar", text: exercise.difficulty)
                            InfoTag(icon: "tag", text: exercise.category)
                        }

                        // 筋肉マップ
                        VStack(alignment: .leading, spacing: 12) {
                            Text("対象筋肉")
                                .font(.headline)
                                .foregroundStyle(Color.mmTextPrimary)

                            ExerciseMuscleMapView(muscleMapping: exercise.muscleMapping)
                                .frame(height: 320)
                                .background(Color.mmBgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // ターゲット筋肉（リスト）
                        VStack(alignment: .leading, spacing: 12) {
                            Text("刺激度")
                                .font(.headline)
                                .foregroundStyle(Color.mmTextPrimary)

                            // 刺激度%順にソート
                            let sorted = exercise.muscleMapping
                                .sorted { $0.value > $1.value }

                            ForEach(sorted, id: \.key) { muscleId, percentage in
                                if let muscle = Muscle(rawValue: muscleId) ?? Muscle(snakeCase: muscleId) {
                                    MuscleStimulationBar(
                                        muscle: muscle,
                                        percentage: percentage
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(exercise.nameJA)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - 情報タグ

private struct InfoTag: View {
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

// MARK: - 刺激度バー

private struct MuscleStimulationBar: View {
    let muscle: Muscle
    let percentage: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(muscle.japaneseName)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextPrimary)
                .frame(width: 100, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.mmBgCard)
                        .frame(height: 8)

                    // バー
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(percentage) / 100, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(percentage)%")
                .font(.caption.monospaced())
                .foregroundStyle(Color.mmTextSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var barColor: Color {
        switch percentage {
        case 80...: return .mmMuscleJustWorked
        case 50..<80: return .mmMuscleAmber
        default: return .mmMuscleLime
        }
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
