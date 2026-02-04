import SwiftUI

// MARK: - ワークアウト完了画面

struct WorkoutCompletionView: View {
    let session: WorkoutSession
    let onDismiss: () -> Void

    @State private var showingShareSheet = false
    @State private var renderedImage: UIImage?

    private var localization: LocalizationManager { LocalizationManager.shared }

    // MARK: - 統計計算

    private var totalVolume: Double {
        session.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
    }

    private var totalSets: Int {
        session.sets.count
    }

    private var uniqueExercises: Int {
        Set(session.sets.map(\.exerciseId)).count
    }

    private var duration: String {
        guard let end = session.endDate else { return "--" }
        let interval = end.timeIntervalSince(session.startDate)
        let minutes = Int(interval / 60)
        return L10n.minutes(minutes)
    }

    /// 実施した種目リスト（重複除去、順番保持）
    private var exercisesDone: [ExerciseDefinition] {
        var seen = Set<String>()
        var result: [ExerciseDefinition] = []
        for set in session.sets {
            if !seen.contains(set.exerciseId),
               let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) {
                seen.insert(set.exerciseId)
                result.append(exercise)
            }
        }
        return result
    }

    /// 刺激した筋肉のマッピング（筋肉ID → 最大刺激度%）
    private var stimulatedMuscleMapping: [String: Int] {
        var muscleIntensity: [String: Int] = [:]

        for set in session.sets {
            guard let exercise = ExerciseStore.shared.exercise(for: set.exerciseId) else { continue }
            for (muscleId, percentage) in exercise.muscleMapping {
                muscleIntensity[muscleId] = max(muscleIntensity[muscleId] ?? 0, percentage)
            }
        }

        return muscleIntensity
    }

    private func setsCount(for exerciseId: String) -> Int {
        session.sets.filter { $0.exerciseId == exerciseId }.count
    }

    /// 種目名リスト（シェア用）
    private var exerciseNames: [String] {
        exercisesDone.map { localization.currentLanguage == .japanese ? $0.nameJA : $0.nameEN }
    }

    var body: some View {
        ZStack {
            Color.mmBgPrimary.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // 完了アイコン
                completionIcon

                // タイトル
                Text(L10n.workoutComplete)
                    .font(.title.bold())
                    .foregroundStyle(Color.mmTextPrimary)

                // 統計カード
                statsCard

                // 刺激した筋肉
                stimulatedMusclesSection

                // 種目リスト（セット数付き）
                exerciseList

                Spacer()

                // ボタン
                buttonSection
            }
            .padding()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - 完了アイコン

    private var completionIcon: some View {
        ZStack {
            Circle()
                .fill(Color.mmAccentPrimary.opacity(0.2))
                .frame(width: 100, height: 100)

            Circle()
                .fill(Color.mmAccentPrimary.opacity(0.4))
                .frame(width: 80, height: 80)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.mmAccentPrimary)
        }
    }

    // MARK: - 統計カード

    private var statsCard: some View {
        HStack(spacing: 0) {
            StatBox(value: formatVolume(totalVolume), label: L10n.totalVolume, icon: "scalemass")
            StatBox(value: "\(uniqueExercises)", label: L10n.exercises, icon: "figure.strengthtraining.traditional")
            StatBox(value: "\(totalSets)", label: L10n.sets, icon: "number")
            StatBox(value: duration, label: L10n.time, icon: "clock")
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 刺激した筋肉セクション

    private var stimulatedMusclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.stimulatedMuscles)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            HStack(spacing: 16) {
                // 前面
                MiniMuscleMapView(
                    muscleMapping: stimulatedMuscleMapping,
                    showFront: true
                )
                .frame(height: 160)

                // 背面
                MiniMuscleMapView(
                    muscleMapping: stimulatedMuscleMapping,
                    showFront: false
                )
                .frame(height: 160)
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 種目リスト

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.exercisesDone)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            ForEach(exercisesDone) { exercise in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                    Spacer()
                    Text(L10n.setsLabel(setsCount(for: exercise.id)))
                        .font(.caption.monospaced())
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
        .padding()
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - ボタンセクション

    private var buttonSection: some View {
        VStack(spacing: 12) {
            // シェアボタン
            Button {
                renderAndShare()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.share)
                }
                .font(.headline)
                .foregroundStyle(Color.mmBgPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.mmAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 閉じるボタン
            Button {
                onDismiss()
            } label: {
                Text(L10n.close)
                    .font(.headline)
                    .foregroundStyle(Color.mmTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }

    // MARK: - シェア用画像生成

    @MainActor
    private func renderAndShare() {
        let shareView = WorkoutShareCard(
            totalVolume: totalVolume,
            totalSets: totalSets,
            exerciseCount: uniqueExercises,
            duration: duration,
            exerciseNames: exerciseNames,
            date: session.startDate
        )

        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            renderedImage = image
            showingShareSheet = true
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - 統計ボックス

private struct StatBox: View {
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

private struct WorkoutShareCard: View {
    let totalVolume: Double
    let totalSets: Int
    let exerciseCount: Int
    let duration: String
    let exerciseNames: [String]
    let date: Date

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MuscleMap")
                        .font(.title2.bold())
                        .foregroundStyle(Color.mmAccentPrimary)
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(Color.mmTextSecondary)
                }
                Spacer()
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title)
                    .foregroundStyle(Color.mmAccentPrimary)
            }

            // 統計
            HStack(spacing: 16) {
                ShareStatItem(value: formatVolume(totalVolume), label: "Volume")
                ShareStatItem(value: "\(exerciseCount)", label: "Exercises")
                ShareStatItem(value: "\(totalSets)", label: "Sets")
                ShareStatItem(value: duration, label: "Time")
            }

            // 種目リスト
            VStack(alignment: .leading, spacing: 6) {
                ForEach(exerciseNames.prefix(5), id: \.self) { name in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.mmAccentPrimary)
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(Color.mmTextPrimary)
                        Spacer()
                    }
                }
                if exerciseNames.count > 5 {
                    Text("+\(exerciseNames.count - 5) more")
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }
            }
        }
        .padding(24)
        .frame(width: 350)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
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

// MARK: - シェアシート

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    let session = WorkoutSession()
    session.endDate = Date()

    return WorkoutCompletionView(session: session) {
        print("Dismissed")
    }
}
