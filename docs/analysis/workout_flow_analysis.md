# CC-D: ワークアウト記録フロー完全分析

> **分析日:** 2026-03-20
> **対象バージョン:** v1.0（App Store提出準備版）
> **トリガー:** ジム実機テストで「種目変更めんどくさい」「アシスト種目のkg表示おかしい」が報告

---

## 1. 画面遷移フロー全体マップ

```
WorkoutStartView（ルートコントローラ）
├── isSessionActive == false → WorkoutIdleView
│   ├── MuscleMapView（筋肉タップ → MuscleExercisePickerSheet）
│   ├── RecommendedWorkoutBanner（おすすめメニュー → 全種目セッション追加）
│   ├── FavoriteExercisesSection（お気に入り横スクロール → 種目選択）
│   └── 「種目を追加して始める」ボタン → ExerciseLibraryView（sheet）
│
├── isSessionActive == true → ActiveWorkoutView
│   ├── selectedExercise != nil → SetInputCard
│   │   ├── GIF + タイマーオーバーレイ + PRバッジ
│   │   ├── 前回記録 + 「同じ」ボタン
│   │   ├── 重量提案チップ（+2.5kg）
│   │   ├── 自重種目: 加重トグル
│   │   ├── WeightInputView（タップで直接入力 / WeightStepperButton ±）
│   │   ├── StepperButton（レップ数 ±1）
│   │   └── 「記録する」ボタン → recordSet() → レストタイマー自動開始
│   │       └── PR達成時 → PRCelebrationOverlay（2秒表示）
│   │
│   ├── 「種目を追加」ボタン → ExercisePickerView（sheet）
│   │   ├── FilterChips（最近 / お気に入り / 全て / カテゴリ / 器具）
│   │   ├── EnhancedExerciseRow（GIFサムネ + 適合性バッジ）
│   │   └── info(i)ボタン → ExercisePreviewSheet（half modal）
│   │       └── 「この種目を追加」ボタン
│   │
│   ├── 空状態 → EmptyWorkoutGuidance
│   ├── RecordedSetsView（種目ごとグループ、スワイプで編集/削除）
│   │   └── セット編集 → SetEditSheet（height:280 シート）
│   │
│   └── 「ワークアウト終了」ボタン → confirmationDialog
│       ├── 「保存して終了」→ endSession() → WorkoutCompletionView（fullScreenCover）
│       └── 「破棄して終了」→ discardSession()
│
└── WorkoutCompletionView（完了画面）
    ├── CompletionIcon（紙吹雪アニメーション）
    ├── CompletionStatsCard（ボリューム/種目数/セット数/時間）
    ├── シェアボタン → confirmationDialog（Instagram / その他）
    ├── LevelUpCelebrationSection（レベルアップ時のみ）
    ├── StimulatedMusclesSection（前面+背面ミニマップ）
    ├── NextRecommendedDaySection（回復予測ベース）
    ├── StrengthMapShareSection（PR更新時のみ）
    ├── CompletionExerciseList（実施種目チェックリスト）
    ├── CompletionProBanner（非Pro時のみ）
    ├── FullBodyConquestView（全身制覇時 fullScreenCover）
    └── 「閉じる」ボタン
```

---

## 2. SetInputComponents.swift 詳細分析

### 重量入力UI

| 項目 | 実装 |
|:---|:---|
| メインコンポーネント | `WeightInputView` — 数値タップで `TextField(keyboardType: .decimalPad)` に切替 |
| ステッパー | `WeightStepperButton` — タップ: ±0.25kg, 長押し: ±2.5kg（0.15s間隔） |
| 最小値 | 0kg（`max(0, currentWeight + delta)`） |
| 最大値 | **制限なし**（上限バリデーションなし） |
| 刻み | タップ: 0.25kg / 長押し: 2.5kg |
| 表示形式 | `%.2f`（例: 100.00） |
| 直接入力 | タップ → TextField表示、空から入力開始、カンマ→ドット自動変換 |

### レップ数入力UI

| 項目 | 実装 |
|:---|:---|
| コンポーネント | `StepperButton` — 標準の+/-円形ボタン |
| 刻み | ±1 |
| 最小値 | 1（`max(1, currentReps + delta)`） |
| 最大値 | **制限なし** |
| 長押し | **非対応**（重量は長押しあるがレップ数にはない） |

### 前回記録の表示

- **表示あり**: `lastWeight` / `lastReps` がnilでない場合に `previousRecord` ラベル表示
- **取得優先度**: セッション内直前セット > 過去セッション最終記録
- **「同じ」ボタン**: 前回値をそのまま `currentWeight` / `currentReps` にコピー
- **+2.5kg提案チップ**: `lastWeight > 0` かつ非自重の場合のみ表示

### 自重種目の特別対応

| 項目 | 実装 |
|:---|:---|
| 判定 | `exercise.equipment == "自重" || exercise.equipment == "Bodyweight"` |
| デフォルト | 重量0kg、レップ数10 |
| 加重トグル | `Toggle` — ON時に重量入力UI表示、OFF時に0に戻す（保存値復元あり） |
| 前回記録 | 重量0の場合は「前回: {reps}回」のみ表示 |
| 重量提案チップ | 非表示（`!isBodyweight` 条件） |

### アシスト種目の特別対応

**対応なし。** `equipment` が `"自重"` / `"Bodyweight"` のみ特別扱い。アシスト系（アシストディップス等）やケーブル系で「アシスト重量」を入力する概念が未実装。

---

## 3. WorkoutViewModel.swift 全メソッドリスト

### セッション操作

| メソッド | 概要 |
|:---|:---|
| `startOrResumeSession()` | 既存アクティブセッション再開 or 新規作成 |
| `endSession()` | タイマー停止 → session.endDate設定 → ウィジェット更新 → incrementWorkoutCount() |
| `discardSession()` | タイマー停止 → 筋肉刺激削除 → セッション削除 |

### 種目選択

| メソッド | 概要 |
|:---|:---|
| `selectExercise(_:)` | 種目選択 → 使用履歴記録 → セット番号計算 → 前回記録取得 |
| `applyRecommendedExercises(_:)` | 提案種目リスト適用 → 最初の種目を選択 → 提案重量セット |

### セット操作

| メソッド | 概要 |
|:---|:---|
| `recordSet() -> Bool` | バリデーション → PR判定 → セット保存 → 筋肉刺激更新 → タイマー開始 → PR達成を返却 |
| `adjustWeight(by:)` | 重量調整（下限0） |
| `adjustReps(by:)` | レップ数調整（下限1） |
| `deleteSet(_:)` | セット削除 → セット番号振り直し → 筋肉刺激再計算 |

### タイマー

| メソッド | 概要 |
|:---|:---|
| `startRestTimer()` | カウントダウン開始（AppState.defaultRestTimerDuration, デフォルト90秒） |
| `tickRestTimer()` | 1秒毎の処理（バックグラウンド復帰対応: Dateベース計算） |
| `stopRestTimer()` | タイマー停止 |
| `resetRestTimer()` | タイマーリセット |
| `recalculateRestTimerAfterBackground()` | バックグラウンド復帰時の補正 |

### 内部

| メソッド | 概要 |
|:---|:---|
| `refreshExerciseSets()` | セッション内セットを種目ごとにグループ化（新しい順ソート） |
| `updateWidgetAfterSession()` | ウィジェットデータ更新 |
| `updateMuscleStimulations(exercise:session:)` | 筋肉刺激記録をバッチ更新 |

### プロパティ

| プロパティ | 型 | 概要 |
|:---|:---|:---|
| `activeSession` | `WorkoutSession?` | 現在のセッション |
| `selectedExercise` | `ExerciseDefinition?` | 選択中の種目 |
| `currentWeight` | `Double` | 入力中の重量 |
| `currentReps` | `Int` | 入力中のレップ数（デフォルト10） |
| `currentSetNumber` | `Int` | 次のセット番号 |
| `exerciseSets` | `[(exercise, sets)]` | セッション内の全記録 |
| `lastWeight` / `lastReps` | `Double?` / `Int?` | 前回記録 |
| `recommendedExercises` | `[RecommendedExercise]` | 提案種目リスト |
| `lastSetWasPR` | `Bool` | 直前セットがPRか |
| `restTimerSeconds` | `Int` | タイマー残り秒 |
| `isRestTimerRunning` | `Bool` | タイマー動作中か |
| `isRestTimerOvertime` | `Bool` | オーバータイム状態か |

---

## 4. ExercisePickerView 分析

### UIレイアウト

- **形式**: `List` (plain style)、各行に `EnhancedExerciseRow`
- **GIF表示**: あり（`ExerciseGifView(size: .thumbnail)` 56x56）、GIFない場合は `MiniMuscleMapView`
- **検索**: `.searchable` (SwiftUI標準、NavigationStack内)

### フィルタリング

| フィルター | 実装 |
|:---|:---|
| 最近使った | `RecentExercisesManager.shared` ベース |
| お気に入り | `FavoritesManager.shared` ベース |
| 全て | フィルタ解除 |
| カテゴリ | 胸/背中/肩/腕 等 |
| 器具 | バーベル/ダンベル/ケーブル/マシン/自重 等 |

- フィルターは排他的（1つ選択で他がリセット）
- 横スクロール `FilterChip` カプセル形式

### 選択→追加フロー

1. 種目行タップ → `onSelect(exercise)` → シート閉じ → `viewModel.selectExercise(exercise)` → SetInputCard表示
2. info(i)ボタンタップ → `ExercisePreviewSheet` (half modal) → 「この種目を追加」ボタン → 同上

### 適合性バッジ

- `ExerciseCompatibilityCalculator.calculate()` で回復状態に基づく適合性を計算
- recommended / neutral / fatigued 等のバッジ表示

---

## 5. レストタイマー分析

### 設定

| 項目 | 値 |
|:---|:---|
| デフォルト | 90秒（`AppState.defaultRestTimerDuration`） |
| カスタム | 設定画面の `Picker` で変更可能 |
| 開始トリガー | `recordSet()` 成功時に自動開始 |

### カウントダウン→オーバータイム動作

```
0s         90s            ∞
|--countdown--|--overtime--->
 ↑            ↑
 残り10秒で    0到達で
 警告Haptic   完了Haptic
 (lightTap)   (restTimerCompleted)
```

### バックグラウンド復帰

- `restTimerStartDate` (Date) を記録
- `scenePhase == .active` 時に `recalculateRestTimerAfterBackground()` → `tickRestTimer()` で経過時間を再計算
- **正確**: バックグラウンド中もDateベースで計算するため、復帰後にズレなし

### UI表示

| コンテキスト | コンポーネント |
|:---|:---|
| GIFあり | `CompactTimerBadge` — GIF右上にオーバーレイ（カプセル型） |
| GIFなし | `CompactTimerBadge` — SetInputCard内にインライン表示 |
| 停止操作 | バッジタップで `stopRestTimer()` |

### Hapticフィードバック

| タイミング | Haptic |
|:---|:---|
| 残り10秒 | `HapticManager.lightTap()`（1回のみ） |
| 0秒到達 | `HapticManager.restTimerCompleted()`（1回のみ） |

### 問題点

- **タイマー開始が自動のみ**: セットを記録しないとタイマーが開始しない。手動開始ボタンがない
- **タイマー時間変更がセッション中不可**: 設定画面に行く必要がある
- **タイマー表示がGIF右上の小さいバッジのみ**: セット間の視認性が低い

---

## 6. 問題点と改善案

### P1: 種目変更の導線が重い（ジムテスト報告）

**現状の種目変更フロー:**
```
① 現在の種目から離脱: 「< 種目を選択」戻るボタンをタップ
② 「種目を追加」ボタンをタップ → ExercisePickerView シート表示
③ フィルターまたは検索で種目を探す
④ 種目をタップ
= 最短4タップ（実質的にはスクロール含む）
```

**問題:**
- 種目を変えるだけなのに、一度「種目未選択状態」に戻る必要がある
- ExercisePickerViewが毎回フルリストからスタート（前回のフィルター状態を記憶しない）
- ルーティン利用時でも、次の種目への導線が `RecordedSetsView` のタップのみ

**改善案:**
- **A-1**: SetInputCard内に「次の種目 →」ボタンを追加（ルーティンの次の種目に1タップで遷移）
- **A-2**: RecordedSetsView内の種目タップで直接SetInputCardに遷移（現状実装済みだが目立たない）
- **A-3**: 種目変更専用の水平スワイプ or セグメント（セッション内の種目を水平タブ化）

### P2: アシスト種目のkg表示問題（ジムテスト報告）

**現状:**
- アシスト種目（例: assisted_pull_up）の `equipment` が `"自重"` / `"Bodyweight"` のどちらかに分類されている場合のみ自重扱い
- 「アシスト重量」（負荷を軽減するウェイト）を入力する概念がない
- ラットプルダウンなどのケーブル系は通常のkg入力で問題なし

**問題:**
- アシストディップスやアシストプルアップで、加重の概念がユーザーの期待と異なる
- 自重+ウェイトベスト vs アシストマシンの区別がつかない
- 表示上 `0.00 kg` が出る（自重で加重なしの場合）

**改善案:**
- **B-1**: ExerciseDefinitionに `isAssistExercise: Bool` フラグを追加、アシスト系はUIで「アシスト重量」ラベル表示
- **B-2**: 自重種目のデフォルト表示を `"BW"` にして、`0.00 kg` を非表示にする
- **B-3**: 重量表示フォーマットを改善（`%.2f` → 整数なら `%.0f`、小数なら `%.1f`）

### P3: 重量入力の片手操作性

**現状:**
- WeightStepperButtonは60x60ptの円形ボタン（タップターゲットは十分）
- タップ: ±0.25kg、長押し: ±2.5kg
- 直接入力: タップ → TextField → decimalPad

**問題:**
- **0.25kg刻みが細かすぎる**: ジムのプレートは通常2.5kgか1.25kg刻み。0.25kgずつだと10kgまで40タップ必要
- **長押し判定まで0.3秒**: 反応がやや遅い
- **直接入力後のキーボード閉じ**: toolbar の「完了」ボタンが必要（片手では右上に手を伸ばす）

**改善案:**
- **C-1**: デフォルト刻みを2.5kgに変更、長押しで5.0kg or 10kg刻み
- **C-2**: 定番プレート重量のクイックボタン（+1.25, +2.5, +5, +10）を横並びで表示
- **C-3**: キーボードの「完了」をボタン直下にも配置

### P4: レップ数入力に長押し非対応

**現状:**
- StepperButtonは通常の+/-で、長押しが未実装（WeightStepperButtonにはある）
- 20→8に変更する場合、12回タップが必要

**改善案:**
- **D-1**: StepperButtonにもWeightStepperButton同様の長押し対応を追加
- **D-2**: レップ数もタップで直接入力可能にする（numberPad）

### P5: 前回記録との比較がセット入力画面のみ

**現状:**
- 前回記録は SetInputCard 内の小さいキャプションテキスト1行のみ
- セット間で前回記録を確認する導線がない（RecordedSetsViewには非表示）

**改善案:**
- **E-1**: SetInputCard内の前回記録表示を拡大（前回の全セット一覧を折りたたみで表示）
- **E-2**: RecordedSetsViewに前回セッションの対応セットを並列表示

### P6: プログレッシブオーバーロードの提案が弱い

**現状:**
- `+2.5kg` 提案チップが1つだけ（前回重量 + 2.5kg）
- 提案はいつも固定の +2.5kg で、種目やトレーニング歴に応じた調整なし

**改善案:**
- **F-1**: 種目カテゴリに応じた推奨増加量（コンパウンド: +2.5kg、アイソレーション: +1.25kg）
- **F-2**: 過去5セッションの推移グラフをSetInputCard内に表示
- **F-3**: 「レップ数を1増やす」提案も追加（重量据え置きでレップ増加もオーバーロード）

### P7: 種目の並べ替え機能がない

**現状:**
- `WorkoutViewModel` に並べ替えメソッドが**存在しない**
- exerciseSets は `completedAt` 順（新しい方が上）で固定ソート
- 手動並べ替え不可

**改善案:**
- **G-1**: RecordedSetsViewにドラッグ&ドロップ並べ替え対応
- **G-2**: ルーティンの種目順をデフォルト表示順にする

### P8: セット記録の完了フィードバック

**現状:**
- セット記録時: ボタンのバウンスアニメーション（0.08s→spring） + Haptic(medium)
- PR時: PRCelebrationOverlay（2秒表示） + Haptic(heavy)

**問題なし** — フィードバックは適切。

### P9: セッション中のルーティン連携が弱い

**現状:**
- `applyRecommendedExercises()` で提案種目を一括追加可能
- しかし、セッション中に「ルーティンの次の種目」への導線がない
- RecordedSetsView内の種目名タップで遷移はできるが、未記録の次の種目への誘導がない

**改善案:**
- **I-1**: SetInputCard下部に「ルーティンの次の種目」カードを表示
- **I-2**: 全種目完了時に「ルーティン完了！」メッセージ表示

### P10: 完了画面の目標連動コピーが日本語のみ

**現状:**
- `completionGoalCopy` のメッセージが日本語ハードコード
- 例: `"胸板、また一段厚くなった"` — 英語版なし

**改善案:**
- **J-1**: L10nキーで日英対応化

---

## 7. 優先度マトリクス

| ID | 問題 | 影響度 | 実装難易度 | 推奨Wave |
|:---|:---|:---|:---|:---|
| **C-1** | 重量刻みが細かすぎる（0.25kg→2.5kg） | 高 | 低 | Wave 10 |
| **A-1** | ルーティン次種目への1タップ導線 | 高 | 中 | Wave 10 |
| **B-2** | 自重種目の0.00kg表示改善 | 中 | 低 | Wave 10 |
| **B-3** | 重量フォーマット改善（%.2f→条件分岐） | 中 | 低 | Wave 10 |
| **D-1** | レップ数ステッパーに長押し対応 | 中 | 低 | Wave 10 |
| **F-1** | 種目カテゴリ別の推奨増加量 | 中 | 中 | Wave 11 |
| **I-1** | ルーティン次種目カード表示 | 中 | 中 | Wave 11 |
| **E-1** | 前回記録の全セット表示 | 低 | 中 | Wave 11 |
| **J-1** | 完了画面コピー日英対応 | 低 | 低 | Wave 10 |
| **C-2** | クイックプレートボタン | 低 | 中 | Wave 12 |
| **G-1** | 種目ドラッグ並べ替え | 低 | 高 | Wave 12 |
| **B-1** | アシスト種目フラグ追加 | 低 | 高 | Wave 12+ |

---

## 8. ファイル別コード量と責務

| ファイル | 行数 | 責務 |
|:---|:---|:---|
| WorkoutStartView.swift | 167 | ルートコントローラ、ペンディング種目/提案処理 |
| WorkoutViewModel.swift | 381 | 全ビジネスロジック（セッション/種目/セット/タイマー） |
| WorkoutIdleComponents.swift | 368 | 待機画面（マップ/おすすめ/お気に入り/筋肉ピッカー） |
| ActiveWorkoutComponents.swift | 305 | アクティブ画面（入力カード配置/終了確認/セット編集シート） |
| SetInputComponents.swift | 362 | セット入力カード + PRオーバーレイ |
| WorkoutInputHelpers.swift | 168 | ステッパー/重量入力の再利用コンポーネント |
| RecordedSetsComponents.swift | 137 | 記録済みセット一覧（スワイプ編集/削除） |
| WorkoutTimerComponents.swift | 143 | タイマーUI（フルサイズ + コンパクトバッジ） |
| ExercisePickerView.swift | 372 | 種目選択シート（フィルター/検索/リッチ行） |
| ExercisePreviewSheet.swift | 444 | 種目プレビュー（GIF/筋肉マップ/YouTube） |
| WorkoutCompletionView.swift | 566 | 完了画面本体 |
| WorkoutCompletionSections.swift | 550 | 完了セクション（統計/筋肉マップ/おすすめ日/レベルアップ等） |
| WorkoutCompletionComponents.swift | 470 | シェアカード/StatBox/ShareSheet |
| FullBodyConquestView.swift | 354 | 全身制覇祝福画面 |
| ShareMuscleMapView.swift | 158 | シェア用静的筋肉マップ |
| **合計** | **~4,945** | |

---

## 9. データフロー概要

```
WorkoutStartView
  └── WorkoutViewModel（@Observable, @MainActor）
        ├── WorkoutRepository（SwiftData CRUD）
        │   ├── WorkoutSession（@Model）
        │   └── WorkoutSet（@Model）
        ├── MuscleStateRepository（MuscleStimulation CRUD）
        ├── ExerciseStore.shared（exercises.json 92種目）
        ├── PRManager.shared（PR判定/推定1RM）
        ├── RecentExercisesManager.shared（使用履歴）
        ├── FavoritesManager.shared（お気に入り）
        ├── PurchaseManager.shared（週間制限 incrementWorkoutCount）
        ├── AppState.shared（defaultRestTimerDuration）
        ├── WidgetDataProvider（ウィジェット更新）
        ├── HapticManager（触覚フィードバック）
        └── NotificationManager（回復通知スケジュール）
```

---

## 10. まとめ

ワークアウト記録フローは基本的に堅実に設計されている。主な摩擦ポイントは:

1. **重量刻みの粒度** — 0.25kgは実用的ではない（2.5kgがジム標準）
2. **種目切り替えの多タップ** — ルーティン連携が弱く、毎回ピッカーを開く必要がある
3. **自重/アシスト種目のUX** — 0.00kg表示、アシスト概念なし
4. **レップ数入力の長押し未対応** — 重量には実装済みなのに非対称

Wave 10ではC-1（刻み変更）、A-1（ルーティン次種目導線）、B-2/B-3（表示改善）、D-1（レップ長押し）を優先的に対応することを推奨する。
