# CC-B: 種目選択UI 全箇所比較分析

> 分析日: 2026-03-20
> 目的: 統一ExercisePickerを設計するための基礎データ収集

---

## 1. 種目選択/表示がある全画面

アプリ内で `ExerciseDefinition` を参照し、種目を一覧表示またはピッキングしている画面は **8箇所** ある。

| # | 画面名 | ファイル | 行数 | 役割 |
|---|---|---|---|---|
| 1 | 種目辞典タブ | `Views/Exercise/ExerciseDictionaryView.swift` | 289 | メインタブの種目ブラウザ |
| 2 | ワークアウト種目追加 | `Views/Workout/ExercisePickerView.swift` | 371 | ワークアウト中に種目を追加（シート） |
| 3 | オンボーディング ルーティンビルダー | `Views/Onboarding/RoutineBuilderPage.swift` | 876 | Day別種目グリッド + 編集 |
| 4 | オンボーディング 種目追加シート | `RoutineBuilderPage.swift` 内 `RoutineExercisePickerSheet` | (上記に含む) | ルーティンへの種目追加 |
| 5 | 種目プレビュー | `Views/Workout/ExercisePreviewSheet.swift` | 443 | ExercisePickerからの詳細確認 |
| 6 | ホーム ルーティンカード | `Views/Home/HomeHelpers.swift` (`TodayRecommendationInline`) | 938 | 今日のDay種目をGIFグリッド表示 |
| 7 | メニュープレビュー | `Views/Home/MenuPreviewSheet.swift` | 325 | おすすめメニューの種目リスト |
| 8 | 種目詳細 | `Views/Exercise/ExerciseDetailView.swift` | 373 | 個別種目の全情報表示 |

**参考（種目一覧は表示しないが関連）:**
- `LocationSelectionPage.swift` (466行) — GIF自動スクロールギャラリー（フィルタ済み種目の視覚デモ、選択機能なし）
- `GoalMusclePreviewPage.swift` (349行) — 分割法プレビュー（種目は表示せず筋肉グループのみ）
- `ExerciseListViewModel.swift` (125行) — ExercisePickerViewのフィルタリングロジック

---

## 2. 各画面の比較テーブル

| 画面 | 表示形式 | 選択可能? | GIF表示 | フィルタ数 | 筋肉マップ | 検索 | お気に入り | カラーパレット |
|---|---|---|---|---|---|---|---|---|
| 種目辞典 | 2カラム LazyVGrid | 詳細表示のみ | `.card` (静止画) | 2段（部位+器具） | あり（200pt, タップ=フィルタ） | なし | あり（器具段） | メイン（mmBg/mmAccent） |
| ワークアウト追加 | List + EnhancedExerciseRow | はい（種目追加） | `.thumbnail` (静止画) | 5種（最近/★/全/カテゴリ/器具） | なし | `.searchable` | あり | メイン |
| ルーティンビルダー | 2カラム LazyVGrid | 詳細表示+編集 | `.card` (静止画) | location（ジム/自宅） | あり（100pt） | なし | なし | オンボーディング（mmOnboarding*） |
| ルーティン種目追加 | LazyVStack リスト | はい（種目追加） | `.thumbnail` (静止画) | 検索のみ | なし | TextField | なし | オンボーディング |
| 種目プレビュー | 単一種目詳細 | 追加ボタン（任意） | `.previewCard` (アニメ) | なし | あり（PreviewMuscleMap） | なし | なし | メイン |
| ホームルーティンカード | 2カラム LazyVGrid | 詳細表示のみ | `.card` (静止画) | なし | なし | なし | なし | メイン |
| メニュープレビュー | 縦リスト（HStack） | なし（表示のみ） | `.thumbnail` (静止画) | なし | あり（MiniMuscleMap） | なし | なし | メイン |
| 種目詳細 | 単一種目全情報 | ワークアウト開始 | `.fullWidth` (アニメ) | なし | あり（ExerciseMuscleMap） | なし | あり（ツールバー） | メイン |

---

## 3. フィルタリングロジックの差分

### 3-A. ExerciseDictionaryView（種目辞典）

```swift
// 2段フィルター: MuscleGroup + Equipment/Favorites
var result = ExerciseStore.shared.exercises

// 1段目: 部位グループ
if let group = selectedMuscleGroup {
    let musclesInGroup = Set(Muscle.allCases.filter { $0.group == group }.map(\.rawValue))
    result = result.filter { exercise in
        exercise.muscleMapping.keys.contains(where: { musclesInGroup.contains($0) })
    }
}
// 2段目: 器具 or お気に入り
if let equip = selectedEquipment {
    if equip == "⭐" {
        result = result.filter { FavoritesManager.shared.isFavorite($0.id) }
    } else {
        result = result.filter { $0.equipment == equip }
    }
}
```

**特徴:** 筋肉マップタップ→MuscleGroupフィルタ連動。テキスト検索なし。

### 3-B. ExercisePickerView（ワークアウト追加）→ ExerciseListViewModel

```swift
// ViewModel側で5種のフィルタを排他的に適用
// 1. showRecentOnly → RecentExercisesManager.getRecentIds()順
// 2. showFavoritesOnly → FavoritesManager.shared.favoriteIds
// 3. selectedCategory → exercise.category == category
// 4. selectedEquipment → exercise.equipment == equipment
// 5. searchText → nameJA/nameEN/equipment の部分一致
```

**特徴:** 最も多機能。ViewModelに分離。カテゴリ（`exercise.category`）ベースと器具ベースの両方。最近使った種目の順序保持。

### 3-C. RoutineBuilderPage（オンボーディング）

```swift
// 自動ピック: MuscleGroup → 種目候補 → location フィルタ → 優先度ソート
// locationフィルタ:
if location == "home" {
    let homeEquipment: Set<String> = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
    result = exercises.filter { homeEquipment.contains($0.equipment) }
}
// 優先度ソート: お気に入り > グループ関連度 > 重点筋肉スコア
```

**特徴:** 自動選択ロジックが重い。ユーザーのフィルタUIは location切替（ジム/自宅）のみ。

### 3-D. RoutineExercisePickerSheet（オンボーディング追加シート）

```swift
// Day の muscleGroups に属する種目のみ表示
// + Day の location でフィルタ
// + テキスト検索（localizedName / nameEN の部分一致）
let groups = day.muscleGroups.compactMap { MuscleGroup(rawValue: $0) }
// → group.muscles → exercises(targeting: muscle) → primaryMuscle.group in targetGroupSet
// → location == "home" → homeEquipment フィルタ
```

**特徴:** RoutineBuilderのフィルタロジックとほぼ同じだが独立して再実装。

### 3-E. LocationSelectionPage（オンボーディング GIFギャラリー）

```swift
// TrainingLocation に応じて器具フィルタ
case .bodyweight: bwEquipment = ["自重", "Bodyweight"] + isTrueBodyweight チェック
case .home: homeEquipment = ["自重", "ダンベル", "ケトルベル", "Bodyweight", "Dumbbell", "Kettlebell"]
case .gym, .both: gymExcludeIds で burpee を除外
// 最大20件 prefix
```

**特徴:** `TrainingLocation` enum のフィルタが独立定義。RoutineBuilderの `filterByLocation` と重複。

---

## 4. GIF表示の差分

### ExerciseGifSize enum（共通コンポーネント）

| サイズ | アニメーション | デフォルト寸法 | 用途 |
|---|---|---|---|
| `.fullWidth` | あり（AspectFit） | maxHeight: 300 | ExerciseDetailView |
| `.previewCard` | あり（AspectFill） | height: 120 | ExercisePreviewSheet |
| `.card` | なし（静止画1フレーム） | 呼び出し元指定 | グリッド系全般 |
| `.thumbnail` | なし（静止画1フレーム） | 100x75 固定 | リスト行 |

### 各画面のGIF利用パターン

| 画面 | サイズ | scaledToFill/Fit | オーバーレイ | 追加処理 |
|---|---|---|---|---|
| 種目辞典 | `.card` + `.scaledToFill()` | Fill | `LinearGradient(.black 0.75)` + 種目名 + 筋肉チップ + 器具 | `aspectRatio(1)`, `cornerRadius(12)` |
| ワークアウト追加 | `.thumbnail` | (デフォルト) | なし | 56x56 frame, `cornerRadius(8)`, fallback: MiniMuscleMapView |
| ルーティンビルダー | `.card` + `GeometryReader` | Fill + `frame(w,h)` + `.clipped()` | `LinearGradient(.black 0.75, 56pt)` + 種目名 + セット×レップバッジ + 削除ボタン | `aspectRatio(1)`, `cornerRadius(10)` |
| ルーティン追加シート | `.thumbnail` | (デフォルト) | なし | 40x40 frame, `cornerRadius(8)` |
| 種目プレビュー | `.previewCard` | (コンポーネント内Fill) | なし（横並びで筋肉マップ） | height: 120 |
| ホームルーティンカード | `.card` + `GeometryReader` | Fill + `frame(w,h)` + `.clipped()` | `LinearGradient(.black 0.75, 56pt)` + 種目名 + セット×レップ | `aspectRatio(1)`, `cornerRadius(8)` |
| メニュープレビュー | `.thumbnail` | (デフォルト) | なし | 80x80 frame, `cornerRadius(8)` |
| 種目詳細 | `.fullWidth` | (コンポーネント内Fit) | なし | `cornerRadius(12)`, border overlay |
| 場所選択ギャラリー | `.card` (130x130) | (デフォルト) | なし | 種目名+器具テキスト下 |

### GIFオーバーレイの3パターン

**パターンA: グラデーション+テキスト重ね（2カラムグリッド用）**
使用箇所: 種目辞典, ルーティンビルダー, ホームルーティンカード

```swift
ZStack(alignment: .bottom) {
    // GIF (card, scaledToFill)
    LinearGradient(colors: [.clear, Color.black.opacity(0.75)], ...)
        .frame(height: 56)
    HStack { Text(name); Spacer(); Text(sets×reps) }
        .padding(.horizontal, 8).padding(.bottom, 6)
}
.aspectRatio(1, contentMode: .fit)
.clipShape(RoundedRectangle(cornerRadius: N))
```

微差:
- 種目辞典: cornerRadius 12, 筋肉チップ+器具テキスト付き, `.scaledToFill()` 直接
- ルーティンビルダー: cornerRadius 10, セット×レップバッジ+削除ボタン, GeometryReader wrap
- ホームカード: cornerRadius 8, セット×レップ, GeometryReader wrap

**パターンB: サムネイル（リスト行用）**
使用箇所: ワークアウト追加, ルーティン追加シート, メニュープレビュー

サイズが 56x56, 40x40, 80x80 とバラバラ。

**パターンC: 専用表示**
使用箇所: 種目詳細（fullWidth）, 種目プレビュー（previewCard）

---

## 5. 重複コードの定量分析

### フィルタリング重複

| 重複ペア | 重複内容 | 推定重複行数 |
|---|---|---|
| ExerciseDictionaryView ↔ ExercisePickerView | 器具フィルタ、お気に入りフィルタ | ~30行 |
| RoutineBuilderPage.filterByLocation ↔ LocationSelectionPage.filteredExercises | homeEquipment Set定義、フィルタ条件 | ~20行 |
| RoutineBuilderPage.autoPickExercises ↔ RoutineExercisePickerSheet.targetExercises | muscleGroup→種目候補の展開ロジック | ~30行 |
| ExerciseListViewModel.applyFilters ↔ ExerciseDictionaryView.filteredExercises | computed property vs ViewModel、本質同一 | ~40行 |

### GIFグリッドセル重複

| 重複ペア | 推定重複行数 |
|---|---|
| ExerciseDictionaryView グリッドセル ↔ RoutineBuilderPage グリッドセル ↔ HomeHelpers ルーティンカードセル | ~40行 × 3箇所 = ~80行削減可能 |

### フィルターチップUI重複

| 重複ペア | 推定重複行数 |
|---|---|
| ExerciseDictionaryView.filterChip ↔ ExercisePickerView.FilterChip | ~20行 |

---

## 6. 統一ExercisePicker設計提案

### 6-A. 共通化できる部分

1. **GIFグリッドセル（ExerciseGifGridCell）** — 3箇所で同一パターン
2. **フィルターチップ（FilterChipView）** — 4箇所で類似実装
3. **フィルタリングエンジン（ExerciseFilterEngine）** — 5箇所で独立実装
4. **GIFサムネイル行（ExerciseThumbnailRow）** — 3箇所で類似

### 6-B. 画面固有の部分（共通化しない）

1. **ExercisePickerView**: 適合性バッジ（`ExerciseCompatibilityCalculator`）、info.circleプレビューボタン
2. **RoutineBuilderPage**: セット×レップバッジ、削除ボタン、location切替
3. **ExerciseDictionaryView**: 筋肉マップ連動フィルタ
4. **MenuPreviewSheet**: 重量提案テキスト、前回記録

### 6-C. 推奨コンポーネント構成

```
SharedComponents/
├── ExerciseGifGridCell.swift      ← NEW: 2カラムグリッド用GIFセル
├── ExerciseThumbnailRow.swift     ← NEW: リスト行用サムネイル行
├── ExerciseFilterChip.swift       ← NEW: フィルターチップ共通UI
├── ExerciseFilterEngine.swift     ← NEW: フィルタリングロジック統合
└── ExerciseGifView.swift          ← EXISTING: 変更なし
```

### 6-D. ExerciseGifGridCell（2カラムグリッド共通セル）

```swift
struct ExerciseGifGridCell: View {
    let exercise: ExerciseDefinition
    let cornerRadius: CGFloat          // 8, 10, 12
    var overlay: GridCellOverlay = .nameOnly

    enum GridCellOverlay {
        case nameOnly                    // 種目辞典
        case nameAndMuscleChip           // 種目辞典（筋肉チップ付き）
        case nameAndSetsReps(Int, Int)   // ルーティンビルダー, ホームカード
        case custom(AnyView)             // 将来拡張用
    }

    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?          // ルーティンビルダーの削除ボタン

    var body: some View { ... }
}
```

### 6-E. ExerciseFilterEngine（統一フィルタ）

```swift
struct ExerciseFilterEngine {
    /// 部位グループフィルタ
    static func filterByMuscleGroup(_ exercises: [ExerciseDefinition], group: MuscleGroup?) -> [ExerciseDefinition]

    /// 器具フィルタ
    static func filterByEquipment(_ exercises: [ExerciseDefinition], equipment: String?) -> [ExerciseDefinition]

    /// Location フィルタ（オンボーディング共通）
    static func filterByLocation(_ exercises: [ExerciseDefinition], location: String) -> [ExerciseDefinition]

    /// お気に入りフィルタ
    static func filterFavorites(_ exercises: [ExerciseDefinition]) -> [ExerciseDefinition]

    /// 最近使った種目
    static func filterRecent(_ exercises: [ExerciseDefinition]) -> [ExerciseDefinition]

    /// テキスト検索
    static func search(_ exercises: [ExerciseDefinition], query: String) -> [ExerciseDefinition]

    /// MuscleGroup → 候補種目展開（RoutineBuilder / RoutineExercisePickerSheet 共通）
    static func candidatesForGroups(_ groups: [MuscleGroup]) -> [ExerciseDefinition]
}
```

### 6-F. ExerciseFilterChip（統一チップUI）

```swift
struct ExerciseFilterChip: View {
    let text: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void
    var colorScheme: ChipColorScheme = .main  // .main or .onboarding

    var body: some View { ... }
}
```

### 6-G. 削除可能コード行数の見積もり

| 対象 | 現在の行数 | 削除可能行数 | 理由 |
|---|---|---|---|
| ExerciseDictionaryView フィルターチップ | ~20行 | ~15行 | ExerciseFilterChip に置換 |
| ExerciseDictionaryView グリッドセル | ~35行 | ~30行 | ExerciseGifGridCell に置換 |
| ExercisePickerView FilterChip | ~17行 | ~17行 | ExerciseFilterChip に置換 |
| ExercisePickerView フィルタロジック部分 | ~60行 | ~40行 | ExerciseFilterEngine に移行（VM残り） |
| ExerciseListViewModel | 125行 | ~80行 | ExerciseFilterEngine に統合 |
| RoutineBuilderPage グリッドセル | ~45行 | ~35行 | ExerciseGifGridCell に置換 |
| RoutineBuilderPage filterByLocation | ~8行 | ~8行 | ExerciseFilterEngine に統合 |
| RoutineBuilderPage 候補展開ロジック | ~20行 | ~15行 | ExerciseFilterEngine.candidatesForGroups |
| RoutineExercisePickerSheet targetExercises | ~30行 | ~25行 | ExerciseFilterEngine に統合 |
| HomeHelpers ルーティンカードセル | ~40行 | ~30行 | ExerciseGifGridCell に置換 |
| LocationSelectionPage フィルタ | ~15行 | ~10行 | ExerciseFilterEngine.filterByLocation |
| **合計** | **~415行** | **~305行** | |

**推定効果: 約305行の重複コード削減 + 新規共通コンポーネント約200行 = 純減約100行 + 保守性大幅向上**

---

## 7. 実装優先度の提案

| 優先度 | コンポーネント | 影響範囲 | 難易度 |
|---|---|---|---|
| P0 | ExerciseFilterEngine | 5画面のフィルタロジック統一 | 中（ロジックのみ、UI変更なし） |
| P0 | ExerciseGifGridCell | 3画面のグリッドセル統一 | 低（UI抽出のみ） |
| P1 | ExerciseFilterChip | 4画面のチップUI統一 | 低（UI抽出のみ） |
| P2 | ExerciseThumbnailRow | 3画面のリスト行統一 | 低（サイズ差のパラメータ化） |
| P2 | ExerciseListViewModel廃止 | ExerciseFilterEngine移行後に削除 | 中（VM→Engine移行） |

---

## 8. 注意事項

1. **カラーパレットの分岐**: オンボーディング画面は `mmOnboarding*` カラー、メイン画面は `mmBg*/mmAccent*` カラーを使用。ExerciseGifGridCell と ExerciseFilterChip には `.colorScheme` パラメータが必要。

2. **ExercisePickerView の適合性バッジ**: `ExerciseCompatibilityCalculator` による回復状態ベースの推奨バッジは ExercisePickerView 固有。統一ピッカーに組み込む場合は optional callback で対応。

3. **RoutineBuilderPage の自動ピックロジック**: `autoPickExercises` は優先度ソート+件数制限を含む複雑なロジック。ExerciseFilterEngine には含めず、RoutineBuilderPage 固有ロジックとして維持。

4. **ExerciseGifView の `.card` サイズ**: 静止画（1フレーム目のみ）。グリッドのパフォーマンスに直結するため、この挙動は維持。

5. **Location フィルタの日英キー混在**: `homeEquipment` に日本語キー（"自重", "ダンベル"）と英語キー（"Bodyweight", "Dumbbell"）を両方含めている。ExerciseFilterEngine 統合時にこの仕様を維持すること（exercises.json のキーが日本語のため）。
