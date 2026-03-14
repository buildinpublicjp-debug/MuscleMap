import SwiftUI
import SwiftData

// MARK: - 種目詳細ビュー

struct ExerciseDetailView: View {
    let exercise: ExerciseDefinition
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var favorites = FavoritesManager.shared
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var prWeight: Double? {
        PRManager.shared.getWeightPR(exerciseId: exercise.id, context: modelContext)
    }

    /// 現在の種目の強さレベル情報
    private var strengthLevelInfo: (level: StrengthLevel, kgToNext: Double?, nextLevel: StrengthLevel?)? {
        guard let best1RM = PRManager.shared.getBestEstimated1RM(exerciseId: exercise.id, context: modelContext) else {
            return nil
        }
        let bodyweight = AppState.shared.userProfile.weightKg
        return StrengthScoreCalculator.exerciseStrengthLevel(
            exerciseId: exercise.id,
            estimated1RM: best1RM,
            bodyweightKg: bodyweight
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // GIFアニメーション（トップに配置、存在する場合のみ）
                        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                            ExerciseGifView(exerciseId: exercise.id, size: .fullWidth)
                        }

                        // 基本情報タグ（コンパクトに）
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                InfoTag(icon: "dumbbell", text: exercise.localizedEquipment)
                                InfoTag(icon: "chart.bar", text: exercise.localizedDifficulty)
                                InfoTag(icon: "tag", text: exercise.localizedCategory)
                                if let pr = prWeight {
                                    InfoTag(icon: "trophy.fill", text: String(format: "%.1f kg", pr), highlight: true)
                                }
                            }
                        }

                        // 強さレベルプログレスバー
                        if let info = strengthLevelInfo {
                            StrengthLevelProgressSection(
                                currentLevel: info.level,
                                kgToNext: info.kgToNext,
                                nextLevel: info.nextLevel
                            )
                        }

                        // ターゲット筋肉（マップ + 刺激度バー統合セクション）
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.targetMuscles)
                                .font(.headline)
                                .foregroundStyle(Color.mmTextPrimary)

                            ExerciseMuscleMapView(muscleMapping: exercise.muscleMapping)
                                .padding(.vertical, 8)
                                .background(Color.mmBgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            // 刺激度バー（マップ直下に配置）
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

                        // 動画で見る（YouTubeボタン）
                        Button {
                            HapticManager.lightTap()
                            if let url = YouTubeSearchHelper.searchURL(for: exercise) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(.red)
                                Text(L10n.watchVideo)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.mmTextSecondary)
                            }
                            .padding()
                            .background(Color.mmBgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // この種目でワークアウト開始ボタン
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
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        favorites.toggle(exercise.id)
                        HapticManager.lightTap()
                    } label: {
                        Image(systemName: favorites.isFavorite(exercise.id) ? "star.fill" : "star")
                            .foregroundStyle(favorites.isFavorite(exercise.id) ? Color.mmMuscleModerate : Color.mmTextSecondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                        .font(.headline)
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
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
    var highlight: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(highlight ? .mmPRGold : Color.mmTextSecondary)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.mmBgCard)
        .foregroundStyle(highlight ? .mmPRGold : Color.mmTextSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - 刺激度バー

private struct MuscleStimulationBar: View {
    let muscle: Muscle
    let percentage: Int
    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        HStack(spacing: 12) {
            Text(localization.currentLanguage == .japanese ? muscle.japaneseName : muscle.englishName)
                .font(.subheadline)
                .foregroundStyle(Color.mmTextPrimary)
                .frame(minWidth: 80, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

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
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(barColor)
                .frame(width: 48, alignment: .trailing)
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

// MARK: - 強さレベルプログレスバー

private struct StrengthLevelProgressSection: View {
    let currentLevel: StrengthLevel
    let kgToNext: Double?
    let nextLevel: StrengthLevel?

    private let allLevels = StrengthLevel.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.strengthLevelTitle)
                .font(.headline)
                .foregroundStyle(Color.mmTextPrimary)

            // プログレスバー
            HStack(spacing: 0) {
                ForEach(Array(allLevels.enumerated()), id: \.offset) { index, level in
                    let isCurrent = level == currentLevel
                    let isPassed = level.minimumScore < currentLevel.minimumScore

                    VStack(spacing: 4) {
                        // レベルインジケータ
                        ZStack {
                            Circle()
                                .fill(isCurrent ? level.color : (isPassed ? level.color.opacity(0.4) : Color.mmBgCard))
                                .frame(width: isCurrent ? 28 : 20, height: isCurrent ? 28 : 20)

                            if isCurrent {
                                Circle()
                                    .stroke(level.color, lineWidth: 2)
                                    .frame(width: 34, height: 34)

                                Text(level.emoji)
                                    .font(.system(size: 12))
                            } else if isPassed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.mmBgPrimary)
                            }
                        }
                        .frame(height: 36)

                        // レベル名
                        Text(level.localizedName)
                            .font(.system(size: 9, weight: isCurrent ? .bold : .regular))
                            .foregroundStyle(isCurrent ? level.color : Color.mmTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)

                    // コネクタライン
                    if index < allLevels.count - 1 {
                        Rectangle()
                            .fill(isPassed ? currentLevel.color.opacity(0.4) : Color.mmBgCard)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                            .offset(y: -12)
                    }
                }
            }

            // 次レベルまでのテキスト
            if let kgToNext = kgToNext, let nextLevel = nextLevel {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.caption)
                        .foregroundStyle(nextLevel.color)
                    Text(L10n.levelUpKgToNext(Int(ceil(kgToNext)), nextLevel.localizedName))
                        .font(.caption.bold())
                        .foregroundStyle(nextLevel.color)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(nextLevel.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if currentLevel == .freak {
                HStack(spacing: 4) {
                    Text("👑")
                    Text(L10n.maxLevelReached)
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmPRGold)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color.mmBgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
