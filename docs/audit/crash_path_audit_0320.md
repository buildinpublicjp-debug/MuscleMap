# クラッシュパス網羅監査 — 2026-03-20

> **対象:** `/Users/og3939397/MuscleMap/MuscleMap/` 配下の全 `.swift` ファイル
> **手法:** grep + Read のみ（コード変更なし）
> **ツール:** 6並列サブエージェントによる網羅検索

---

## サマリー

| カテゴリ | Critical | High | Medium | Low | 合計 |
|:---|:---:|:---:|:---:|:---:|:---:|
| 1. Force Unwrap (`!`) | 0 | 0 | 0 | 5 | 5 |
| 2. Array Index (`[index]`) | 0 | 3 | 5 | 8 | 16 |
| 3. Division by Zero (`/`, `%`) | 0 | 0 | 2 | 36 | 38 |
| 4. Optional Chain Dangers | 0 | 1 | 5 | 7 | 13 |
| 5. Today's Changed Files | 1 | 4 | 5 | 6 | 16 |
| 6. SwiftData Query Safety | 2 | 4 | 3 | 2 | 11 |
| **合計** | **3** | **12** | **20** | **64** | **99** |

---

## Critical（即クラッシュ）

### C-1. RoutineBuilderPage — `locationPicker` Binding の未ガード配列アクセス

- **ファイル:** `Views/Onboarding/RoutineBuilderPage.swift`
- **行:** 238-242
- **カテゴリ:** Array Index / Today's Changed Files

```swift
Picker("", selection: Binding(
    get: { days[selectedDayIndex].location },
    set: { newLocation in
        days[selectedDayIndex].location = newLocation
    }
))
```

**シナリオ:** `exerciseListView` は `if days.indices.contains(selectedDayIndex)` でガードされているが、Binding クロージャは遅延評価される。SwiftUI が View 更新中に `days` が変化した場合（リセット・再初期化等）、get/set クロージャ内で `days[selectedDayIndex]` が Index out of range でクラッシュする。

**修正案:**
```swift
get: { days.indices.contains(selectedDayIndex) ? days[selectedDayIndex].location : "gym" }
set: { newLocation in
    guard days.indices.contains(selectedDayIndex) else { return }
    days[selectedDayIndex].location = newLocation
}
```

---

### C-2. WorkoutRepository.startSession() — 未保存オブジェクトを返却

- **ファイル:** `Repositories/WorkoutRepository.swift`
- **行:** 34-45
- **カテゴリ:** SwiftData Query Safety

```swift
func startSession() -> WorkoutSession {
    let session = WorkoutSession()
    modelContext.insert(session)
    do {
        try modelContext.save()
    } catch {
        print("[DEBUG] save error: \(error)")
    }
    return session  // save() 失敗時も返却される
}
```

**シナリオ:** `save()` が失敗しても `WorkoutSession` オブジェクトが返却される。呼び出し元の `WorkoutViewModel` はこのセッションに対してセットを記録し続けるが、アプリ終了時にデータが全て消失する。ユーザーはワークアウトを記録したと思っているが、再起動後にデータがない。

**修正案:** `startSession() throws -> WorkoutSession` に変更し、呼び出し元で失敗をハンドリング。

---

### C-3. DayWorkoutDetailView — 3回連続 save() でロールバック不可

- **ファイル:** `Views/History/DayWorkoutDetailView.swift`
- **行:** 348-378
- **カテゴリ:** SwiftData Query Safety

```swift
func deleteSet() {
    modelContext.delete(workoutSet)
    try? modelContext.save()          // save #1
    // ... setNumber 再番号付け ...
    try? modelContext.save()          // save #2
    // ... session.sets 更新 ...
    try? modelContext.save()          // save #3
}
```

**シナリオ:** save #1 が成功（セット削除永続化）→ save #2 が失敗（再番号付けが消失）→ setNumber が不整合になる。3つの `try?` が独立して失敗しうるため、データ整合性が保証されない。

**修正案:** 3つの操作を1つの `do { ... try modelContext.save() } catch { ... }` にまとめ、アトミックに保存。

---

## High

### H-1. RoutineEditView — `deleteExercises` / `moveExercises` 未ガード

- **ファイル:** `Views/Settings/RoutineEditView.swift`
- **行:** 199-206
- **カテゴリ:** Array Index

```swift
private func deleteExercises(at offsets: IndexSet) {
    days[selectedDayIndex].exercises.remove(atOffsets: offsets)
}
private func moveExercises(from source: IndexSet, to destination: Int) {
    days[selectedDayIndex].exercises.move(fromOffsets: source, toOffset: destination)
}
```

**シナリオ:** 同ファイルの `addExercise()` は `guard days.indices.contains(selectedDayIndex)` でガード済み。delete/move は `.onDelete` / `.onMove` から呼ばれるため、タブ切替と同時にスワイプ操作があった場合にクラッシュの可能性。

**修正案:** 両関数の先頭に `guard days.indices.contains(selectedDayIndex) else { return }` を追加。

---

### H-2. RoutineEditView — `exerciseHeader` / `exerciseList` のサブビュー内未ガード

- **ファイル:** `Views/Settings/RoutineEditView.swift`
- **行:** 123, 129, 157
- **カテゴリ:** Array Index

```swift
// exerciseHeader (line 123):
Text(L10n.routineExerciseCount(days[selectedDayIndex].exercises.count, maxExercisesPerDay))
// exerciseList (line 157):
ForEach(days[selectedDayIndex].exercises) { routineExercise in
```

**シナリオ:** 呼び出し元でガード済みだが、computed property 内部にガードがない。リファクタリングで呼び出し元が変わった場合に即クラッシュ。

---

### H-3. RoutineBuilderPage — `selectedDayIndex += 1` 上限クランプなし

- **ファイル:** `Views/Onboarding/RoutineBuilderPage.swift`
- **行:** 449-450
- **カテゴリ:** Today's Changed Files

```swift
withAnimation(.easeInOut(duration: 0.3)) {
    selectedDayIndex += 1
}
```

**シナリオ:** `isLastDay` チェック（行272）の後にインクリメントされるが、レースコンディション（`days` が変更された場合）で `selectedDayIndex` が `days.count` を超える可能性。

**修正案:** `selectedDayIndex = min(selectedDayIndex + 1, days.count - 1)`

---

### H-4. RoutineBuilderPage — `editingExerciseIndex` のステイル

- **ファイル:** `Views/Onboarding/RoutineBuilderPage.swift`
- **行:** 102-107, 422-428
- **カテゴリ:** Today's Changed Files

**シナリオ:** ユーザーがインデックス3の種目を編集中に、別の種目が削除されると、インデックス3が範囲外になる可能性。行103-104のガードで保護されているが、`$days[selectedDayIndex].exercises[editIdx]` の Binding 評価タイミング次第でクラッシュの窓がある。

**修正案:** `removeExercise()` の先頭で `editingExerciseIndex = nil` をセット。

---

### H-5. FrequencySelectionPage — Timer リテインサイクル

- **ファイル:** `Views/Onboarding/FrequencySelectionPage.swift`
- **行:** 303-308
- **カテゴリ:** Today's Changed Files

```swift
let timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [trainingDays] _ in
    Task { @MainActor in
        animationDay = (animationDay + 1) % 7
    }
}
```

**シナリオ:** クロージャが `self` を暗黙的にキャプチャ（`animationDay` 経由）。`onDisappear` で解除されるが、迅速なナビゲーション時にリークする可能性。

---

### H-6. LocationSelectionPage — Timer リテインサイクル（33Hz）

- **ファイル:** `Views/Onboarding/LocationSelectionPage.swift`
- **行:** 246-249
- **カテゴリ:** Today's Changed Files

```swift
autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
    Task { @MainActor in
        scrollOffset -= 0.5
    }
}
```

**シナリオ:** 0.03秒間隔（33Hz）で `@State` を更新。H-5 と同じリテインサイクルリスクに加え、CPU 負荷が高い。

---

### H-7. SwiftData — 無制限 FetchDescriptor（メモリ枯渇）

- **ファイル:** 複数
- **カテゴリ:** SwiftData Query Safety

| ファイル | 行 | 内容 |
|:---|:---|:---|
| `Repositories/MuscleStateRepository.swift` | 16-17 | 全 `MuscleStimulation` を fetch（21筋肉分だけ必要） |
| `Views/Home/HomeView.swift` | 314 | 全 `WorkoutSet` を fetch（ホーム表示のたび） |
| `ViewModels/MuscleBalanceDiagnosisViewModel.swift` | 182-185 | 全完了セッション fetch |
| `ViewModels/MuscleJourneyViewModel.swift` | 163-165 | 全刺激データ fetch（2回） |

**シナリオ:** 数ヶ月〜1年使用のヘビーユーザーでは WorkoutSet が 10,000+ レコードになる。ホーム画面表示のたびに全件メモリロードされ、メモリ警告→クラッシュの可能性。

---

### H-8. SwiftData — `try?` によるエラー黙殺（17箇所）

- **ファイル:** 複数（WorkoutCompletionView, PRManager, MuscleHeatmapViewModel, StreakViewModel, WeeklySummaryViewModel, MuscleJourneyViewModel, RoutineManager, ImportDataConverter 等）
- **カテゴリ:** SwiftData Query Safety

**シナリオ:** `try? modelContext.fetch(descriptor)` / `try? modelContext.save()` でエラーを黙殺。fetch 失敗時にデータが表示されない（ユーザーは空だと思い込む）。save 失敗時にデータが消失する（次回起動で復活）。

---

### H-9. SwiftData — save 失敗がユーザーに通知されない

- **ファイル:** `Repositories/WorkoutRepository.swift`
- **行:** 93-101, 153-164
- **カテゴリ:** SwiftData Query Safety

**シナリオ:** `addSet()` は save 失敗時も未保存の `WorkoutSet` を返却。`discardSession()` は delete 後の save が失敗すると「ゴースト」データが次回起動時に復活。

---

### H-10. SwiftData — fetch 失敗によるデータ重複

- **ファイル:** `Repositories/MuscleStateRepository.swift`
- **行:** 73-80
- **カテゴリ:** SwiftData Query Safety

```swift
let existing = try? modelContext.fetch(descriptor).first  // fetch 失敗 → nil
if let existing = existing {
    // 更新
} else {
    // 新規挿入 ← 既存レコードがあっても重複挿入される
}
```

**シナリオ:** `upsertStimulation()` で fetch が失敗すると `existing` が nil になり、既存レコードがあっても新規レコードが挿入される。回復計算が破損する。

---

## Medium

### M-1. StrengthShareCard — `medals[index]` 未ガード

- **ファイル:** `Views/Home/StrengthShareCard.swift`
- **行:** 207-210
- **カテゴリ:** Array Index

```swift
let medals = ["🥇", "🥈", "🥉"]
ForEach(Array(topMuscles.enumerated()), id: \.offset) { index, entry in
    rankRow(medal: medals[index], ...)
```

**シナリオ:** `topMuscles` が 4 要素以上の場合、`medals[3]` で Index out of range。現在の Producer は `.prefix(3)` を使っているが、ForEach 側にガードがない。

**修正案:** `ForEach(Array(topMuscles.prefix(3).enumerated()), ...)`

---

### M-2. GoalSelectionPage — `Set.first` の非決定性

- **ファイル:** `Views/Onboarding/GoalSelectionPage.swift`
- **行:** 183
- **カテゴリ:** Optional Chain Dangers / Today's Changed Files

```swift
if let first = selectedGoals.first {
    AppState.shared.primaryOnboardingGoal = first.rawValue
}
```

**シナリオ:** `Set` は順序不定。複数目標選択時に `primaryOnboardingGoal` がランダムに決まり、下流の GoalMusclePreviewPage・RoutineBuilderPage で不整合が発生。

---

### M-3. GoalSelectionPage — 全目標解除時のステイル

- **ファイル:** `Views/Onboarding/GoalSelectionPage.swift`
- **行:** 172-185
- **カテゴリ:** Optional Chain Dangers

**シナリオ:** ユーザーが全目標を解除しても `primaryOnboardingGoal` がクリアされない（`else` 分岐がない）。再選択時に前回の値が残留。

---

### M-4. StrengthScoreCalculator — `lerp` 分母未ガード

- **ファイル:** `Utilities/StrengthScoreCalculator.swift`
- **行:** 170
- **カテゴリ:** Division by Zero

```swift
let t = (value - from) / (to - from)  // to == from なら NaN
```

**シナリオ:** `inverseLerp()` は `guard scoreTo != scoreFrom` でガード済みだが、`lerp()` にはガードがない。現在の呼び出し元は全て `from != to` だが、将来の追加で危険。

---

### M-5. MenuSuggestionService — `MuscleGroup.muscles.count` の脆弱性

- **ファイル:** `Utilities/MenuSuggestionService.swift`
- **行:** 145
- **カテゴリ:** Division by Zero

```swift
scores[group] = totalScore / Double(muscles.count)
```

**シナリオ:** 現在は全 MuscleGroup に 2 筋肉以上あるが、新グループ追加時に筋肉マッピングを忘れると Division by Zero。

---

### M-6. primaryOnboardingGoal — nil 伝播（不整合な fallback）

- **ファイル:** 複数（GoalMusclePreviewPage, RoutineCompletionPage, CallToActionPage, PaywallView）
- **カテゴリ:** Optional Chain Dangers

**シナリオ:** `primaryOnboardingGoal` が nil の場合、各画面のフォールバック値が異なる（`.getBig`、汎用ヘッドライン、日本語のみコピー、空配列）。ユーザーは一貫性のないコンテンツを見る。

---

### M-7. homeEquipment フィルタ — 日本語のみ文字列

- **ファイル:** `Views/Onboarding/GoalMusclePreviewPage.swift` (行220), `Views/Onboarding/RoutineBuilderPage.swift` (行471)
- **カテゴリ:** Today's Changed Files

```swift
let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル"]
// LocationSelectionPage は両言語対応済み: ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
```

**シナリオ:** exercises.json が英語 equipment 文字列を使っている場合、自宅フィルタが 0 件になり、全種目にフォールバック。「自宅」を選んだのにジム種目が表示される。

---

### M-8. PRInputPage — `DispatchQueue.main.asyncAfter` シート連鎖

- **ファイル:** `Views/Onboarding/PRInputPage.swift`
- **行:** 285-287
- **カテゴリ:** Today's Changed Files

```swift
tappedMuscle = nil
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    selectedExercise = exercise
}
```

**シナリオ:** 0.3 秒のハードコード遅延でシート切替。アクセシビリティの「モーションを減らす」有効時や低速デバイスで、第2シートが表示されない可能性。

---

### M-9. RoutineCompletionPage — 空ルーティン対応なし

- **ファイル:** `Views/Onboarding/RoutineCompletionPage.swift`
- **行:** 18-20
- **カテゴリ:** Today's Changed Files

**シナリオ:** 状態復元バグ等で `RoutineManager.shared.routine.days` が空の場合、完了画面に「0種目 / 0日」「0%カバレッジ」が表示される。クラッシュはしないが、ユーザー体験が著しく劣化。

---

### M-10. SwiftData — cascade delete での二重削除

- **ファイル:** `Repositories/WorkoutRepository.swift` (行153-157), `Views/History/DayWorkoutDetailView.swift` (行383-394)
- **カテゴリ:** SwiftData Query Safety

```swift
// 手動で全 set を delete → session も delete（cascade で再度 set を delete）
for set in session.sets {
    modelContext.delete(set)  // 手動削除
}
modelContext.delete(session)  // cascade で sets も削除 → 二重削除
```

**シナリオ:** SwiftData は通常これを gracefully に処理するが、エッジケースでは問題が発生しうる。不要な処理でもある。

---

### M-11. SwiftData — 非アトミック複数 save

- **ファイル:** `Views/History/DayWorkoutDetailView.swift`
- **行:** 352-370
- **カテゴリ:** SwiftData Query Safety（C-3 の詳細）

3回の `try? modelContext.save()` が独立して失敗しうる。

---

### M-12. SwiftData — スレッドタイミング

- **ファイル:** `Connectivity/PhoneSessionManager.swift`
- **行:** 203-245
- **カテゴリ:** SwiftData Query Safety

`nonisolated` デリゲートメソッドから `Task { @MainActor in }` で SwiftData 操作。Watch からのバースト送信で複数 Task の実行順序が保証されない。

---

## Low（全 64 件 — 代表例のみ記載）

### Force Unwrap（5件 — 全て Low）

| # | ファイル | 行 | コード | 理由 |
|:---|:---|:---|:---|:---|
| L-1 | `ViewModels/HistoryViewModel.swift` | 384 | `lastWorkoutDate!` | `||` 短絡評価で保護 |
| L-2 | `ViewModels/HistoryViewModel.swift` | 192 | `exerciseDailyMax[exId]!` | 直前の nil チェックで保護 |
| L-3 | `ViewModels/HistoryViewModel.swift` | 415 | `dailyMaxWeights[date]!` | `.keys.sorted()` で取得したキーなので安全 |
| L-4 | `App/MuscleMapApp.swift` | 131 | `cal.date(byAdding:)!` | デモデータ生成のみ、実運用パス外 |
| L-5 | `Views/Workout/FullBodyConquestView.swift` | 271 | `colors.randomElement()!` | 9要素ハードコード配列、空にならない |

### Array Index（8件 — 全てガード済み）

代表例:
- `FrequencySelectionPage.swift:239` — `day < schedule.count` でガード
- `CSVParser.swift:76` — `columns.count >= 4` でガード
- `MuscleMapApp.swift:357` — `% exerciseRotation.count` でガード

### Division by Zero（36件 — 全て定数・ガード済み）

代表例:
- `RecoveryCalculator.swift:40` — `guard needed > 0` でガード
- `HistoryViewModel.swift:586` — `guard first > 0` でガード
- `ColorCalculator.swift:55-70` — 定数 `0.2` で除算
- `StrengthScoreCalculator.swift:248` — `bodyweightKg > 0 ? bodyweightKg : 70.0` でガード

### Optional Chain（7件）

代表例:
- `MuscleJourneyView.swift:186` — `changeSummary?.newlyStimulated.count ?? 0`（安全）
- `HomeNeglectedComponents.swift:54` — `muscleInfos.first` に `??` fallback
- `MenuPreviewSheet.swift:36` — 二重 fallback `?? ""` → `?? .chest`

### SwiftData（2件）

- `MuscleStimulation` の orphan リスク — session 削除時に手動で `deleteStimulations` を呼ぶ必要があるが、`WorkoutRepository.discardSession()` 内では呼ばれない
- `MuscleMapApp.swift:131` — `#if DEBUG` 内の force unwrap

---

## 修正優先度マトリクス

| 優先度 | ID | 修正内容 | 影響範囲 |
|:---|:---|:---|:---|
| **P0** | C-1 | `locationPicker` Binding に bounds check 追加 | クラッシュ防止 |
| **P0** | C-2 | `startSession()` を `throws` に変更 | データ消失防止 |
| **P0** | C-3 | `deleteSet()` の 3 save をアトミック化 | データ整合性 |
| **P1** | H-1 | `RoutineEditView` delete/move にガード追加 | クラッシュ防止 |
| **P1** | H-3 | `selectedDayIndex` に上限クランプ | クラッシュ防止 |
| **P1** | H-4 | `editingExerciseIndex` を削除時クリア | クラッシュ窓を閉じる |
| **P1** | H-7 | 重要 FetchDescriptor に `fetchLimit` 追加 | メモリ枯渇防止 |
| **P1** | H-10 | `upsertStimulation` の fetch 失敗で新規挿入しない | データ重複防止 |
| **P2** | H-5/H-6 | Timer を SwiftUI ライフサイクル管理に変更 | リテインサイクル |
| **P2** | M-1 | `topMuscles` に `.prefix(3)` 追加 | Index out of range 防止 |
| **P2** | M-7 | `homeEquipment` に英語文字列追加 | フィルタ修正 |
| **P3** | M-2/M-3 | `Set.first` → ソート済み + else 分岐 | ロジック正確性 |
| **P3** | M-4 | `lerp()` に `guard to != from` 追加 | 将来のクラッシュ防止 |

---

## 総評

### 強み
- `as!`（Force Cast）: **0件** — 優秀
- `try!`（Force Try）: **0件** — 優秀
- 暗黙アンラップ型（`Type!`）: **0件** — 優秀
- `fatalError()` / `preconditionFailure()`: **0件** — 優秀
- `.first!` / `.last!` / `removeFirst()` / `removeLast()`: **0件** — 優秀
- `@Query` 未使用（ViewModel/Repository 経由のみ）: 良い設計判断
- `@MainActor` アノテーション: 全 Repository/ViewModel に適用済み

### 弱み
- **`days[selectedDayIndex]`** パターン: RoutineBuilderPage と RoutineEditView の両方で、一部パスにガードが欠如
- **`try?` の過度な使用**: 17箇所でエラーを黙殺。ユーザーに一切フィードバックがない
- **FetchDescriptor の `fetchLimit` 未指定**: ホーム画面の `loadStrengthScores()` が毎回全 WorkoutSet を fetch するのは特に危険
- **Timer のライフサイクル管理**: `Timer.scheduledTimer` + 暗黙 self キャプチャが複数箇所に存在

---

*Generated by Claude Code — 2026-03-20*
