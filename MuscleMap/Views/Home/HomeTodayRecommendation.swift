import SwiftUI

// MARK: - 今日のおすすめボタン

struct TodayRecommendationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(Color.mmAccentPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.todayRecommendation)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                    Text(L10n.basedOnRecovery)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 今日のおすすめメニュービュー

struct TodayRecommendationView: View {
    let menu: SuggestedMenu
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: ExerciseDefinition?

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 提案理由
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(Color.mmAccentPrimary)
                                Text(L10n.suggestionReason)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmTextPrimary)
                            }
                            Text(menu.reason)
                                .font(.body)
                                .foregroundStyle(Color.mmTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.mmBgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // 種目リスト
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.suggestedExercises)
                                .font(.headline)
                                .foregroundStyle(Color.mmTextPrimary)

                            ForEach(menu.exercises) { exercise in
                                SuggestedExerciseRow(
                                    exercise: exercise,
                                    onTap: {
                                        selectedExercise = exercise.definition
                                    }
                                )
                            }

                            if menu.exercises.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 40))
                                        .foregroundStyle(Color.mmTextSecondary)
                                    Text(L10n.letsStartTraining)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.mmTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            }
                        }

                        // 開始ボタン
                        Button {
                            HapticManager.lightTap()
                            AppState.shared.selectedTab = 1
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text(L10n.startWorkout)
                            }
                            .font(.headline)
                            .foregroundStyle(Color.mmBgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.mmAccentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.todayRecommendation)
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
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 提案種目行

struct SuggestedExerciseRow: View {
    let exercise: SuggestedExercise
    let onTap: () -> Void

    private var localization: LocalizationManager { LocalizationManager.shared }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 筋肉マップ（どこに効くかを視覚的に表示）
                ZStack(alignment: .topTrailing) {
                    MiniMuscleMapView(muscleMapping: exercise.definition.muscleMapping)
                        .frame(width: 40, height: 52)

                    // 未刺激警告バッジ
                    if exercise.isNeglectedFix {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.mmMuscleNeglected)
                            .offset(x: 4, y: -4)
                    }
                }

                // 種目情報
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(localization.currentLanguage == .japanese ? exercise.definition.nameJA : exercise.definition.nameEN)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.mmTextPrimary)

                        if exercise.isNeglectedFix {
                            Text(L10n.neglected)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mmMuscleNeglected.opacity(0.2))
                                .foregroundStyle(Color.mmMuscleNeglected)
                                .clipShape(Capsule())
                        }
                    }
                    Text(L10n.setsReps(exercise.suggestedSets, exercise.suggestedReps))
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.mmTextSecondary)
            }
            .padding()
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
