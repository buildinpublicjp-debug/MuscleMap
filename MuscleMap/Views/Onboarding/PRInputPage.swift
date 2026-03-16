import SwiftUI

// MARK: - PR入力用の種目エントリ

/// PR入力リストの1行分のデータ
private struct PREntry: Identifiable {
    let id: UUID = UUID()
    var exerciseId: String
    var text: String = ""
}

// MARK: - PR入力画面（種目追加・変更可能）

struct PRInputPage: View {
    let onNext: () -> Void

    /// BIG3のデフォルトID
    private static let defaultExerciseIds = [
        "barbell_bench_press",
        "barbell_back_squat",
        "deadlift",
    ]

    /// 最大種目数
    private static let maxEntries = 6

    @State private var entries: [PREntry] = defaultExerciseIds.map {
        PREntry(exerciseId: $0)
    }
    @State private var appeared = false
    @State private var isProceeding = false

    /// 種目検索シート
    @State private var showExercisePicker = false
    /// 差し替え対象のエントリID（nilなら新規追加）
    @State private var replacingEntryId: UUID?

    /// デフォルト体重（体重未入力時の暫定値）
    private var bodyweightKg: Double {
        let weight = AppState.shared.userProfile.weightKg
        return weight > 0 ? weight : 70.0
    }

    /// 総合レベルの算出
    private var overallLevel: StrengthLevel? {
        let values = entries.compactMap { entry -> (String, Double)? in
            guard let weight = Double(entry.text), weight > 0 else { return nil }
            return (entry.exerciseId, weight)
        }
        guard !values.isEmpty else { return nil }

        var totalScore = 0.0
        for (exerciseId, estimated1RM) in values {
            let result = StrengthScoreCalculator.exerciseStrengthLevel(
                exerciseId: exerciseId,
                estimated1RM: estimated1RM,
                bodyweightKg: bodyweightKg
            )
            totalScore += result.level.minimumScore
        }
        let avgScore = totalScore / Double(values.count)
        return StrengthScoreCalculator.level(score: avgScore)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // タイトルエリア
            VStack(spacing: 8) {
                Text(L10n.prInputTitle)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .multilineTextAlignment(.center)

                Text(L10n.prInputSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.mmOnboardingTextSub)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 32)

            // 種目入力リスト
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach($entries) { $entry in
                        PREntryRow(
                            entry: $entry,
                            bodyweightKg: bodyweightKg,
                            onTapName: {
                                replacingEntryId = entry.id
                                showExercisePicker = true
                            }
                        )
                    }

                    // 種目追加ボタン
                    if entries.count < Self.maxEntries {
                        Button {
                            replacingEntryId = nil
                            showExercisePicker = true
                            HapticManager.lightTap()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text(L10n.addExercise)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(Color.mmOnboardingAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.mmOnboardingAccent.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer().frame(height: 16)

            // 総合レベル表示
            if let level = overallLevel {
                VStack(spacing: 8) {
                    Text(L10n.prOverallLevel)
                        .font(.subheadline)
                        .foregroundStyle(Color.mmOnboardingTextSub)

                    HStack(spacing: 8) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(level.color)
                        Text(level.localizedName)
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundStyle(level.color)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: overallLevel?.rawValue)
            }

            Spacer()

            // スキップ + 次へボタン
            VStack(spacing: 12) {
                // スキップテキストリンク
                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    HapticManager.lightTap()
                    onNext()
                } label: {
                    Text(L10n.skip)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .buttonStyle(.plain)

                // 次へボタン
                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    savePRs()
                    HapticManager.lightTap()
                    onNext()
                } label: {
                    Text(L10n.next)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.mmOnboardingBg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.mmOnboardingAccent, .mmOnboardingAccentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerSheet(
                existingIds: Set(entries.map(\.exerciseId)),
                onSelect: { exercise in
                    if let replaceId = replacingEntryId,
                       let index = entries.firstIndex(where: { $0.id == replaceId }) {
                        // 差し替え
                        entries[index].exerciseId = exercise.id
                        entries[index].text = ""
                    } else {
                        // 新規追加
                        let newEntry = PREntry(exerciseId: exercise.id)
                        withAnimation(.easeOut(duration: 0.3)) {
                            entries.append(newEntry)
                        }
                    }
                    HapticManager.lightTap()
                    showExercisePicker = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Private

    /// PR入力値をUserProfileに保存
    private func savePRs() {
        var prs: [String: Double] = [:]
        for entry in entries {
            if let weight = Double(entry.text), weight > 0 {
                prs[entry.exerciseId] = weight
            }
        }
        AppState.shared.userProfile.initialPRs = prs
    }
}

// MARK: - PR入力行（種目名タップで変更可能 + レベルバッジ）

private struct PREntryRow: View {
    @Binding var entry: PREntry
    let bodyweightKg: Double
    let onTapName: () -> Void

    /// 種目名（ExerciseStoreから解決）
    private var exerciseName: String {
        ExerciseStore.shared.loadIfNeeded()
        return ExerciseStore.shared.exerciseName(for: entry.exerciseId)
            ?? entry.exerciseId
    }

    /// 入力値に対応するレベル
    private var currentLevel: StrengthLevel? {
        guard let weight = Double(entry.text), weight > 0 else { return nil }
        let result = StrengthScoreCalculator.exerciseStrengthLevel(
            exerciseId: entry.exerciseId,
            estimated1RM: weight,
            bodyweightKg: bodyweightKg
        )
        return result.level
    }

    var body: some View {
        HStack(spacing: 12) {
            // 種目名（タップで変更）
            Button(action: onTapName) {
                HStack(spacing: 4) {
                    Text(exerciseName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // 入力フィールド + kg
            HStack(spacing: 4) {
                TextField("0", text: $entry.text)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                    .keyboardType(.numberPad)
                    .frame(width: 64)
                    .multilineTextAlignment(.center)
                    .onChange(of: entry.text) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue { entry.text = filtered }
                    }

                Text("kg")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.mmOnboardingBg.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // レベルバッジ
            if let level = currentLevel {
                Text(level.localizedName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.mmOnboardingAccent)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: level.rawValue)
            }
        }
        .padding(14)
        .background(Color.mmOnboardingCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 種目検索シート（ExerciseLibraryの簡易版）

private struct ExercisePickerSheet: View {
    let existingIds: Set<String>
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    /// フィルタ済み種目リスト
    private var filteredExercises: [ExerciseDefinition] {
        ExerciseStore.shared.loadIfNeeded()
        let all = ExerciseStore.shared.exercises
        if searchText.isEmpty {
            return all
        }
        let query = searchText.lowercased()
        return all.filter {
            $0.nameJA.lowercased().contains(query)
            || $0.nameEN.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredExercises) { exercise in
                    Button {
                        onSelect(exercise)
                    } label: {
                        HStack(spacing: 12) {
                            // 種目アイコン（カテゴリ別）
                            Image(systemName: categoryIcon(for: exercise.category))
                                .font(.system(size: 16))
                                .foregroundStyle(Color.mmOnboardingAccent)
                                .frame(width: 32, height: 32)
                                .background(Color.mmOnboardingAccent.opacity(0.12))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.nameJA)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.mmOnboardingTextMain)
                                Text(exercise.localizedEquipment)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.mmOnboardingTextSub)
                            }

                            Spacer()

                            // 既に追加済みマーク
                            if existingIds.contains(exercise.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.mmOnboardingAccent)
                            }
                        }
                    }
                    .listRowBackground(Color.mmOnboardingCard)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.mmOnboardingBg)
            .searchable(text: $searchText, prompt: L10n.searchExercises)
            .navigationTitle(L10n.addExercise)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }
                }
            }
        }
    }

    /// カテゴリ別SFシンボル
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "chest": return "figure.strengthtraining.traditional"
        case "back": return "figure.rowing"
        case "shoulders": return "figure.arms.open"
        case "arms": return "dumbbell.fill"
        case "legs": return "figure.run"
        case "core": return "figure.core.training"
        default: return "figure.mixed.cardio"
        }
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        PRInputPage(onNext: {})
    }
}
