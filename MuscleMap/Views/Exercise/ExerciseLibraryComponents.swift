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
                    HStack(spacing: 8) {
                        ForEach(favoriteExercises) { exercise in
                            Button {
                                HapticManager.lightTap()
                                onSelect(exercise)
                            } label: {
                                HStack(spacing: 6) {
                                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                                        ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                                            .frame(width: 32, height: 32)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    } else {
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .font(.caption)
                                            .foregroundStyle(Color.mmAccentPrimary)
                                            .frame(width: 32, height: 32)
                                            .background(Color.mmBgCard)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }

                                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.mmTextPrimary)
                                        .lineLimit(1)
                                }
                                .padding(.trailing, 8)
                                .background(Color.mmBgSecondary)
                                .clipShape(Capsule())
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
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // GIF or ミニマップ（上部120px）
                ZStack(alignment: .topTrailing) {
                    if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                        ExerciseGifView(exerciseId: exercise.id, size: .previewCard)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .clipped()
                    } else {
                        MiniMuscleMapView(muscleMapping: exercise.muscleMapping)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.mmBgPrimary.opacity(0.5))
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

                // 種目情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.currentLanguage == .japanese ? exercise.nameJA : exercise.nameEN)
                        .font(.caption.bold())
                        .foregroundStyle(Color.mmTextPrimary)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        if let muscle = primaryMuscle {
                            LibraryPrimaryMuscleTag(
                                muscleName: localization.currentLanguage == .japanese
                                    ? muscle.japaneseName
                                    : muscle.englishName
                            )
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "dumbbell")
                        Text(exercise.localizedEquipment)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.mmTextSecondary)
                    .lineLimit(1)
                }
                .padding(8)
            }
            .background(Color.mmBgSecondary)
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
