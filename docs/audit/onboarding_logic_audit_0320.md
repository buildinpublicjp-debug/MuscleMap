# Onboarding Logic Audit — 2026-03-20

> 対象: `Views/Onboarding/` 配下14ファイル + `AppState.swift` + `UserProfile.swift` + `UserRoutine.swift` + `GoalMusclePriority.swift`
> 目的: 3/19〜20 の20CC超の変更後、ページ遷移・データフロー・状態管理の整合性を徹底チェック
> **コード変更なし — 読み取り専用分析**

---

## 1. ページ遷移ロジック

### 1-1. 実際のフロー（OnboardingV2View.swift）

```
Page 0: GoalSelectionPage        — 目標選択（複数選択）
Page 1: FrequencySelectionPage   — 週間頻度（2/3/4/5）
Page 2: LocationSelectionPage    — 場所（gym/home/both）
Page 3: ProfileInputPage         — トレ歴 + 体重 + ニックネーム ★統合済み
Page 4: PRInputPage              — PR入力（経験者のみ）
Page 5: GoalMusclePreviewPage    — 目標×筋肉ビジュアル + 分割法プレビュー
Page 6: RoutineBuilderPage       — 自動ルーティン構築
Page 7: RoutineCompletionPage    — サマリー + ハードペイウォール
```

### 1-2. CLAUDE.md との乖離 ⚠️ CRITICAL

| 項目 | CLAUDE.md 記載 | 実コード |
|:---|:---|:---|
| Page 3 | `TrainingHistoryPage（トレ歴選択）` | `ProfileInputPage（トレ歴+体重+ニックネーム統合）` |
| Page 6 | `WeightInputPage（体重・ニックネーム入力）` | `RoutineBuilderPage` |
| Page 7 | `RoutineBuilderPage` | `RoutineCompletionPage` |
| Page 8 | `RoutineCompletionPage` | **存在しない（全8ページ = 0〜7）** |
| 最大ページ数 | 9ページ | 8ページ（PR込み）/ 7ページ（PRスキップ） |

**影響:** CLAUDE.md の「最大9ページ」「Page 6: WeightInputPage」は実コードと一致しない。WeightInputPage は `ProfileInputPage` に統合され、Page 3 で処理される。ドキュメントの更新が必要。

### 1-3. PR スキップ判定

```swift
// OnboardingV2View.swift:11-13
private var showPRInput: Bool {
    AppState.shared.userProfile.trainingExperience.shouldShowPRInput
}

// UserProfile.swift:80-82
var shouldShowPRInput: Bool {
    self == .oneYearPlus || self == .veteran
}
```

- `afterProfileInput()` で Page 3 → Page 4（PR）or Page 5（GoalMusclePreview）に分岐
- インジケーターも `indicatorPages` で動的に Page 4 を除外

**判定:** 正常。PRスキップ時のインジケーターも正しく `[0,1,2,3,5,6,7]` を返す。

### 1-4. TabView のスワイプ

`.tabViewStyle(.page(indexDisplayMode: .never))` により、ユーザーは横スワイプでもページ遷移可能。ただし各ページの「次へ」ボタンでデータ保存が行われるため、**スワイプで次ページに移動した場合、データ保存がスキップされるリスクがある**。

**⚠️ MEDIUM:** TabView の `.page` スタイルはスワイプを無効化できない。ユーザーがスワイプで GoalSelectionPage → FrequencySelectionPage に遷移すると `primaryOnboardingGoal` が未設定のまま進行する可能性がある。

---

## 2. データフロー分析

### 2-1. 書き込みタイミング一覧

| データ | 書き込み箇所 | タイミング |
|:---|:---|:---|
| `primaryOnboardingGoal` | GoalSelectionPage:183-184 | 目標トグルのたびに `selectedGoals.first` を保存 |
| `goalPriorityMuscles` | GoalSelectionPage:211 | 「次へ」タップ時に全選択目標の筋肉を合算保存 |
| `goalPriorityMuscles` | OnboardingV2View:66-68 | GoalMusclePreviewPage「次へ」時に `primaryOnboardingGoal` ベースで再計算・上書き |
| `weeklyFrequency` | OnboardingV2View:37 | FrequencySelectionPage「次へ」時 |
| `trainingLocation` | OnboardingV2View:44 | LocationSelectionPage「次へ」時 |
| `trainingExperience` | ProfileInputPage:131 | 経験ボタンタップ即時 |
| `weightKg` | ProfileInputPage:209,293 | ステッパー操作 + 「次へ」時（二重書き込み、問題なし） |
| `nickname` | ProfileInputPage:282,294 | onChange即時 + 「次へ」時 |
| `initialPRs` | PRInputPage:313 | 「次へ」タップ時のみ（スキップ時は未保存） |
| ルーティン | RoutineBuilderPage:436-437 | 最終Day完了時に `RoutineManager.shared.saveRoutine()` |
| `hasCompletedOnboarding` | ContentView経由 | `onComplete()` → 外部で設定 |

### 2-2. `primaryOnboardingGoal` の非決定性 ⚠️ HIGH

```swift
// GoalSelectionPage.swift:183
if let first = selectedGoals.first {
    AppState.shared.primaryOnboardingGoal = first.rawValue
}
```

`selectedGoals` は `Set<OnboardingGoal>` であり、**`Set.first` は挿入順が保証されない**。ユーザーが「デカくなりたい」→「モテたい」の順で選択しても、`primaryOnboardingGoal` が `"get_attractive"` になる可能性がある。

**影響箇所:**
- `GoalMusclePreviewPage.currentGoal` — 表示される目標名とハイライト筋肉が意図と異なる可能性
- `OnboardingV2View:64-68` — `goalPriorityMuscles` の上書きが `primaryOnboardingGoal` 1つだけの筋肉で行われ、GoalSelectionPage で保存した複数目標の合算筋肉が失われる
- `RoutineCompletionPage.goalBasedHeadline` — 目標別キャッチコピーが意図しない目標のものになる

### 2-3. `goalPriorityMuscles` のトリプルライト ⚠️ MEDIUM

1. **GoalSelectionPage「次へ」（:211）** — 全選択目標の筋肉合算 → `goalPriorityMuscles` に保存
2. **OnboardingV2View GoalMusclePreviewPage 遷移後（:64-68）** — `primaryOnboardingGoal` 1つだけの筋肉で **上書き**

**問題:** GoalSelectionPage で複数目標を選択した場合、合算された筋肉リストが GoalMusclePreviewPage 通過時に単一目標の筋肉に縮小される。

```
例: ユーザーが getBig + getAttractive を選択
  → GoalSelectionPage「次へ」: [chestUpper, chestLower, lats, quad, ham, glutes, deltAnterior, deltLateral, biceps, abs]
  → GoalMusclePreviewPage 通過: Set.first = getBig なら [chestUpper, chestLower, lats, quad, ham, glutes] に縮小
                                  Set.first = getAttractive なら [chestUpper, deltAnterior, deltLateral, biceps, abs] に縮小
```

---

## 3. GoalSelectionPage 複数選択のダウンストリーム影響

### 3-1. GoalMusclePreviewPage — 単一目標のみ使用

```swift
// GoalMusclePreviewPage.swift:18-24
private var currentGoal: OnboardingGoal {
    guard let raw = AppState.shared.primaryOnboardingGoal,
          let goal = OnboardingGoal(rawValue: raw) else {
        return .getBig  // フォールバック
    }
    return goal
}
```

GoalMusclePreviewPage は `primaryOnboardingGoal`（単一）のみ参照。GoalSelectionPage で複数選択した情報は `splitPreview` にも反映されない。

### 3-2. RoutineBuilderPage — `goalPriorityMuscles` 参照

```swift
// RoutineBuilderPage.swift:306
priorityMuscles: profile.goalPriorityMuscles,
```

`autoPickExercises` の優先ソートに使用。上記 2-3 の上書き問題により、複数目標の合算筋肉がここに到達する保証がない。

### 3-3. RoutineCompletionPage — 単一目標のキャッチコピー

```swift
// RoutineCompletionPage.swift:87-88
guard let raw = AppState.shared.primaryOnboardingGoal,
      let goal = OnboardingGoal(rawValue: raw) else { ... }
```

`primaryOnboardingGoal` のみ参照。複数目標選択の場合、表示されるコピーが意図しない目標のものになる可能性。

---

## 4. RoutineBuilderPage Day 選択ロジック

### 4-1. 初期化

```swift
private func initializeDays() {
    guard days.isEmpty else { return }  // 二重初期化ガード ✅
    let parts = splitParts  // weeklyFrequency から SplitPart[] を取得
    ...
}
```

- `splitParts` は `AppState.shared.userProfile.weeklyFrequency` を参照
- `userLocation` は `profile.trainingLocation` を参照
- **両方ともページ到達前に保存済み** ✅

### 4-2. Day 間遷移

```swift
private func saveAndProceed() {
    if isLastDay {
        let routine = UserRoutine(days: days, createdAt: Date())
        RoutineManager.shared.saveRoutine(routine)
        ...
        onNext()
    } else {
        selectedDayIndex += 1
    }
}
```

- `canProceed` は `!days[selectedDayIndex].exercises.isEmpty` をチェック ✅
- 最終 Day で `saveRoutine` → `onNext()` の順序 ✅
- お気に入りにも全種目を登録 ✅

### 4-3. Location 切替時の種目再ピック

```swift
private func rebuildExercisesForCurrentDay(location: String) {
    ...
    let exercises = autoPickExercises(...)
    days[selectedDayIndex].exercises = exercises
}
```

- 他の Day の exercises は保持される ✅
- Day ごとに独立した location を持てる ✅

---

## 5. タイマー / アニメーションリーク

### 5-1. FrequencySelectionPage — Timer

```swift
@State private var animationTimerRef: Timer?

private func startRecoveryAnimation(frequency: WeeklyFrequency) {
    stopAnimation()  // 既存タイマーを先にinvalidate ✅
    ...
    let timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { ... }
    animationTimerRef = timer
}

private func stopAnimation() {
    animationTimerRef?.invalidate()
    animationTimerRef = nil
}
```

- `onDisappear { stopAnimation() }` でクリーンアップ ✅
- ただし `Timer.scheduledTimer` のクロージャ内で `[trainingDays]` はキャプチャしているが、`self`（View 構造体）への強参照はない（SwiftUI の `@State` は間接参照）
- **リスク: 低。** SwiftUI の View 再生成時に `@State` は保持されるが、`onDisappear` で確実に停止している。

### 5-2. LocationSelectionPage — Auto Scroll Timer

```swift
@State private var autoScrollTimer: Timer?

private func startAutoScroll() {
    stopAutoScroll()  // 先に停止 ✅
    autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
        Task { @MainActor in scrollOffset -= 0.5 }
    }
}
```

- `onDisappear { stopAutoScroll() }` でクリーンアップ ✅
- **⚠️ LOW:** `0.03秒` 間隔（≈33fps）のタイマー。`Task { @MainActor in ... }` の生成コストが毎フレーム発生。`withAnimation` なしで `scrollOffset` を更新しているが、SwiftUI の差分検知がトリガーされるため事実上毎フレームレンダリング。パフォーマンスへの影響は軽微だが、`CADisplayLink` や `TimelineView` の方が適切。

### 5-3. SplashView — DispatchQueue.main.asyncAfter

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { ... }
DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { ... }
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { ... }
```

- キャンセル不可な `asyncAfter` を3回使用
- **リスク: 極低。** スプラッシュ画面は1回しか表示されず、View が消えても `@State` への書き込みは SwiftUI が無視する。

### 5-4. PRInputPage — DispatchQueue.main.asyncAfter

```swift
// PRInputPage.swift:285
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    selectedExercise = exercise
}
```

- シート dismiss → 0.3秒後に次のシートを表示
- **リスク: 極低。** 画面遷移済みなら `@State` 更新は無視される。

### 5-5. RoutineCompletionPage — repeatForever アニメーション

```swift
withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
    buttonGlow = true
}
```

- `repeatForever` アニメーションは View が表示中のみアクティブ（SwiftUI 管理）✅
- 明示的な停止不要

---

## 6. クラッシュパス分析

### 6-1. ExerciseStore 未ロード

```swift
// GoalMusclePreviewPage.swift:51
ExerciseStore.shared.loadIfNeeded()

// RoutineBuilderPage.swift:290
exerciseStore.loadIfNeeded()

// PRInputPage.swift:272
ExerciseStore.shared.loadIfNeeded()
```

**判定:** 主要な消費者は `loadIfNeeded()` を呼んでいる ✅。ただし GoalSelectionPage は `ExerciseStore` を直接呼ばず `GoalMusclePriority.data(for:)` 経由で使用し、その中で `loadIfNeeded()` が呼ばれる ✅。

### 6-2. 空配列アクセス

| 箇所 | チェック |
|:---|:---|
| `RoutineBuilderPage.days[selectedDayIndex]` | `days.indices.contains(selectedDayIndex)` ガードあり ✅ |
| `RoutineBuilderPage.days[selectedDayIndex].exercises[editIdx]` | `days[selectedDayIndex].exercises.indices.contains(editIdx)` ガードあり ✅ |
| `GoalSelectionPage.cardAppearances[index]` | `cardAppearances.indices.contains(index)` ガードあり ✅ |
| `splitPreview` の `parts` | `parts` は `splitParts(for: frequency)` の戻り値。`frequency` は `max(2, min(5, ...))` でクランプ ✅ |

### 6-3. Force Unwrap

オンボーディング関連ファイルに `!` によるフォースアンラップは検出されなかった ✅。

### 6-4. Optional チェーン不足

```swift
// GoalMusclePreviewPage.swift:18-24
private var currentGoal: OnboardingGoal {
    guard let raw = AppState.shared.primaryOnboardingGoal,
          let goal = OnboardingGoal(rawValue: raw) else {
        return .getBig  // フォールバック
    }
    return goal
}
```

- `primaryOnboardingGoal` が `nil`（スワイプで GoalSelectionPage をスキップした場合）→ `.getBig` にフォールバック ✅
- RoutineCompletionPage も同様のフォールバック ✅

### 6-5. WeightInputPage 孤立ファイル

`WeightInputPage.swift` は存在するが、`OnboardingV2View.swift` からは参照されていない。`ProfileInputPage` に機能が統合されたため **デッドコード**。削除可能。

### 6-6. CallToActionPage 孤立ファイル

`CallToActionPage.swift` は存在するが、`OnboardingV2View.swift` からは参照されていない。`RoutineCompletionPage` に機能統合済みで **デッドコード**。削除可能。

---

## 7. ローカライゼーションギャップ

### 7-1. 英語翻訳なし（日本語ハードコード） ⚠️ HIGH

| ファイル | 行 | 内容 |
|:---|:---|:---|
| `GoalSelectionPage.swift` | 44-50 | `localizedDescription` — 全7項目が日本語のみ |
| `WeightInputPage.swift` | 46 | `"身長"` |
| `WeightInputPage.swift` | 69 | `"体重"` |
| `WeightInputPage.swift` | 126 | `"ニックネーム"` |
| `SplashView.swift` | 47 | `"鍛えた筋肉が光る。"` |
| `SplashView.swift` | 51 | `"あなたの体の変化を、目で見る。"` |
| `SplashView.swift` | 66 | `"始める"` |
| `CallToActionPage.swift` | 17-33,91-93 | 全コピーが日本語のみ（ただしデッドコード） |
| `GoalMusclePriority.swift` | 71-136 | `headline`, `reasons` — 全7パターンが日本語のみ |

### 7-2. 日本語のみの器具フィルタ ⚠️ HIGH

| ファイル | 行 | 内容 |
|:---|:---|:---|
| `GoalMusclePreviewPage.swift` | 220 | `["自重", "ダンベル", "ケトルベル"]` — 英語版なし |
| `RoutineBuilderPage.swift` | 471 | `["自重", "ダンベル", "ケトルベル"]` — 英語版なし |
| `RoutineBuilderPage.swift` | 702 | `["自重", "ダンベル", "ケトルベル"]` — 英語版なし |
| `LocationSelectionPage.swift` | 38-40 | `equipmentFilter` プロパティ — 日本語のみ（ただし現在は未使用） |

**LocationSelectionPage の `filteredExercises` と `totalFilteredCount`** では日英両方を含む `["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]` で正しく修正済み ✅。

**しかし GoalMusclePreviewPage と RoutineBuilderPage では日本語のみ** → exercises.json の `equipment` フィールドが英語の場合、自宅ユーザーのフィルタが0件になり、フォールバック（全種目表示 or 空配列）が発生する。

RoutineBuilderPage の `filterByLocation` は `filtered.isEmpty ? exercises : filtered`（:473）でフォールバックあり ✅（ただし意図しない種目が表示される）。
GoalMusclePreviewPage の `filterByLocation` にはフォールバックなし → **0件で表示が空になる可能性** ⚠️。

### 7-3. SplashView 完全未ローカライズ ⚠️ MEDIUM

SplashView の全テキスト（「鍛えた筋肉が光る。」「あなたの体の変化を、目で見る。」「始める」）に `isJapanese ?` 分岐がない。英語ユーザーに日本語が表示される。

---

## 8. その他の発見事項

### 8-1. TrainingHistoryPage.swift のファイル名

ファイル名は `TrainingHistoryPage.swift` だが、中身は `ProfileInputPage` 構造体。ファイル名と構造体名の不一致。

### 8-2. TrainingLocation.equipmentFilter（:36-42）未使用

`TrainingLocation.equipmentFilter` プロパティは定義されているが、どのファイルからも参照されていない。各ページが独自にフィルタ Set を定義している。共通化の余地あり。

### 8-3. RoutineDay.muscleGroups（:18）の型

`RoutineDay.muscleGroups` は `[String]`（rawValue 配列）。`MuscleGroup(rawValue:)` でデコードしているが、`exercises.json` の定義と `MuscleGroup` enum の整合性に依存する暗黙的な結合。

### 8-4. isProceeding フラグの Reset 漏れ

各ページの `isProceeding` フラグは `true` に設定後、`false` に戻す処理がない。ユーザーがスワイプで戻った場合、ボタンが押せなくなる。TabView の `.page` スタイルではスワイプ戻りが可能なため、**ボタン無反応になるリスクがある**。

対象ページ: GoalSelectionPage, FrequencySelectionPage, LocationSelectionPage, ProfileInputPage, PRInputPage, GoalMusclePreviewPage

---

## 重要度サマリー

| # | 重要度 | 概要 | 影響範囲 |
|:---|:---|:---|:---|
| 1 | 🔴 HIGH | `Set.first` 非決定性 → `primaryOnboardingGoal` がランダム | GoalMusclePreview, RoutineCompletion のコピー |
| 2 | 🔴 HIGH | `goalPriorityMuscles` トリプルライト → 複数目標の合算が単一目標に縮小 | RoutineBuilder の種目優先ソート |
| 3 | 🔴 HIGH | 器具フィルタ日本語ハードコード（GoalMusclePreview, RoutineBuilder） | 英語版の自宅ユーザーで種目が空/フォールバック |
| 4 | 🟡 MEDIUM | CLAUDE.md のページ構成が実コードと不一致（9→8ページ、WeightInputPage統合未反映） | 開発者の混乱 |
| 5 | 🟡 MEDIUM | SplashView 完全未ローカライズ | 英語ユーザーのファーストインプレッション |
| 6 | 🟡 MEDIUM | `OnboardingGoal.localizedDescription` 英語なし | 現在は UI で未使用だが将来リスク |
| 7 | 🟡 MEDIUM | `isProceeding` のリセット漏れ → スワイプ戻り時にボタン無反応 | 全オンボーディングページ |
| 8 | 🟡 MEDIUM | TabView スワイプでデータ保存スキップ可能 | 全ページ間遷移 |
| 9 | 🟢 LOW | デッドコード: WeightInputPage.swift, CallToActionPage.swift | コードベースの肥大化 |
| 10 | 🟢 LOW | TrainingHistoryPage.swift のファイル名不一致 | 保守性 |
| 11 | 🟢 LOW | LocationSelectionPage の autoScroll Timer（0.03s間隔） | 微小なパフォーマンスコスト |
| 12 | 🟢 LOW | GoalMusclePriority の headline/reasons 日本語のみ | GoalMusclePreviewPage では現在未使用 |

---

## 推奨アクション（優先順）

1. **`primaryOnboardingGoal` を最初に選択した目標に固定する** — `selectedGoals` を `[OnboardingGoal]` 配列（順序保持）に変更するか、選択時に最初の1つだけを別途保存する
2. **`OnboardingV2View:64-68` の `goalPriorityMuscles` 上書きを削除する** — GoalSelectionPage の合算保存を正とする
3. **器具フィルタを日英両対応にする** — LocationSelectionPage と同様に `["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]` に統一
4. **SplashView のローカライズ** — `isJapanese ?` 分岐を追加
5. **CLAUDE.md のオンボーディングセクションを現状に合わせて更新**
6. **`isProceeding` を `onAppear` で `false` にリセット**（スワイプ戻り対策）
7. **デッドコード削除** — WeightInputPage.swift, CallToActionPage.swift, FavoriteExercisesPage.swift
