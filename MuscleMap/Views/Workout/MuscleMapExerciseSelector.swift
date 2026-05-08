import SwiftUI
import SwiftData

// MARK: - セパレーション拡張用 enum (v1.2 拡張フック)
//
// 現在は筋肉タップで直接 MuscleExercisePickerSheet を開く（2ステップ）。
// v1.2 では筋肉タップ → セパレーション選択（大胸筋上部内側/外側など）
//          → 種目絞り込み の3ステップに拡張する想定。
// このenumはそのフローを表現するための土台。
// 100DL達成後の v1.2 で実装予定。
enum MuscleSelectionStep {
    case selectMuscle                  // ステップ1: 筋肉タップ
    // case selectSeparation(Muscle)   // [v1.2] ステップ2: セパレーション (例: 大胸筋上部内側/外側)
    case selectExercise(Muscle)        // ステップ2 (現): 種目グリッド
}

// MARK: - マッスルマップ起点の種目選択コンポーネント（再利用可能）

/// 「マッスルマップ → 筋肉タップ → 種目グリッド」フローの共通View。
/// WorkoutIdleView のメインコンテンツ、Active状態の "+ 種目追加" シートで再利用される。
///
/// アーキテクチャ哲学: 全てのワークアウト追加はマッスルマップを起点とする。
/// 種目リスト直行は副入口（browseExercises）からのみアクセス可能。
struct MuscleMapExerciseSelector: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let onSelect: (ExerciseDefinition) -> Void
    /// 副入口「種目を探す」リンクの表示有無
    var showBrowseLink: Bool = true

    @State private var selectedMuscle: Muscle?
    @State private var showingBrowseAll = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 筋肉マップ（タップで種目選択）
                MuscleMapView(
                    muscleStates: muscleStates,
                    onMuscleTapped: { muscle in
                        // TODO: v1.2 でセパレーション選択画面を中継させる
                        // 現在は直接 MuscleExercisePickerSheet を開く
                        selectedMuscle = muscle
                    }
                )
                .frame(height: UIScreen.main.bounds.height * 0.40)
                .padding(.horizontal)

                // ヒント + 副入口（中央にガイド文、右端に検索アイコン）
                ZStack {
                    Text(L10n.tapMuscleHint)
                        .font(.caption)
                        .foregroundStyle(Color.mmTextSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 56)

                    if showBrowseLink {
                        HStack {
                            Spacer()
                            Button {
                                HapticManager.lightTap()
                                showingBrowseAll = true
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.mmAccentPrimary)
                                    .frame(width: 36, height: 36)
                                    .background(Color.mmBgCard)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.browseExercises)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedMuscle) { muscle in
            MuscleExercisePickerSheet(muscle: muscle) { exercise in
                onSelect(exercise)
                selectedMuscle = nil
            }
        }
        .sheet(isPresented: $showingBrowseAll) {
            ExercisePickerView { exercise in
                onSelect(exercise)
                showingBrowseAll = false
            }
        }
    }
}

// MARK: - Sheet ラッパー（Active状態の "+ 種目追加" 用）

/// ワークアウト実行中の「+ 種目を追加」ボタンから表示されるシート。
/// 中身は MuscleMapExerciseSelector と同じだが、NavigationStack + 閉じるボタン付き。
struct MuscleMapExerciseSelectorSheet: View {
    let muscleStates: [Muscle: MuscleVisualState]
    let onSelect: (ExerciseDefinition) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mmBgPrimary.ignoresSafeArea()

                MuscleMapExerciseSelector(
                    muscleStates: muscleStates,
                    onSelect: { exercise in
                        onSelect(exercise)
                        dismiss()
                    }
                )
            }
            .navigationTitle(L10n.selectExercise)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.close) { dismiss() }
                        .foregroundStyle(Color.mmAccentPrimary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Selector") {
    ZStack {
        Color.mmBgPrimary.ignoresSafeArea()
        MuscleMapExerciseSelector(
            muscleStates: [:],
            onSelect: { _ in }
        )
    }
}

#Preview("Sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            MuscleMapExerciseSelectorSheet(
                muscleStates: [:],
                onSelect: { _ in }
            )
        }
}
