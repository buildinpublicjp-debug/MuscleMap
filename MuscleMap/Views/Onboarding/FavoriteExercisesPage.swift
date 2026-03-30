import SwiftUI

// MARK: - オンボーディング: やりたい種目選択ページ

/// GoalMusclePreviewPageの後、WeightInputPageの前に配置
/// 目標の重点筋肉に関連する種目を優先表示し、お気に入りに登録する
struct FavoriteExercisesPage: View {
    let onNext: () -> Void

    @State private var selectedIds: Set<String> = []
    @State private var searchText = ""
    @State private var headerAppeared = false

    /// 選択上限
    private let maxSelection = 10

    /// 目標の重点筋肉
    private var priorityMuscles: [Muscle] {
        guard let raw = AppState.shared.primaryOnboardingGoal,
              let goal = OnboardingGoal(rawValue: raw) else { return [] }
        return GoalMusclePriority.data(for: goal).muscles
    }

    /// 重点筋肉に関連する種目（上位表示用）
    private var priorityExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        store.loadIfNeeded()
        var seen: Set<String> = []
        var result: [ExerciseDefinition] = []
        for muscle in priorityMuscles {
            for ex in store.exercises(targeting: muscle) {
                if !seen.contains(ex.id) {
                    seen.insert(ex.id)
                    result.append(ex)
                }
            }
        }
        return result
    }

    /// それ以外の種目
    private var otherExercises: [ExerciseDefinition] {
        let store = ExerciseStore.shared
        let priorityIds = Set(priorityExercises.map { $0.id })
        return store.exercises.filter { !priorityIds.contains($0.id) }
    }

    /// 検索フィルター適用済みの全種目リスト（重点→その他の順）
    private var filteredExercises: [ExerciseDefinition] {
        let all = priorityExercises + otherExercises
        if searchText.isEmpty { return all }
        let query = searchText.lowercased()
        return all.filter {
            $0.localizedName.lowercased().contains(query) ||
            $0.nameEN.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            // ヘッダー
            VStack(spacing: 8) {
                Text(L10n.favoriteExercisesTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.favoriteExercisesSub)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : 20)

            Spacer().frame(height: 16)

            // 検索バー
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.mmOnboardingTextSub)
                TextField("", text: $searchText, prompt: Text(L10n.searchExercises).foregroundColor(Color.mmOnboardingTextSub))
                    .foregroundStyle(Color.mmOnboardingTextMain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }
                }
            }
            .padding(12)
            .background(Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)

            Spacer().frame(height: 8)

            // 選択カウンター
            if !selectedIds.isEmpty {
                Text(L10n.exerciseSelectedCount(selectedIds.count))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingAccent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                    .transition(.opacity)
            }

            // 種目リスト
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(filteredExercises) { exercise in
                        ExerciseSelectRow(
                            exercise: exercise,
                            isSelected: selectedIds.contains(exercise.id),
                            onTap: {
                                toggleSelection(exercise.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }

            Spacer(minLength: 0)

            // ボタンエリア
            VStack(spacing: 12) {
                // スキップ
                Button {
                    HapticManager.lightTap()
                    onNext()
                } label: {
                    Text(L10n.skip)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)

                // 次へボタン
                Button {
                    saveAndProceed()
                } label: {
                    Text(L10n.next)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(selectedIds.isEmpty ? Color.mmOnboardingTextSub : Color.mmOnboardingBg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedIds.isEmpty ? Color.mmOnboardingCard : Color.mmOnboardingAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .disabled(selectedIds.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: selectedIds.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                headerAppeared = true
            }
        }
    }

    // MARK: - ロジック

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else if selectedIds.count < maxSelection {
            selectedIds.insert(id)
        }
        HapticManager.lightTap()
    }

    private func saveAndProceed() {
        // 選択した種目をお気に入りに登録
        for id in selectedIds {
            FavoritesManager.shared.add(id)
        }
        HapticManager.lightTap()
        onNext()
    }
}

// MARK: - 種目選択行

private struct ExerciseSelectRow: View {
    let exercise: ExerciseDefinition
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // 左アクセントバー
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.mmOnboardingAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 8)

                HStack(spacing: 12) {
                    // GIFサムネイル
                    exerciseThumbnail

                    // 種目名 + 器具バッジ
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.localizedName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.mmOnboardingTextMain)
                            .lineLimit(1)

                        Text(exercise.localizedEquipment)
                            .font(.caption)
                            .foregroundStyle(Color.mmOnboardingTextSub)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.mmOnboardingCard)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Spacer()

                    // チェックマーク
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(Color.mmOnboardingAccent)
                                .frame(width: 24, height: 24)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.mmOnboardingBg)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(minHeight: 56)
            .background(isSelected ? Color.mmOnboardingAccent.opacity(0.06) : Color.mmOnboardingCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }

    // MARK: - サムネイル

    @ViewBuilder
    private var exerciseThumbnail: some View {
        if ExerciseGifView.hasGif(exerciseId: exercise.id) {
            ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.mmOnboardingBg)
                    .frame(width: 40, height: 40)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.4))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        FavoriteExercisesPage(onNext: {})
    }
}
