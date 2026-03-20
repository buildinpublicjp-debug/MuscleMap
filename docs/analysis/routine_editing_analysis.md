# ルーティン管理 + HomeView編集導線 分析レポート

> Wave 7 事前分析 — CC-C
> 作成日: 2026-03-20

---

## 1. RoutineManager.swift 完全分析

**ファイル:** `MuscleMap/Data/RoutineManager.swift` (72行)

### クラス定義
```swift
@MainActor @Observable
class RoutineManager {
    static let shared = RoutineManager()
}
```

### Public API一覧

| メソッド/プロパティ | 型 | 説明 |
|:---|:---|:---|
| `shared` | `RoutineManager` (static) | シングルトン |
| `routine` | `UserRoutine` (private(set)) | 現在のルーティン（読み取り専用） |
| `hasRoutine` | `Bool` (computed) | `!routine.days.isEmpty` |
| `saveRoutine(_ routine:)` | `func` | ルーティン全体を上書き保存 |
| `todayRoutineDay(modelContext:)` | `func → RoutineDay?` | 直近セッションから次のDayを判定 |
| `reload()` | `func` | UserDefaultsから再読み込み |

### データ保存形式
- **UserDefaults** にJSON形式で保存
- キー: `"userRoutine"`
- `JSONEncoder`/`JSONDecoder` で `UserRoutine` をシリアライズ
- **SwiftDataではない**（`@Model`なし）

### saveRoutine() の処理フロー
```
saveRoutine(routine) →
  1. self.routine = routine  (メモリ更新)
  2. routine.save()          (UserDefaults書き込み)
```

### 個別種目の追加/削除/差替えAPI
**存在しない。** 現在は `saveRoutine()` で `UserRoutine` 全体を上書きするのみ。
個別操作は呼び出し側（RoutineEditView）で `days` 配列を直接操作し、最後に全体保存。

---

## 2. UserRoutine.swift 完全分析

**ファイル:** `MuscleMap/Models/UserRoutine.swift` (87行)

### データモデル階層

```
UserRoutine (struct, Codable)
├── days: [RoutineDay]
└── createdAt: Date

RoutineDay (struct, Codable, Identifiable)
├── id: UUID
├── name: String                  // "Day 1: 胸・三頭" 等
├── muscleGroups: [String]        // ["chest", "triceps"]
├── exercises: [RoutineExercise]
└── location: String              // "gym" / "home" / "both" / "bodyweight"

RoutineExercise (struct, Codable, Identifiable)
├── id: UUID
├── exerciseId: String            // exercises.json の id
├── suggestedSets: Int            // デフォルト 3
└── suggestedReps: Int            // デフォルト 10
```

### 重要な特性
- **SwiftDataの@Modelではない** — 純粋なCodable struct
- `RoutineDay.location` は `decodeIfPresent` で後方互換対応
- `UserRoutine.default` = 空配列（`days: []`）
- 全プロパティが `var`（ミュータブル）→ 呼び出し側で直接変更可能

---

## 3. HomeView のルーティン表示ロジック

### データ取得フロー
```
HomeView.onAppear
  → viewModel = HomeViewModel(modelContext:)
  → viewModel.loadTodayRoutine()
    → RoutineManager.shared.todayRoutineDay(modelContext:)
      → 直近セッションの種目IDとルーティン各Dayを照合
      → bestIndex（最も重複する日）の次の日を返す
  → vm.todayRoutine に RoutineDay? が格納
```

### 表示コンポーネント
`HomeView` → `TodayRecommendationInline`（HomeHelpers.swift内）

### TodayRecommendationInline の分岐ロジック
```
if todayRoutine != nil && exercises非空
  → routineCard()          ★ ← ここが長押し対象
elif hasRoutine
  → restDayCard            （種目なし = 休息日）
elif !hasWorkoutHistory && recommendation
  → firstTimeRecommendationCard()
elif hasWorkoutHistory && suggestedMenu
  → proRecommendationCard() / freeRecommendationCard()
else
  → noRoutineCard          （ルーティン未設定）
```

### routineCard() の実装詳細（HomeHelpers.swift:187-394）

**State変数:**
- `@State private var selectedDayIndex: Int?` — Dayタブ選択
- `@State private var selectedExerciseDefinition: ExerciseDefinition?` — 種目詳細シート

**Dayタブ:**
- `todayDayIndex`: todayRoutineのidで全daysを検索してindex取得
- `currentDayIndex`: selectedDayIndex ?? todayDayIndex
- `displayDay`: allDays[currentDayIndex]

**種目グリッド（2カラム）:**
```swift
LazyVGrid(columns: gridColumns, spacing: 8) {
    ForEach(displayDay.exercises) { exercise in
        Button { selectedExerciseDefinition = def } label: {
            ZStack(alignment: .bottom) {
                // GIF背景（GeometryReader + scaledToFill + clipped）
                // グラデーション（56pt）
                // 種目名（左）+ セット×レップ（右）
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
```

**現在のインタラクション:**
- タップ → `selectedExerciseDefinition` → `.sheet(item:)` → `ExerciseDetailView`
- Dayタブ切替 → `selectedDayIndex` 変更
- 「ルーティンを開始する」ボタン → ワークアウトタブへ遷移
- **長押し/スワイプ/contextMenu: 未実装**

---

## 4. HomeViewModel のルーティン関連

**ファイル:** `MuscleMap/ViewModels/HomeViewModel.swift`

| メソッド | 説明 |
|:---|:---|
| `todayRoutine: RoutineDay?` | 今日のルーティン日（State） |
| `hasRoutine: Bool` | `RoutineManager.shared.hasRoutine` |
| `loadTodayRoutine()` | `RoutineManager.shared.todayRoutineDay()` を呼んで格納 |
| `previousWeight(for:)` | 種目の前回重量を取得 |

**refreshメソッド:** 明示的なrefreshはない。`loadTodayRoutine()` を再呼出すれば更新される。

---

## 5. ContextMenu/長押し実装の可能性分析

### SwiftUI `.contextMenu` でできること
```swift
.contextMenu {
    Button { /* 差替え */ } label: { Label("種目を変更", systemImage: "arrow.left.arrow.right") }
    Button(role: .destructive) { /* 削除 */ } label: { Label("削除", systemImage: "trash") }
}
```

- iOS 16+で安定、プレビュー付きハプティクス自動
- カードのButton内に配置可能（`.contextMenu`はButtonの外に付ける）
- `role: .destructive` で赤文字表示

### 「種目を変更」フロー設計
```
ユーザーが種目カードを長押し
  → contextMenu表示
  → 「種目を変更」タップ
  → State: showingReplaceSheet = true, replacingExercise = RoutineExercise
  → .sheet表示: ミニExercisePicker（RoutineEditExercisePickerSheet流用可）
  → ユーザーが新種目選択
  → RoutineManager.shared の routine を更新:
      1. days[currentDayIndex].exercises で replacingExercise.id を探す
      2. exerciseId を新種目のidに差替え
      3. RoutineManager.shared.saveRoutine(updatedRoutine)
  → withAnimation で UI 反映
  → HomeViewModel.loadTodayRoutine() で todayRoutine 再読み込み
```

### 「削除」フロー設計
```
ユーザーが種目カードを長押し
  → contextMenu表示
  → 「削除」タップ
  → 確認不要（contextMenuのdestructiveで十分明確）
  → RoutineManager.shared の routine を更新:
      1. days[currentDayIndex].exercises から該当idを remove
      2. RoutineManager.shared.saveRoutine(updatedRoutine)
  → withAnimation(.easeInOut) で UI 反映
```

### アニメーション配置
```swift
// 差替え時
withAnimation(.easeInOut(duration: 0.3)) {
    // routine更新後に todayRoutine を再代入
}

// 削除時
withAnimation(.easeInOut(duration: 0.3)) {
    // exercises.removeAll(where:) 後に再代入
}
```

### TabViewとの競合リスク
- **なし。** routineCardはHomeView内のScrollView内にあり、TabViewのスワイプとは別レイヤー
- `.contextMenu` は長押しトリガーなので横スワイプと競合しない

---

## 6. RoutineManager改修案

### 追加メソッド案

```swift
// RoutineManager.swift に追加

/// 種目を差替え
func replaceExercise(dayIndex: Int, exerciseIndex: Int, newExerciseId: String) {
    guard routine.days.indices.contains(dayIndex),
          routine.days[dayIndex].exercises.indices.contains(exerciseIndex) else { return }
    var updated = routine
    updated.days[dayIndex].exercises[exerciseIndex].exerciseId = newExerciseId
    saveRoutine(updated)
}

/// 種目を削除
func removeExercise(dayIndex: Int, exerciseIndex: Int) {
    guard routine.days.indices.contains(dayIndex),
          routine.days[dayIndex].exercises.indices.contains(exerciseIndex) else { return }
    var updated = routine
    updated.days[dayIndex].exercises.remove(at: exerciseIndex)
    saveRoutine(updated)
}

/// 種目を追加
func addExercise(dayIndex: Int, exerciseId: String, sets: Int = 3, reps: Int = 10) {
    guard routine.days.indices.contains(dayIndex) else { return }
    var updated = routine
    updated.days[dayIndex].exercises.append(
        RoutineExercise(exerciseId: exerciseId, suggestedSets: sets, suggestedReps: reps)
    )
    saveRoutine(updated)
}
```

### データ永続化の更新フロー
```
replaceExercise/removeExercise/addExercise
  → var updated = routine    (コピー作成)
  → updated を変更           (struct なので安全にコピー変更)
  → saveRoutine(updated)
    → self.routine = updated  (メモリ更新 → @Observable で UI 自動反映)
    → updated.save()          (UserDefaults 永続化)
```

### HomeView側の反映
`RoutineManager.shared` が `@Observable` なので、`routine` プロパティの変更は自動的にViewに伝播する。
ただし `TodayRecommendationInline` は `todayRoutine: RoutineDay?` をパラメータで受け取っているため、
`HomeViewModel.loadTodayRoutine()` を再呼出して `todayRoutine` を更新する必要がある。

**推奨パターン:**
```swift
// TodayRecommendationInline 内
private func refreshRoutine() {
    // RoutineManager.shared.routine は既に更新済み
    // todayRoutineの再計算をトリガー（HomeViewModel経由）
}
```

または、`TodayRecommendationInline` が直接 `RoutineManager.shared.routine.days[currentDayIndex]` を
参照する形に変更すれば、`@Observable` の自動更新で即座に反映される。

---

## 7. 既存の RoutineEditView パターン参照

**ファイル:** `MuscleMap/Views/Settings/RoutineEditView.swift` (571行)

### 現在の編集パターン
- `@State private var days: [RoutineDay]` にコピーして編集
- 追加: `RoutineEditExercisePickerSheet` → `onAdd` callback
- 削除: `.onDelete` (IndexSet)
- 並べ替え: `.onMove`
- セット/レップ編集: `RoutineExerciseEditSheet`
- 保存: `saveRoutine()` → `RoutineManager.shared.saveRoutine(UserRoutine(days:, createdAt:))`

### 流用可能なコンポーネント
- `RoutineEditExercisePickerSheet`: 種目選択UI（検索バー + muscleGroup ベースフィルタ）
  → **長押し「種目を変更」のピッカーとしてそのまま流用可能**
  → ただし `private struct` なので、流用するには `internal` に変更 or 別ファイルに移動が必要

---

## 8. 実装チェックリスト（CC-C用）

### RoutineManager.swift
- [ ] `replaceExercise(dayIndex:exerciseIndex:newExerciseId:)` 追加
- [ ] `removeExercise(dayIndex:exerciseIndex:)` 追加
- [ ] `addExercise(dayIndex:exerciseId:sets:reps:)` 追加

### HomeHelpers.swift (TodayRecommendationInline)
- [ ] `@State private var showingReplaceSheet = false`
- [ ] `@State private var replacingExerciseIndex: Int?`
- [ ] 種目カードに `.contextMenu` 追加（変更 / 削除）
- [ ] 「種目を変更」→ ピッカーシート表示
- [ ] 「削除」→ `withAnimation` + RoutineManager更新
- [ ] RoutineEditExercisePickerSheet の再利用 or 新ミニピッカー

### UI更新
- [ ] 変更/削除後に `todayRoutine` を再代入（表示更新）
- [ ] `withAnimation` でスムーズなカード遷移

### テスト項目
- [ ] 長押しでcontextMenu表示
- [ ] 種目変更 → GIF・名前が即座に更新
- [ ] 種目削除 → カードがアニメーション付きで消える
- [ ] アプリ再起動後も変更が保持されている
- [ ] Day切替後も正しいDay内容が表示される
