import SwiftUI

// MARK: - PR入力画面（筋肉マップ→種目選択→重量入力）

struct PRInputPage: View {
    let onNext: () -> Void

    /// 入力済みPR（exerciseId: weight）
    @State private var recordedPRs: [String: Double] = [:]
    @State private var appeared = false
    @State private var isProceeding = false

    /// 筋肉タップ → 種目選択シート
    @State private var tappedMuscle: Muscle?

    /// 種目選択 → 重量入力シート
    @State private var selectedExercise: ExerciseDefinition?

    private var localization: LocalizationManager { LocalizationManager.shared }
    private var isJapanese: Bool { localization.currentLanguage == .japanese }

    /// デフォルト体重
    private var bodyweightKg: Double {
        let w = AppState.shared.userProfile.weightKg
        return w > 0 ? w : 70.0
    }

    /// 入力済みPRに対応する筋肉のハイライト
    private var muscleStates: [Muscle: MuscleVisualState] {
        var states: [Muscle: MuscleVisualState] = [:]
        // 入力済み種目がターゲットにする筋肉をグリーンに
        var highlightedMuscles: Set<Muscle> = []
        let store = ExerciseStore.shared
        for exerciseId in recordedPRs.keys {
            if let exercise = store.exercise(for: exerciseId) {
                for (muscleId, _) in exercise.muscleMapping {
                    if let muscle = Muscle(rawValue: muscleId) {
                        highlightedMuscles.insert(muscle)
                    }
                }
            }
        }
        for muscle in Muscle.allCases {
            states[muscle] = highlightedMuscles.contains(muscle) ? .recovering(progress: 0.1) : .inactive
        }
        return states
    }

    /// デフォルト表示するBIG3種目
    private var defaultExercises: [ExerciseDefinition] {
        let ids = ["barbell_bench_press", "barbell_squat", "barbell_deadlift"]
        let store = ExerciseStore.shared
        return ids.compactMap { store.exercise(for: $0) }
    }

    /// 総合レベル
    private var overallLevel: StrengthLevel? {
        guard !recordedPRs.isEmpty else { return nil }
        var totalScore = 0.0
        for (exerciseId, weight) in recordedPRs {
            let result = StrengthScoreCalculator.exerciseStrengthLevel(
                exerciseId: exerciseId,
                estimated1RM: weight,
                bodyweightKg: bodyweightKg
            )
            totalScore += result.level.minimumScore
        }
        let avgScore = totalScore / Double(recordedPRs.count)
        return StrengthScoreCalculator.level(score: avgScore)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 16)

            // ヘッダー
            VStack(spacing: 4) {
                Text(L10n.prInputTitle)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Text(L10n.prInputSubtitle)
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer().frame(height: 8)

            // 筋肉マップ（タップ可能 + 未入力時タップガイド）
            ZStack {
                MuscleMapView(
                    muscleStates: muscleStates,
                    onMuscleTapped: { muscle in
                        tappedMuscle = muscle
                        HapticManager.lightTap()
                    }
                )
                .frame(height: 340)

                // 未入力時のタップガイド（マップ中央下部）
                if recordedPRs.isEmpty {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 12))
                            Text(isJapanese ? "筋肉をタップして重量を入力" : "Tap muscles to enter weights")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.mmOnboardingBg.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: recordedPRs.count)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 4)

            // 種目GIFカード（横スクロール）
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if recordedPRs.isEmpty {
                        // 未入力時: BIG3をGIFカードで表示
                        ForEach(defaultExercises, id: \.id) { exercise in
                            PRCompactGifCard(
                                exercise: exercise,
                                recordedWeight: nil
                            ) {
                                selectedExercise = exercise
                                HapticManager.lightTap()
                            }
                        }
                    } else {
                        // 入力済み全種目をGIFカードで表示
                        ForEach(recordedPRs.sorted(by: { $0.key < $1.key }), id: \.key) { exerciseId, weight in
                            if let def = ExerciseStore.shared.exercise(for: exerciseId) {
                                PRCompactGifCard(
                                    exercise: def,
                                    recordedWeight: weight
                                ) {
                                    selectedExercise = def
                                    HapticManager.lightTap()
                                }
                            }
                        }

                        // 「+追加」ボタン
                        Button {
                            // 胸をデフォルトで開く（最も一般的な追加先）
                            tappedMuscle = .chestUpper
                            HapticManager.lightTap()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                Text(isJapanese ? "追加" : "Add")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(Color.mmOnboardingTextSub)
                            .frame(width: 100, height: 100)
                            .background(Color.mmOnboardingCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: recordedPRs.count)

            // 強さレベルプレビュー or 動機付けテキスト
            if recordedPRs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.mmOnboardingAccent.opacity(0.4))
                    Text(isJapanese
                        ? "重量を入力すると、あなたの強さレベルが判定されます"
                        : "Enter your weights to see your strength level")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .opacity(appeared ? 1 : 0)
            } else if let level = overallLevel {
                VStack(spacing: 8) {
                    Text(isJapanese ? "現在のレベル" : "Your Level")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.mmOnboardingTextSub)

                    HStack(spacing: 8) {
                        ForEach(StrengthLevel.allCases, id: \.self) { l in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(l == level ? l.color : Color.mmOnboardingCard)
                                    .frame(width: l == level ? 28 : 16, height: l == level ? 28 : 16)
                                    .overlay(
                                        Group {
                                            if l == level {
                                                Text(l.emoji).font(.system(size: 12))
                                            }
                                        }
                                    )
                                if l == level {
                                    Text(l.localizedName)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(l.color)
                                }
                            }
                        }
                    }

                    Text(isJapanese
                        ? "もっと入力すると精度が上がります"
                        : "More entries = more accurate")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }
                .padding(10)
                .background(Color.mmOnboardingCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: overallLevel?.rawValue)
                .opacity(appeared ? 1 : 0)
            }

            Spacer(minLength: 2)

            // 次へ + スキップ
            VStack(spacing: 8) {
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

                Button {
                    guard !isProceeding else { return }
                    isProceeding = true
                    HapticManager.lightTap()
                    onNext()
                } label: {
                    Text(isJapanese ? "わからない場合はスキップ →" : "Skip if unsure →")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            isProceeding = false  // スワイプ戻り時にボタンを有効化
            ExerciseStore.shared.loadIfNeeded()
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                appeared = true
            }
        }
        // 筋肉タップ → 種目選択シート
        .sheet(item: $tappedMuscle) { muscle in
            MuscleExerciseSheet(
                muscle: muscle,
                recordedPRs: recordedPRs,
                onSelectExercise: { exercise in
                    tappedMuscle = nil
                    // 少し遅延して次のシートを表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        selectedExercise = exercise
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        // 種目選択 → 重量入力シート
        .sheet(item: $selectedExercise) { exercise in
            WeightInputSheet(
                exercise: exercise,
                initialWeight: recordedPRs[exercise.id],
                bodyweightKg: bodyweightKg,
                onSave: { weight in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        recordedPRs[exercise.id] = weight
                    }
                    HapticManager.stepperChanged()
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    /// PR入力値をUserProfileに保存
    private func savePRs() {
        AppState.shared.userProfile.initialPRs = recordedPRs
    }
}

// MARK: - 筋肉タップ → 種目選択シート

private struct MuscleExerciseSheet: View {
    let muscle: Muscle
    let recordedPRs: [String: Double]
    let onSelectExercise: (ExerciseDefinition) -> Void

    @State private var selectedEquipment: String? = nil

    private var localization: LocalizationManager { LocalizationManager.shared }
    private var isJapanese: Bool { localization.currentLanguage == .japanese }

    private let equipmentFilters: [(key: String, label: String, labelEn: String)] = [
        ("バーベル", "バーベル", "Barbell"),
        ("ダンベル", "ダンベル", "Dumbbell"),
        ("マシン", "マシン", "Machine"),
        ("ケーブル", "ケーブル", "Cable"),
    ]

    /// 重量不適種目を除外 + 器具フィルター適用
    private var exercises: [ExerciseDefinition] {
        var result = ExerciseStore.shared.exercises(targeting: muscle)
        // 重量記録に不適切な種目を除外（plank, burpee, ab_roller等）
        result = result.filter { !$0.isStrengthScoreExcluded }
        // 器具フィルター
        if let equip = selectedEquipment {
            result = result.filter { $0.equipment == equip }
        }
        return result
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            HStack {
                Text(isJapanese ? muscle.japaneseName : muscle.englishName)
                    .font(.headline.bold())
                    .foregroundStyle(Color.mmOnboardingTextMain)
                Spacer()
                Text(isJapanese ? "\(exercises.count)種目" : "\(exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // 器具フィルターチップ
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    equipmentChip(
                        text: isJapanese ? "すべて" : "All",
                        isSelected: selectedEquipment == nil
                    ) {
                        selectedEquipment = nil
                    }
                    ForEach(equipmentFilters, id: \.key) { filter in
                        equipmentChip(
                            text: isJapanese ? filter.label : filter.labelEn,
                            isSelected: selectedEquipment == filter.key
                        ) {
                            selectedEquipment = selectedEquipment == filter.key ? nil : filter.key
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 12)

            // 種目GIFグリッド（2カラム）
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(exercises) { exercise in
                        PRExerciseGridCard(
                            exercise: exercise,
                            recordedWeight: recordedPRs[exercise.id]
                        ) {
                            onSelectExercise(exercise)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(Color.mmOnboardingBg)
    }

    /// 器具フィルターチップ
    private func equipmentChip(text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.lightTap()
            action()
        }) {
            Text(text)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 重量入力シート

private struct WeightInputSheet: View {
    let exercise: ExerciseDefinition
    let initialWeight: Double?
    let bodyweightKg: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double = 0
    @State private var holdTimer: Timer?

    private var localization: LocalizationManager { LocalizationManager.shared }
    private var isJapanese: Bool { localization.currentLanguage == .japanese }

    /// 現在の重量でのレベル判定
    private var currentLevel: StrengthLevel? {
        guard weight > 0 else { return nil }
        return StrengthScoreCalculator.exerciseStrengthLevel(
            exerciseId: exercise.id,
            estimated1RM: weight,
            bodyweightKg: bodyweightKg
        ).level
    }

    var body: some View {
        VStack(spacing: 16) {
            // 種目ヘッダー（GIF + 名前）
            HStack(spacing: 12) {
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .thumbnail)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.mmOnboardingCard)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "dumbbell")
                                .font(.title3)
                                .foregroundStyle(Color.mmOnboardingTextSub)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.localizedName)
                        .font(.headline.bold())
                        .foregroundStyle(Color.mmOnboardingTextMain)
                        .lineLimit(1)
                    Text(exercise.localizedEquipment)
                        .font(.caption)
                        .foregroundStyle(Color.mmOnboardingTextSub)
                }

                Spacer()

                // レベルバッジ
                if let level = currentLevel {
                    Text(level.localizedName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(level.color)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: level.rawValue)
                }
            }

            // 重量入力エリア
            VStack(spacing: 12) {
                Text(isJapanese ? "最大重量 (1RM)" : "Max Weight (1RM)")
                    .font(.caption)
                    .foregroundStyle(Color.mmOnboardingTextSub)

                Text(isJapanese ? "1回だけ挙げられる最大の重量" : "The heaviest weight you can lift once")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.mmOnboardingTextSub.opacity(0.7))

                HStack(spacing: 16) {
                    // マイナスボタン（タップ + 長押し連続減少）
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.mmOnboardingTextSub)
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.15)) {
                                weight = max(0, min(300, weight - 2.5))
                            }
                            HapticManager.stepperChanged()
                        }
                        .onLongPressGesture(minimumDuration: 0.3, perform: {}) { pressing in
                            if pressing {
                                startHoldTimer(increment: -0.25)
                            } else {
                                stopHoldTimer()
                            }
                        }

                    // 重量表示
                    VStack(spacing: 0) {
                        Text(weightDisplayString(weight))
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundStyle(Color.mmOnboardingTextMain)
                            .frame(minWidth: 80)
                            .contentTransition(.numericText())

                        Text("kg")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.mmOnboardingTextSub)
                    }

                    // プラスボタン（タップ + 長押し連続増加）
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.mmOnboardingAccent)
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.15)) {
                                weight = min(300, weight + 2.5)
                            }
                            HapticManager.stepperChanged()
                        }
                        .onLongPressGesture(minimumDuration: 0.3, perform: {}) { pressing in
                            if pressing {
                                startHoldTimer(increment: 0.25)
                            } else {
                                stopHoldTimer()
                            }
                        }
                }
            }

            // 記録するボタン
            Button {
                guard weight > 0 else { return }
                onSave(weight)
                dismiss()
            } label: {
                Text(isJapanese ? "記録する" : "Record")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(weight > 0 ? Color.mmOnboardingBg : Color.mmOnboardingTextSub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(weight > 0 ? Color.mmOnboardingAccent : Color.mmOnboardingCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(weight <= 0)
            .animation(.easeInOut(duration: 0.2), value: weight > 0)
        }
        .padding(20)
        .background(Color.mmOnboardingBg)
        .onAppear {
            weight = initialWeight ?? 0
        }
        .onDisappear {
            stopHoldTimer()
        }
    }

    // MARK: - 長押し連続増減

    private func startHoldTimer(increment: Double) {
        stopHoldTimer()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.snappy(duration: 0.1)) {
                    weight = max(0, min(300, weight + increment))
                }
                HapticManager.stepperChanged()
            }
        }
    }

    private func stopHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
    }

    /// 整数なら "80"、小数なら "80.25"（末尾0除去）
    private func weightDisplayString(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        let formatted = String(format: "%.2f", value)
        // 末尾の "0" を除去（例: "80.50" → "80.5"）
        if formatted.hasSuffix("0") {
            return String(formatted.dropLast())
        }
        return formatted
    }
}

// MARK: - 種目GIFコンパクトカード（100x100横スクロール用）

private struct PRCompactGifCard: View {
    let exercise: ExerciseDefinition
    let recordedWeight: Double?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .card)
                        .scaledToFill()
                } else {
                    Color.mmOnboardingCard
                        .overlay(
                            Image(systemName: "dumbbell")
                                .font(.title3)
                                .foregroundStyle(Color.mmOnboardingTextSub)
                        )
                }

                // グラデーション + 種目名 + kg
                VStack(alignment: .leading, spacing: 1) {
                    Text(exercise.localizedName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let weight = recordedWeight {
                        Text("\(Int(weight))kg")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Color.mmOnboardingAccent)
                    } else {
                        Text(exercise.localizedEquipment)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 種目GIFグリッドカード（共通）

private struct PRExerciseGridCard: View {
    let exercise: ExerciseDefinition
    let recordedWeight: Double?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // GIF（card size, scaledToFill）
                if ExerciseGifView.hasGif(exerciseId: exercise.id) {
                    ExerciseGifView(exerciseId: exercise.id, size: .card)
                        .scaledToFill()
                } else {
                    Color.mmOnboardingCard
                        .overlay(
                            Image(systemName: "dumbbell")
                                .font(.title2)
                                .foregroundStyle(Color.mmOnboardingTextSub)
                        )
                }

                // グラデーション + 種目名 + 器具
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.localizedName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(exercise.localizedEquipment)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // 入力済み重量バッジ（右上）
                if let weight = recordedWeight {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(Int(weight))kg")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Color.mmOnboardingBg)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.mmOnboardingAccent)
                                .clipShape(Capsule())
                                .padding(6)
                        }
                        Spacer()
                    }
                } else {
                    // 未入力ガイド（中央）
                    VStack {
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.mmOnboardingBg.ignoresSafeArea()
        PRInputPage(onNext: {})
    }
}
