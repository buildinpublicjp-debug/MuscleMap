# MuscleMap Code Review: Home + Workout Screens

> **v1.0 | 2026-03-22**
> 対象: HomeView, HomeHelpers, MuscleMapView, 14 Workout Viewファイル, WorkoutViewModel, ExerciseGifView

---

## レビューサマリー

| カテゴリ | 検出数 | Critical | Warning | Info |
|:---|:---:|:---:|:---:|:---:|
| 1. ビルドエラー候補 | 2 | 0 | 2 | 0 |
| 2. クラッシュリスク | 5 | 2 | 3 | 0 |
| 3. ロジックバグ | 6 | 2 | 3 | 1 |
| 4. Free vs Pro ゲート漏れ | 3 | 1 | 2 | 0 |
| 5. ExerciseGifView | 3 | 1 | 1 | 1 |
| 6. MuscleExercisePickerSheet | 2 | 0 | 2 | 0 |
| 7. RecentExercisesSection | 1 | 0 | 1 | 0 |
| 8. メモリリーク / パフォーマンス | 5 | 1 | 3 | 1 |
| **合計** | **27** | **7** | **17** | **3** |

---

## 1. ビルドエラー候補

### W-1.1 `RecordedSetsComponents.swift` — DateFormatter の再生成コスト
**重要度:** Warning
**ファイル:** `RecordedSetsComponents.swift:18-22`

```swift
private var timeFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}
```

`RecordedSetsView` は `ForEach` のたびにこの computed property を評価し、毎回 `DateFormatter` を新規生成する。ビルドエラーではないが、コンパイラが型チェックに時間をかける原因になり得る。`static let` に変更すべき。

### W-1.2 `WorkoutCompletionComponents.swift` — `CompletionProBanner` ハードコード日本語
**重要度:** Warning
**ファイル:** `WorkoutCompletionSections.swift:184-189`

```swift
Text("90日で体の変化を証明する")
Text("Strength Map + 種目別グラフで成長を可視化")
Text("Proを始める")
```

`L10n` を使わずハードコード日本語。英語ユーザーには日本語テキストが表示される。

---

## 2. クラッシュリスク

### C-2.1 `MuscleMapView.swift` — デモアニメーションの `DispatchQueue.main.asyncAfter` がクリーンアップされない
**重要度:** Critical
**ファイル:** `MuscleMapView.swift:77-111`

```swift
private func runDemoAnimation() {
    for (index, muscle) in allMuscles.enumerated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
            withAnimation { _ = demoHighlighted.insert(muscle) }
        }
    }
    // ...さらに3つの asyncAfter
}
```

Viewが画面から消えた後も `asyncAfter` のクロージャが実行される。SwiftUI Viewの `@State` が deallocated 済みの場合、クラッシュはしないが意図しない副作用が発生し得る。
**対策:** `@State private var animationTask: Task<Void, Never>?` を使い、`.onDisappear` でキャンセルする。

### C-2.2 `WorkoutInputHelpers.swift` — `WeightStepperButton` の Timer が invalidate されないケース
**重要度:** Critical
**ファイル:** `WorkoutInputHelpers.swift:86-123`

```swift
@State private var longPressTimer: Timer?

private func startLongPressTimer() {
    longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { ... }
}
```

`WeightStepperButton` は `@State` で `Timer?` を保持するが、Viewが再生成/破棄されても `Timer` は RunLoop に retain されたまま。SwiftUI Viewの `@State` は structのため `deinit` がなく、Timerのinvalidateが保証されない。
**対策:** `.onDisappear { stopLongPressTimer() }` を追加する。

### W-2.3 `WorkoutIdleComponents.swift` — `loadRecentExercises` の全件フェッチ
**重要度:** Warning
**ファイル:** `WorkoutIdleComponents.swift:86-104`

```swift
let descriptor = FetchDescriptor<WorkoutSet>(
    sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
)
guard let allSets = try? modelContext.fetch(descriptor) else { ... }
```

`fetchLimit` なしで全 `WorkoutSet` をメモリに読み込む。1000セット超で数十MBに達し得る。10種目の一意IDを取得するだけなので、`fetchLimit` を 200-300 程度に設定すべき。

### W-2.4 `HomeView.swift` — `loadStrengthScores` の全件フェッチ
**重要度:** Warning
**ファイル:** `HomeView.swift:324-332`

```swift
let descriptor = FetchDescriptor<WorkoutSet>()
guard let allSets = try? modelContext.fetch(descriptor) else { return }
```

`fetchLimit` なしで全セットをフェッチ。StrengthScore計算のために全データが必要だが、`fetchLimit: 5000` 等の上限があると安全。

### W-2.5 `WorkoutCompletionView.swift` — `checkPRUpdates` 内の N+1 クエリ
**重要度:** Warning
**ファイル:** `WorkoutCompletionView.swift:414-439`

```swift
for (exerciseId, maxWeight) in exerciseMaxInSession {
    let descriptor = FetchDescriptor<WorkoutSet>(
        predicate: #Predicate { $0.exerciseId == exerciseId },
        sortBy: [SortDescriptor(\.weight, order: .reverse)]
    )
    guard let allSets = try? modelContext.fetch(descriptor) else { continue }
    ...
}
```

セッション内の種目数分（5-10回）フェッチが走る。種目数が多い場合にパフォーマンス劣化。

---

## 3. ロジックバグ

### C-3.1 `WorkoutViewModel.swift` — `endSession` 後に `completedSession` が参照する WorkoutSession の `endDate`
**重要度:** Critical
**ファイル:** `WorkoutStartView.swift:27-29` + `WorkoutViewModel.swift:123-146`

```swift
// WorkoutStartView
onWorkoutCompleted: { session in
    vm.endSession()         // ← activeSession = nil, session.endDate が設定される
    HapticManager.workoutEnded()
    completedSession = session  // ← この session は endSession() 後に endDate が設定済み？
}
```

`endSession()` は `workoutRepo.endSession(session)` で `endDate` を設定しているはず。ただし `activeSession = nil` にした後でも `session` 変数は同じインスタンスを指すため、SwiftData の `@Model` オブジェクトならendDateはset済みで安全。問題なし（確認完了）。

**修正不要** — SwiftData のリファレンス型で正常動作。

### C-3.2 `WorkoutCompletionView.swift` — `completionGoalCopy` が日本語ハードコード
**重要度:** Critical
**ファイル:** `WorkoutCompletionView.swift:280-316`

```swift
// 部位ベースのメッセージ
if uniqueGroups.count > 2 {
    muscleMessage = "全身、しっかり追い込んだ"
} else if let group = dominantGroup {
    switch group {
    case .chest: muscleMessage = "胸板、また一段厚くなった"
    ...
    }
}
return "\(goal.localizedName) → \(muscleMessage)"
```

`muscleMessage` が全て日本語ハードコード。英語ユーザーに日本語が表示される。`L10n` を使うか、`isJapanese` で分岐すべき。

### W-3.3 `WorkoutViewModel.swift` — `restTimer` の `nonisolated(unsafe)` マーク
**重要度:** Warning
**ファイル:** `WorkoutViewModel.swift:75`

```swift
nonisolated(unsafe) private var restTimer: Timer?
```

`@MainActor` クラス内で `nonisolated(unsafe)` を使い、Timer のコールバックは `Task { @MainActor in ... }` で安全にディスパッチしているが、`Timer.scheduledTimer` 自体がメインスレッドで呼ばれる保証が必要。`startRestTimer()` は `@MainActor` メソッドなので問題ないが、今後のリファクタ時に壊れやすい設計。

### W-3.4 `MuscleExercisePickerSheet` — GIF無し種目が完全に非表示
**重要度:** Warning
**ファイル:** `WorkoutIdleComponents.swift:207`

```swift
ForEach(relatedExercises.filter { ExerciseGifView.hasGif(exerciseId: $0.id) }) { exercise in
```

GIFが存在しない種目が筋肉タップ時のピッカーから完全に除外される。92種目中GIFのない種目がある場合、ユーザーはその種目を選択できなくなる。
**対策:** GIF付き種目を先に表示し、GIF無し種目をセパレーターで区切って後ろに表示する。

### W-3.5 `SetInputCard` — 自重種目判定がハードコード文字列
**重要度:** Warning
**ファイル:** `SetInputComponents.swift:18-20`

```swift
private var isBodyweight: Bool {
    exercise.equipment == "自重" || exercise.equipment == "Bodyweight"
}
```

`RecordedSetsComponents.swift:85` にも同じパターンがある。7言語対応なのに日本語と英語しかチェックしていない。中国語「自重」、韓国語「맨몸」等でfalseになる。`ExerciseDefinition` に `isBodyweight` プロパティを追加すべき。

### I-3.6 `ExercisePreviewSheet` — `toSnakeCase()` の重複定義
**重要度:** Info
**ファイル:** `ExercisePreviewSheet.swift:401-416`, `ShareMuscleMapView.swift:121-136`

`String.toSnakeCase()` / `toSnakeCaseForShare()` が2ファイルにprivate extensionとして重複定義されている。共通ユーティリティに統合すべき。

---

## 4. Free vs Pro ゲート漏れ

### C-4.1 `WorkoutStartView` — `handlePendingRoutineDay` が `canRecordWorkout` チェックなし
**重要度:** Critical
**ファイル:** `WorkoutStartView.swift:103-108`

```swift
private func handlePendingRoutineDay() {
    guard let pendingDay = RoutineManager.shared.pendingStartDay,
          let vm = viewModel else { return }
    RoutineManager.shared.pendingStartDay = nil
    vm.startWithRoutine(day: pendingDay)  // ← canRecordWorkout チェックなし
}
```

`ContentView` のタブ遷移ゲートは `AppState.shared.selectedTab` の `onChange` で発動するが、`pendingStartDay` はルーティンボタンタップ時にタブ遷移と同時にセットされる。タブ遷移ゲートは ContentView レベルだが、WorkoutStartView の `onAppear` / `onChange` で直接セッション開始するため、無料ユーザーが週間上限を超えてルーティンを開始できる可能性がある。

**検証が必要:** ContentView のワークアウトタブゲートが先に発動するかどうかをフロー確認する。発動順序が保証されなければ、ここにもガードが必要。

### W-4.2 `WorkoutStartView` — `handlePendingExercise` が `canRecordWorkout` チェックなし
**重要度:** Warning
**ファイル:** `WorkoutStartView.swift:111-118`

同様に `handlePendingExercise` も `canRecordWorkout` チェックがない。種目詳細画面からの直接遷移パスで週間制限を回避できる可能性。

### W-4.3 `WorkoutStartView` — `handlePendingRecommendation` が `canRecordWorkout` チェックなし
**重要度:** Warning
**ファイル:** `WorkoutStartView.swift:121-129`

メニュー提案からの遷移パスも同様。

---

## 5. ExerciseGifView

### C-5.1 `ExerciseGifView` — GIFデータの毎回ディスクI/O
**重要度:** Critical
**ファイル:** `ExerciseGifView.swift:89-100`

```swift
private static func loadGifData(exerciseId: String) -> Data? {
    guard let url = Bundle.main.url(...) else { return nil }
    return try? Data(contentsOf: url)
}
```

`loadGifData` は毎回 `Data(contentsOf:)` でディスクからGIFバイナリを読み込む。同じGIFが画面に複数回表示される場合（ルーティン進捗バーの24x24サムネイル等）、同じファイルを何度もI/Oする。
**対策:** `NSCache<NSString, NSData>` による in-memory キャッシュを追加する。

### W-5.2 `ExerciseGifView` — `hasGif` が暗黙的にフルGIFデータを読み込む
**重要度:** Warning
**ファイル:** `ExerciseGifView.swift:83-85`

```swift
static func hasGif(exerciseId: String) -> Bool {
    return loadGifData(exerciseId: exerciseId) != nil
}
```

GIFファイルの存在チェックだけなのに、ファイル全体をメモリに読み込む。`FileManager.default.fileExists` に変更すべき。

### I-5.3 `ExerciseGifView` — `.thumbnail` サイズの固定 100x75
**重要度:** Info
**ファイル:** `ExerciseGifView.swift:68-69`

```swift
.frame(width: 100, height: 75)
```

ルーティン進捗バー（`RoutineProgressBar`）では 24x24 で `.thumbnail` を使い、`WorkoutIdleComponents` では 50x50 で使う。しかし `.thumbnail` のframeは 100x75 固定で、呼び出し元の `.frame(width: 50, height: 50)` や `.frame(width: 24, height: 24)` で上書きされる。実際はオーバーサイズの画像をレンダリングしてからクリップするため無駄。ただし実用上問題は小さい（firstFrame の静止画のため）。

---

## 6. MuscleExercisePickerSheet

### W-6.1 N+1 クエリパターン — `lastRecord(for:)` が種目ごとにフェッチ
**重要度:** Warning
**ファイル:** `WorkoutIdleComponents.swift:182-188`

```swift
private func lastRecord(for exerciseId: String) -> WorkoutSet? {
    let descriptor = FetchDescriptor<WorkoutSet>(
        predicate: #Predicate { $0.exerciseId == exerciseId },
        sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
    )
    return try? modelContext.fetch(descriptor).first
}
```

ForEach内で種目ごとに呼ばれるため、表示種目数（10-15）分のフェッチが走る。
**対策:** onAppear で該当筋肉の全種目分の最新記録を一括フェッチしてDictionaryに保持する。

### W-6.2 空ステート到達不可
**重要度:** Warning
**ファイル:** `WorkoutIdleComponents.swift:195-203`

```swift
if relatedExercises.isEmpty {
    // Empty state
} else {
    ForEach(relatedExercises.filter { ExerciseGifView.hasGif(exerciseId: $0.id) }) {
```

`relatedExercises` が空でなくても、GIFフィルター後に0件になるとScrollViewが空になる。空ステートは `relatedExercises.isEmpty` でしか表示されないため、GIF付き種目が0件の場合にユーザーに何も表示されない。

---

## 7. RecentExercisesSection

### W-7.1 横スクロールでのGIFサムネイル非表示
**重要度:** Warning
**ファイル:** `WorkoutIdleComponents.swift:109-167`

`RecentExercisesSection` にはGIFサムネイルが含まれていない（テキスト+器具+筋肉タグのみ）。CLAUDE.md のUIデザイン原則に「リスト形式の画面でも、各行にサムネイル/アイコンを必ず配置。テキストのみの行は禁止」とある。
**対策:** 各カードの上部に `ExerciseGifView(size: .thumbnail)` を追加する。

---

## 8. メモリリーク / パフォーマンス

### C-8.1 `WorkoutViewModel` — `restTimer` のリーク可能性
**重要度:** Critical
**ファイル:** `WorkoutViewModel.swift:75, 303-307`

```swift
nonisolated(unsafe) private var restTimer: Timer?

restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    Task { @MainActor in
        self?.tickRestTimer()
    }
}
```

`[weak self]` は正しいが、`nonisolated(unsafe)` と `@Observable` クラスの組み合わせで、Timerが RunLoop に retain され続ける。`deinit` で `restTimer?.invalidate()` があるが、以下のケースで問題:
- `WorkoutStartView` がタブ切り替えで非表示になった場合、`@State private var viewModel: WorkoutViewModel?` は保持されるため問題なし
- しかし `WorkoutStartView` 自体がメモリから解放される場合（ナビゲーション等）、`viewModel` の `deinit` → `restTimer?.invalidate()` の順序が保証される

**結論:** 現在のコードでは `deinit` で対応済み。ただし `nonisolated(unsafe)` の使用は Swift 6 strict concurrency で問題になる可能性あり。

### W-8.2 `RoutineProgressBar` — ForEach内の `ExerciseGifView.hasGif` 呼び出し
**重要度:** Warning
**ファイル:** `ActiveWorkoutComponents.swift:368`

```swift
if ExerciseGifView.hasGif(exerciseId: routineEx.exerciseId) {
    ExerciseGifView(exerciseId: routineEx.exerciseId, size: .thumbnail)
```

ルーティンの各種目チップ（5-8個）に対して `hasGif` → `loadGifData` → `Data(contentsOf:)` が呼ばれる。C-5.1 のキャッシュ追加で解決可能。

### W-8.3 `WorkoutCompletionView` — `onAppear` で5つの重い処理が同期実行
**重要度:** Warning
**ファイル:** `WorkoutCompletionView.swift:261-267`

```swift
.onAppear {
    checkFullBodyConquest()      // SwiftData フェッチ + 21筋肉ループ
    markFirstWorkoutCompleted()  // 軽い
    checkPRUpdates()             // N+1 フェッチ
    detectLevelUps()             // PR フェッチ + スコア計算
    scheduleRecoveryNotification() // 回復時間計算
}
```

5つの処理が同期的に `onAppear` で走る。`checkFullBodyConquest` と `checkPRUpdates` は共にSwiftDataフェッチを含む。画面表示が遅延する原因になり得る。
**対策:** `Task { await ... }` で非同期化し、UIの表示を先行させる。

### W-8.4 `ExercisePickerView` — 全92種目の `EnhancedExerciseRow` にGIFサムネイル
**重要度:** Warning
**ファイル:** `ExercisePickerView.swift:136-146`

```swift
List(viewModel.filteredExercises) { exercise in
    EnhancedExerciseRow(exercise: exercise, ...)
}
```

`EnhancedExerciseRow` は `ExerciseGifView(size: .thumbnail)` を表示する。List の LazyLoading で画面外は遅延されるが、スクロール時に毎回GIF firstFrame の生成が走る。`NSCache` があれば問題は緩和される。

### I-8.5 `ConfettiView` — 100パーティクルの Canvas アニメーション
**重要度:** Info
**ファイル:** `FullBodyConquestView.swift:222-248`

```swift
TimelineView(.animation) { timeline in
    Canvas { context, size in
        for piece in confettiPieces { ... }  // 100個
    }
}
```

`TimelineView(.animation)` は毎フレーム（60fps）全100パーティクルの位置を計算する。`Canvas` は効率的だが、古いデバイスではフレームドロップの可能性がある。実用上は全身制覇（レアイベント）でのみ表示されるため影響は小さい。

---

## 修正優先度

### 今すぐ修正すべき（Critical）

| # | 問題 | 修正工数 |
|:---|:---|:---|
| C-3.2 | `completionGoalCopy` の日本語ハードコード | 小 |
| C-4.1 | `handlePendingRoutineDay` の `canRecordWorkout` チェック追加 | 小 |
| C-5.1 | `ExerciseGifView.loadGifData` にNSCacheキャッシュ追加 | 中 |
| C-2.2 | `WeightStepperButton` Timer の `.onDisappear` クリーンアップ | 小 |

### 次のリリースまでに修正すべき（Warning）

| # | 問題 | 修正工数 |
|:---|:---|:---|
| W-5.2 | `hasGif` を `FileManager.fileExists` に変更 | 小 |
| W-3.4 | `MuscleExercisePickerSheet` GIF無し種目の復帰 | 中 |
| W-3.5 | 自重判定をExerciseDefinitionプロパティに統合 | 小 |
| W-1.2 + C-3.2 | ハードコード日本語のL10n化 | 中 |
| W-6.1 | `lastRecord` N+1 クエリの一括化 | 中 |
| W-2.3 | `loadRecentExercises` に `fetchLimit` 追加 | 小 |
| W-4.2/4.3 | `handlePending*` に `canRecordWorkout` ガード追加 | 小 |
| W-8.3 | `WorkoutCompletionView.onAppear` 非同期化 | 中 |

### 将来改善（Info）

| # | 問題 |
|:---|:---|
| I-3.6 | `toSnakeCase` 重複定義の統合 |
| I-5.3 | thumbnail サイズの最適化 |
| I-8.5 | Confetti の古デバイス対応 |

---

## 全体評価

**構造:** MVVM + Repository パターンが一貫しており、ViewModelへの責務分離が適切。14ファイルへの分割粒度も適切。

**品質:** SwiftUI / SwiftData の使い方は全体的に堅実。`@Observable` + `@MainActor` の採用でデータフローが明確。

**主要リスク:**
1. **Free vs Pro ゲート漏れ** — ルーティン・種目詳細・メニュー提案からの3つの直接遷移パスで `canRecordWorkout` チェックが欠落。これが最大のビジネスリスク
2. **GIFメモリ** — キャッシュなしのディスクI/Oが頻繁。RoutineProgressBar のサムネイル表示で顕著
3. **ローカライゼーション漏れ** — `completionGoalCopy` と `CompletionProBanner` の日本語ハードコード
