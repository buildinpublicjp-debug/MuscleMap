import SwiftUI

// MARK: - お気に入り横スクロール行（Library版）

struct LibraryFavoritesRow: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void
    @ObservedObject private var favorites = FavoritesManager.shared
    private var localization: LocalizationManager { LocalizationManager.shared }

    private var favoriteExercises: [ExerciseDefinition] {
        exercises.filter { favorites.isFavorite($0.id) }
    }

    var body: some View {
        if !favoriteExercises.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.favoritesSection)
                    .font(.caption.bold())
                    .foregroundStyle(Color.mmTextSecondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favoriteExercises) { exercise in
                            let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
                            Button {
                                HapticManager.lightTap()
                                onSelect(exercise)
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    // GIF（元の比率のまま）
                                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                        ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                            .aspectRatio(contentMode: .fit)
                                    } else {
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color.mmTextSecondary.opacity(0.4))
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }

                                    // 下部グラデーション
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.8)],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )

                                    // テキスト
                                    Text(name)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .padding(6)
                                }
                                .frame(width: 110, height: 80)
                                .background(Color.mmBgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - グリッドコンテンツ（Library版）

struct LibraryGridContent: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void

    var body: some View {
        ScrollView {
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(exercises) { exercise in
                    LibraryGridCard(exercise: exercise) {
                        onSelect(exercise)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - グリッドカード（Library版）

private struct LibraryGridCard: View {
    let exercise: ExerciseDefinition
    let onTap: () -> Void
    @ObservedObject private var favorites = FavoritesManager.shared
    private var localization: LocalizationManager { LocalizationManager.shared }

    /// 主要ターゲットの筋肉
    private var primaryMuscle: Muscle? {
        guard let maxEntry = exercise.muscleMapping.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return Muscle(rawValue: maxEntry.key) ?? Muscle(snakeCase: maxEntry.key)
    }

    var body: some View {
        let name = localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN
        let muscleName: String? = {
            guard let m = primaryMuscle else { return nil }
            return localization.currentLanguage == .japanese ? m.japaneseName : m.englishName
        }()

        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    // GIF（AspectFitで全体表示、切れない）
                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                        ExerciseGifView(exerciseId: exercise.id, size: .gridCard)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                    } else {
                        MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    }

                    // 下部グラデーションオーバーレイ
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 60)

                    // テキスト（グラデーションの上）
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        if let muscleName {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.mmAccentPrimary)
                                    .frame(width: 5, height: 5)
                                Text(muscleName)
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color.mmAccentPrimary)
                            }
                        }
                    }
                    .padding(8)
                }

                // お気に入りハートアイコン
                Button {
                    HapticManager.lightTap()
                    favorites.toggle(exercise.id)
                } label: {
                    Image(systemName: favorites.isFavorite(exercise.id) ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundStyle(favorites.isFavorite(exercise.id) ? Color.mmDestructive : Color.mmTextSecondary)
                        .padding(6)
                        .background(Color.mmBgPrimary.opacity(0.7))
                        .clipShape(Circle())
                }
                .padding(6)
            }
            .background(Color.mmBgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - リストコンテンツ（Library版）

struct LibraryListContent: View {
    let exercises: [ExerciseDefinition]
    let onSelect: (ExerciseDefinition) -> Void

    var body: some View {
        List(exercises) { exercise in
            Button {
                HapticManager.lightTap()
                onSelect(exercise)
            } label: {
                ExerciseLibraryRow(exercise: exercise)
            }
            .listRowBackground(Color.mmBgSecondary)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - 種目行（リッチUI、Library版）

struct ExerciseLibraryRow: View {
    let exercise: ExerciseDefinition
    @ObservedObject private var favorites = FavoritesManager.shared
    private var localization: LocalizationManager { LocalizationManager.shared }

    /// 主要ターゲットの筋肉
    private var primaryMuscle: Muscle? {
        guard let maxEntry = exercise.muscleMapping.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return Muscle(rawValue: maxEntry.key) ?? Muscle(snakeCase: maxEntry.key)
    }

    var body: some View {
        HStack(spacing: 12) {
            // GIFサムネイル or ミニ筋肉マップ
            if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
            } else {
                MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                    .frame(width: 100, height: 75)
                    .background(Color.mmBgPrimary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // 種目情報
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.mmTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // 筋肉名 + 器具タグ
                HStack(spacing: 6) {
                    if let muscle = primaryMuscle {
                        LibraryPrimaryMuscleTag(
                            muscleName: localization.currentLanguage == .japanese
                                ? muscle.japaneseName
                                : muscle.englishName
                        )
                    }
                    LibraryExerciseTag(text: exercise.localizedEquipment, icon: "dumbbell")
                }
            }

            Spacer(minLength: 4)

            // お気に入りハートアイコン
            Button {
                HapticManager.lightTap()
                favorites.toggle(exercise.id)
            } label: {
                Image(systemName: favorites.isFavorite(exercise.id) ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundStyle(favorites.isFavorite(exercise.id) ? Color.mmDestructive : Color.mmTextSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.mmTextSecondary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 主要筋肉タグ（Library用）

private struct LibraryPrimaryMuscleTag: View {
    let muscleName: String

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.mmAccentPrimary)
                .frame(width: 6, height: 6)
            Text(muscleName)
                .lineLimit(1)
        }
        .font(.caption2.bold())
        .foregroundStyle(Color.mmAccentPrimary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.mmAccentPrimary.opacity(0.15))
        .clipShape(Capsule())
        .fixedSize()
    }
}

// MARK: - 種目タグ（Library用）

private struct LibraryExerciseTag: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption2)
        .foregroundStyle(Color.mmTextSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.mmBgCard)
        .clipShape(Capsule())
        .fixedSize()
    }
}
