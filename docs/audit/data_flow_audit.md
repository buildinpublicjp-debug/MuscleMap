# MuscleMap データフロー監査レポート v2

> **日付:** 2026-03-17
> **対象:** MuscleMap iOS App 全データフロー
> **スコープ:** オンボーディング / ワークアウト記録 / 回復計算 / メニュー提案 / 課金ゲート / ルーティン統合
> **監査者:** Claude Code (Opus 4)

---

## サマリー

| 項目 | 件数 |
|:---|:---|
| 追跡したデータフロー数 | 32 |
| 正常 | 22 |
| 不整合発見 | 10 |
| 致命的 (CRITICAL) | 3 |
| 要注意 (WARNING) | 7 |

### 致命的バグ一覧

| # | 深刻度 | 内容 | ファイル |
|:--|:--|:--|:--|
| C-1 | **CRITICAL** | `incrementWorkoutCount()` がどこからも呼ばれていない。無料ユーザーの週間制限が完全に無効 | `PurchaseManager.swift` L112 |
| C-2 | **CRITICAL** | `HomeViewModel.loadTodayRoutine()` と `RoutineManager.todayRoutineDay()` のロジック不整合（曜日ベース vs セッション履歴ベース） | `HomeViewModel.swift` L44-54, `RoutineManager.swift` L33-66 |
| C-3 | **CRITICAL** | GoalSelectionPage が単一選択だが CLAUDE.md では複数選択（Set<OnboardingGoal>）と記述。仕様と実装の乖離 | `GoalSelectionPage.swift` L59, `AppState.swift` L127-130 |

### 要注意バグ一覧

| # | 深刻度 | 内容 | ファイル |
|:--|:--|:--|:--|
| W-1 | **HIGH** | `trainingLocation="both"` がフィルタリングで `"gym"` と同じ扱い（全種目通過） | `WorkoutRecommendationEngine.swift` L308-322 |
| W-2 | **MEDIUM** | `WeeklyFrequency` に「週1回」の選択肢がない | `FrequencySelectionPage.swift` L5-54 |
| W-3 | **HIGH** | `MuscleStimulation.totalSets` が種目単位で記録され、同一筋肉を刺激する複数種目のセットが合算されない | `WorkoutViewModel.swift` L347-362 |
| W-4 | **LOW** | 胸の `baseRecoveryHours` が 48h（中筋群）だが StrengthScoreCalculator では `.compoundLarge`（大筋群）に分類 | `Muscle.swift` L127-129, `StrengthScoreCalculator.swift` L186-187 |
| W-5 | **MEDIUM** | `debugOverridePremium` のデフォルト値が `true`（QAテスト阻害の可能性） | `PurchaseManager.swift` L11 |
| W-6 | **LOW** | `MuscleStimulation.maxIntensity` が回復計算で一切使用されていない | `RecoveryCalculator.swift`, `MuscleStateRepository.swift` L84 |
| W-7 | **MEDIUM** | `initialPRs` の過大入力を修正するUIが存在しない（PR編集画面なし） | `StrengthScoreCalculator.swift` L235-240 |

---

## A. オンボーディング → UserProfile データフロー

### ページ別データ保存・読出し一覧

| ページ | 保存先 | キー | 型 | 読出し箇所 |
|:---|:---|:---|:---|:---|
| Page 0: GoalSelection | AppState (UserDefaults) | `primaryOnboardingGoal` | String? | GoalMusclePreviewPage, CallToActionPage, RoutineCompletionPage, PaywallView, WorkoutCompletionView, MenuSuggestionService |
| Page 1: Frequency | UserProfile (UserDefaults) | `weeklyFrequency` | Int | RoutineBuilderPage, WorkoutRecommendationEngine, MenuSuggestionService, CallToActionPage |
| Page 2: Location | UserProfile (UserDefaults) | `trainingLocation` | String | WorkoutRecommendationEngine, RoutineBuilderPage |
| Page 3: TrainingHistory | UserProfile (UserDefaults) | `trainingExperience` | TrainingExperience | OnboardingV2View (shouldShowPRInput), WorkoutRecommendationEngine (defaultReps/Sets), RoutineBuilderPage |
| Page 4: PRInput (条件付き) | UserProfile (UserDefaults) | `initialPRs` | [String:Double] | StrengthScoreCalculator (Step 1.5 マージ) |
| Page 5: GoalMusclePreview | UserProfile (UserDefaults) | `goalPriorityMuscles` | [String] | WorkoutRecommendationEngine.sortByPriority(), MenuSuggestionService.primaryGroupFromGoal(), RoutineBuilderPage |
| Page 6: WeightInput | UserProfile (UserDefaults) | `weightKg`, `heightCm`, `nickname` | Double/String | StrengthScoreCalculator (bodyweight), WorkoutCompletionView (シェアカード) |
| Page 7: RoutineBuilder | UserRoutine (UserDefaults) + FavoritesManager | `userRoutine`, favorites | JSON/Set | RoutineManager, HomeViewModel.loadTodayRoutine() |
| Page 8: RoutineCompletion | (表示のみ + Paywall) | -- | -- | PaywallView呼出 |

### A-1. GoalSelectionPage → primaryOnboardingGoal

**保存コード** (`GoalSelectionPage.swift` L119):
```swift
AppState.shared.primaryOnboardingGoal = goal.rawValue
```

**読み出し箇所（全6箇所）:**
1. `OnboardingV2View.swift` L64: GoalMusclePreviewPage の「次へ」で GoalMusclePriority.data(for:) に渡す
2. `CallToActionPage.swift`: 目標別キャッチコピー表示
3. `RoutineCompletionPage.swift`: ルーティン完了サマリー表示
4. `PaywallView.swift`: 目標筋肉マップ表示
5. `WorkoutCompletionView.swift` L281: 完了メッセージの目標連動コピー
6. `MenuSuggestionService.swift` L109: primaryGroupFromGoal() 内の goalPriorityMuscles 参照

**結果: 正常（単一選択）。ただし CLAUDE.md との仕様乖離あり（C-3参照）**

### A-2. FrequencySelectionPage → weeklyFrequency

**保存コード** (`OnboardingV2View.swift` L37):
```swift
AppState.shared.userProfile.weeklyFrequency = frequency.rawValue
```

`WeeklyFrequency` enum の rawValue は Int: `.twice(2)`, `.thrice(3)`, `.four(4)`, `.fivePlus(5)`

**読み出し箇所（全4箇所）:**
1. `WorkoutRecommendationEngine.splitParts(for:)` L198-234: 分割法決定
2. `MenuSuggestionService.pairedGroups(for:)` L155: ペアリング取得
3. `RoutineBuilderPage`: Day数生成（frequency に基づくルーティン日数）
4. `CallToActionPage`: 週X回表示テキスト

**結果: 正常。ただし週1回の選択肢がない（W-2参照）**

### A-3. LocationSelectionPage → trainingLocation

**保存コード** (`OnboardingV2View.swift` L44):
```swift
AppState.shared.userProfile.trainingLocation = location.rawValue
```

`TrainingLocation` enum: `.gym`, `.home`, `.both` → rawValue は "gym", "home", "both"

**読み出し箇所（全2箇所）:**
1. `WorkoutRecommendationEngine.filterByLocation()` L308-322
2. `RoutineBuilderPage`: ルーティン種目のフィルタリング

**filterByLocation() のロジック:**
```swift
guard location == "home" else { return exercises }  // "gym" も "both" もフィルタなし
```

**結果: "home" のみフィルタ適用。"both" は "gym" と同じ扱い（W-1参照）**

### A-4. TrainingHistoryPage → trainingExperience

**保存コード** (`TrainingHistoryPage.swift` 内):
```swift
AppState.shared.userProfile.trainingExperience = experience
```

**shouldShowPRInput の分岐:**
```swift
var shouldShowPRInput: Bool {
    self == .oneYearPlus || self == .veteran
}
```
- `.beginner`: PRInputPage スキップ、defaultReps=12, defaultSets=3
- `.halfYear`: PRInputPage スキップ、defaultReps=10, defaultSets=3
- `.oneYearPlus`: PRInputPage 表示、defaultReps=8, defaultSets=4
- `.veteran`: PRInputPage 表示、defaultReps=6, defaultSets=4

**結果: 正常。shouldShowPRInput の分岐は正しく OnboardingV2View L12-13 で参照**

### A-5. PRInputPage → initialPRs

**保存コード** (`PRInputPage.swift` 内):
```swift
AppState.shared.userProfile.initialPRs[exerciseId] = estimated1RM
```

**読み出し箇所:**
- `StrengthScoreCalculator.muscleStrengthScores()` Step 1.5: `if pr1RM > (exerciseBest1RM[exerciseId] ?? 0)` で実際のワークアウト記録より大きい場合のみ採用

**結果: 正常。ただし上限バリデーションなし・編集UIなし（W-7参照）**

### A-6. GoalMusclePreviewPage → goalPriorityMuscles

**保存コード** (`OnboardingV2View.swift` L64-68):
```swift
if let raw = AppState.shared.primaryOnboardingGoal,
   let goal = OnboardingGoal(rawValue: raw) {
    let muscles = GoalMusclePriority.data(for: goal).muscles
    AppState.shared.userProfile.goalPriorityMuscles = muscles.map { $0.rawValue }
}
```

**GoalMusclePriority の7パターン:**
| 目標 | 重点筋肉 |
|:---|:---|
| getBig | chestUpper, chestLower, lats, quadriceps, hamstrings, glutes |
| dontGetDisrespected | deltoidAnterior, deltoidLateral, chestUpper, trapsUpper |
| martialArts | lats, quadriceps, hamstrings, rectusAbdominis, obliques |
| sports | quadriceps, hamstrings, glutes, rectusAbdominis, deltoidAnterior |
| getAttractive | chestUpper, deltoidAnterior, deltoidLateral, biceps, rectusAbdominis |
| moveWell | quadriceps, glutes, rectusAbdominis, erectorSpinae, lats |
| health | quadriceps, hamstrings, glutes, erectorSpinae, rectusAbdominis |

**読み出し箇所（全3箇所）:**
1. `MenuSuggestionService.primaryGroupFromGoal()` L109: goalPriorityMuscles[0] → MuscleGroup
2. `WorkoutRecommendationEngine.sortByPriority()` L330-356: 優先度ソートのスコアリング
3. `WorkoutRecommendationEngine.generateFirstTimeRecommendation()` L126-132: 初回ユーザーのターゲットグループ決定

**結果: 正常。GoalMusclePriority → UserProfile → Engine の変換チェーンは型安全**

### A-7. WeightInputPage → weightKg, heightCm, nickname

**保存コード** (`WeightInputPage.swift` 内): AppState.shared.userProfile にリアルタイム更新

**読み出し箇所:**
- `StrengthScoreCalculator`: `bodyweightKg` として strengthRatio 計算に使用
- `WorkoutCompletionView.prepareShareImage()` L387: `AppState.shared.userProfile.weightKg`
- `WorkoutCompletionView.prepareStrengthShareImage()` L521: `UserProfile.load().weightKg`
- `heightCm`: **現在どこからも参照されていない**（将来のBMI計算用として定義のみ）

**結果: 正常。ただし heightCm は未使用**

### A-8. RoutineBuilderPage → UserRoutine

**保存コード** (`RoutineBuilderPage.swift` L325):
```swift
RoutineManager.shared.saveRoutine(routine)
```

**UserRoutine の永続化:** `UserDefaults` に JSON エンコードして保存（storageKey: "userRoutine"）

**結果: 正常。UserDefaults 経由で正しく永続化**

---

## B. ワークアウト記録データフロー

### 全体フロー図

```
WorkoutStartView
  |
  |--[開始]---> WorkoutViewModel.startOrResumeSession()
  |              |-> WorkoutRepository.startSession()
  |              |   -> WorkoutSession(id, startDate, endDate=nil) [SwiftData]
  |              |-> 既存アクティブセッションがあれば再開
  |
  |--[セット記録]--> WorkoutViewModel.recordSet(exercise, weight, reps)
  |                   |-> WorkoutRepository.addSet() -> WorkoutSet [SwiftData]
  |                   |-> PRManager.checkIsWeightPR() -> PR判定
  |                   |-> updateMuscleStimulations(exercise, session)
  |                   |   |-> exercise.muscleMapping の各筋肉に対して:
  |                   |   |   MuscleStateRepository.upsertStimulation()
  |                   |   |   -> MuscleStimulation [SwiftData]
  |                   |   |   totalSets = その種目のセット数 [★ W-3: 筋肉合計ではない]
  |                   |-> startRestTimer()
  |
  |--[終了]----> WorkoutStartView.onWorkoutCompleted
                  |-> WorkoutViewModel.endSession()
                  |   |-> WorkoutRepository.endSession() -> session.endDate = Date()
                  |   |-> updateWidgetAfterSession()
                  |   |-> [★ C-1: incrementWorkoutCount() 未呼出]
                  |
                  |-> completedSession = session
                  |   -> fullScreenCover: WorkoutCompletionView
                        |-> checkFullBodyConquest()
                        |-> markFirstWorkoutCompleted()
                        |-> checkPRUpdates() -> hasPRUpdate
                        |-> detectLevelUps() -> levelUpExercises
                        |-> scheduleRecoveryNotification()
```

### B-1. セッション開始

`WorkoutViewModel.startOrResumeSession()`:
- 既存アクティブセッション（`endDate == nil`）があれば再開
- なければ新規 `WorkoutSession` を SwiftData に作成

**結果: 正常**

### B-2. セット追加

`WorkoutViewModel.recordSet()`:
1. `workoutRepo.addSet()` で WorkoutSet を SwiftData に保存
2. `PRManager.checkIsWeightPR()` でPR判定
3. `updateMuscleStimulations()` で筋肉刺激データを更新
4. `setNumber += 1` でセット番号インクリメント
5. `startRestTimer()` でレストタイマー開始

**結果: 正常**

### B-3. MuscleStimulation の計算と保存

`updateMuscleStimulations()` (`WorkoutViewModel.swift` L347-362):
```swift
for (muscleId, percentage) in exercise.muscleMapping {
    let maxIntensity = Double(percentage) / 100.0
    let totalSets = workoutRepo.fetchSets(in: session, exerciseId: exercise.id).count
    muscleRepo.upsertStimulation(
        muscle: muscleId, sessionId: session.id,
        maxIntensity: maxIntensity, totalSets: totalSets
    )
}
```

`MuscleStateRepository.upsertStimulation()`:
- sessionId + muscle で既存レコードを検索
- 既存あり: `maxIntensity = max(既存, 新規)`, `totalSets = 新規値で上書き`
- 既存なし: 新規作成

**問題 (W-3):**
- ベンチプレス 3セット → chest_upper に totalSets=3 で保存
- 次にインクラインプレス 3セット → chest_upper に totalSets=3 で**上書き**
- 実際は合計6セットだが、3セットとして記録される
- 回復時間が過小評価される

**結果: 要注意（W-3）。種目ごとの totalSets であり、筋肉ごとの合算ではない**

### B-4. セッション終了

`WorkoutViewModel.endSession()`:
- `session.endDate = Date()` を設定
- Widget データ更新
- **`incrementWorkoutCount()` 未呼出（C-1参照）**

**結果: 致命的（C-1）。週間制限カウントが更新されない**

### B-5. 完了画面 → PR判定 + シェアカード

`WorkoutCompletionView.onAppear`:
1. `checkFullBodyConquest()`: 全21筋肉に刺激記録があれば全身制覇
2. `markFirstWorkoutCompleted()`: `AppState.hasCompletedFirstWorkout = true`
3. `checkPRUpdates()`: セッション内の各種目の最大重量を過去記録と比較
4. `detectLevelUps()`: PR更新種目の前後レベルを StrengthScoreCalculator で比較
5. `scheduleRecoveryNotification()`: 最も遅い回復完了時刻で通知スケジュール

**結果: 正常**

### B-6. ホーム画面更新

`HomeViewModel.loadMuscleStates()`:
- `MuscleStateRepository.fetchLatestStimulations()` で最新の刺激データ取得
- 各筋肉に対して `RecoveryCalculator.recoveryStatus()` で回復ステータス判定
- `MuscleVisualState` に変換してマップ表示に反映

**結果: 正常**

---

## C. 回復計算の整合性

### Volume Coefficient（ボリューム係数）

| セット数 | 係数 | 回復時間倍率 |
|:---|:---|:---|
| 0以下 | 0.70 | 最短（安全策） |
| 1 | 0.70 | 軽刺激 |
| 2 | 0.85 | やや短い |
| 3 | 1.00 | 標準 |
| 4 | 1.10 | やや長い |
| 5+ | 1.15 | 最長（上限） |

**評価:** 段階的で医学的に妥当。上限キャップ（1.15x）により極端な回復時間を防止。Schoenfeld et al. (2016) のボリューム-回復関係と整合。

### Base Recovery Hours（基本回復時間）

| カテゴリ | 筋肉群 | 回復時間 |
|:---|:---|:---|
| 大筋群 (72h) | lats, trapsUpper, trapsMiddleLower, erectorSpinae, glutes, quadriceps, hamstrings, adductors, hipFlexors | 72時間 |
| 中筋群 (48h) | chestUpper, chestLower, deltoid系, biceps, triceps | 48時間 |
| 小筋群 (24h) | forearms, rectusAbdominis, obliques, gastrocnemius, soleus | 24時間 |

**評価:** 72h/48h/24h の3段階は一般的なスポーツ科学ガイドラインに準拠。胸が48h（中筋群）はやや議論の余地あり（W-4参照）。

### 回復進捗計算

```swift
static func recoveryProgress(...) -> Double {
    let elapsed = now.timeIntervalSince(stimulationDate) / 3600
    let needed = adjustedRecoveryHours(muscle: muscle, totalSets: totalSets)
    guard needed > 0 else { return 1.0 }
    return min(1.0, max(0.0, elapsed / needed))
}
```

- ゼロ除算ガード: あり
- クランプ: 0.0-1.0
- 線形回復モデル（現実は非線形だが、アプリとしては十分）

**結果: 正常**

### 回復ステータス判定の優先順位

```swift
if days >= 14 { return .neglectedSevere }
else if days >= 7 { return .neglected }
else if progress >= 1.0 { return .fullyRecovered }
else { return .recovering(progress: progress) }
```

**重要な挙動:** neglected 判定が fullyRecovered より**優先**される。つまり、7日以上前に刺激した筋肉は回復が完了していても `neglected` として紫で表示される。これは「長期間刺激していない筋肉への警告」として意図的な設計と推定。

### 回復ステータス → カラーマッピング

| RecoveryStatus | MuscleVisualState | カラー |
|:---|:---|:---|
| `.recovering(0.0-0.2)` | `.recovering(progress: 0.0-0.2)` | `#E57373` (赤/疲労) |
| `.recovering(0.2-0.8)` | `.recovering(progress: 0.2-0.8)` | 赤→黄→緑 グラデーション |
| `.recovering(0.8-1.0)` | `.recovering(progress: 0.8-1.0)` | `#81C784` (緑/回復済) |
| `.fullyRecovered` | `.inactive` | `#3D3D42` (灰/記録なし) |
| `.neglected` (7日+) | `.neglected(fast: false)` | `#B388D4` (紫/1.5秒パルス) |
| `.neglectedSevere` (14日+) | `.neglected(fast: true)` | `#B388D4` (紫/0.5秒パルス) |

**結果: 信号機パターン（赤→黄→緑）として直感的。正常**

---

## D. メニュー提案エンジンの整合性

### MenuSuggestionService.suggestTodayMenu() フロー

```
suggestTodayMenu(stimulations, exerciseStore)
    |
    |-- stimulations が空?
    |   |-- YES --> primaryGroupFromGoal()
    |   |   |-- goalPriorityMuscles[0] のグループ
    |   |   |-- フォールバック: splitParts(frequency).first?.muscleGroups.first ?? .chest
    |   |
    |   --> buildMenuForGroup(group, stimulations, exerciseStore)
    |
    |-- NO --> evaluateGroups(stimulations)
        |-- 各グループの回復スコア算出:
        |   |-- 刺激記録あり: recoveryProgress (0.0-1.0) を加算
        |   |-- 刺激記録なし: 2.0 を加算（最優先化）
        |-- グループ平均スコアが最高 → selectedGroup
        --> buildMenuForGroup(selectedGroup, stimulations, exerciseStore)
```

### buildMenuForGroup() の処理

1. `pairedGroups(for: primaryGroup)` でペアリンググループを取得
2. 各グループの筋肉に対する種目を `exerciseStore.exercises(targeting:)` で収集
3. 重複チェック、グループあたり最大3種目
4. `findNeglectedMuscle()` で7日+未刺激の筋肉があれば1種目追加
5. 最大6種目に制限

**結果: 正常**

### WorkoutRecommendationEngine.generateRecommendation() フロー

```
generateRecommendation(suggestedMenu, modelContext)
    |
    |-- pairedGroups を取得
    |-- 候補種目を収集（primaryMuscle がペアグループに属する種目のみ）
    |-- filterByLocation(location) でフィルタリング
    |   |-- "home" → 自重/ダンベル/ケトルベルのみ
    |   |-- "gym" / "both" → フィルタなし [★ W-1]
    |-- sortByPriority() でソート:
    |   |-- 1. お気に入り優先
    |   |-- 2. グループ適合度（targetGroups の筋肉への刺激度合計%）
    |   |-- 3. 重点筋肉スコア（goalPriorityMuscles への刺激度合計%）
    |-- 上位3種目を選出
    |-- buildRecommendedExercises():
        |-- 前回記録があれば: suggestedWeight = prev + increment (+2.5 or +1.25)
        |-- 前回記録なし: suggestedWeight = 0
        |-- defaultReps/Sets は trainingExperience に基づく
```

**結果: 正常（filterByLocation の "both" 問題を除く）**

### 初回ユーザー（stimulations空）のフォールバックパス

`generateFirstTimeRecommendation()`:
1. `goalPriorityMuscles[0]` → ターゲットグループ決定
2. goalPriorityMuscles が空 → `.chest` にフォールバック
3. `pairedGroups` → 種目収集 → フィルタ → ソート → 上位3種目
4. 前回記録なし → suggestedWeight = 0、defaultReps/Sets をトレ歴から決定

**結果: 正常。初回ユーザーでも必ずメニューが生成される**

### pairedGroups() のハードコードfallback問題

`MenuSuggestionService.pairedGroups(for:)` L153-170:
```swift
// まず splitParts から検索
if let matchingPart = parts.first(where: { $0.muscleGroups.contains(primary) }) {
    return matchingPart.muscleGroups
}
// フォールバック（パートが見つからない場合）
switch primary {
case .chest:     return [.chest, .arms]       // splitParts(3) では [.chest, .shoulders]
case .shoulders: return [.shoulders, .core]   // splitParts(3) では [.chest, .shoulders]
...
```

正常パスでは `splitParts` から動的に検索するため、フォールバックに到達するケースは「splitParts に primary が含まれないパートが存在しない場合」。全ての MuscleGroup は少なくとも1つの splitPart に含まれるため、**正常パスでは到達しない**。ただし防御的プログラミングとしてはフォールバック値が splitParts と整合していないのは懸念。

**結果: 実害は低いが、フォールバック値の不整合は修正推奨**

### findNeglectedMuscle() の限界

```swift
for muscle in Muscle.allCases {
    if let stim = stimulations[muscle] {
        let days = RecoveryCalculator.daysSinceStimulation(stim.stimulationDate)
        if days >= 7 { return muscle }
    }
    // stimulations に存在しない筋肉は完全に無視
}
```

一度も刺激されたことがない筋肉は `stimulations` ディクショナリに存在しないため検出されない。ただし、`evaluateGroups()` では未刺激筋肉にスコア 2.0 を付与するため、グループレベルでは適切に優先される。`findNeglectedMuscle` は追加の1種目を挿入するための補助機能であり、メイン提案ロジックには影響しない。

**結果: 設計上は許容範囲だが、完全性を求めるなら未刺激筋肉も neglected 候補に含めるべき**

---

## E. 課金ゲートの整合性

### isPremium チェック箇所（全箇所）

| ファイル | 行 | 用途 | 正常? |
|:---|:---|:---|:---|
| `PurchaseManager.swift` | L15-27 | 定義（RevenueCat entitlement "premium"） | -- |
| `ContentView.swift` | L57 | ワークアウトタブ遷移制限（canRecordWorkout） | 正常 |
| `HomeView.swift` | L78 | Strength Mapボタン表示制御 | 正常 |
| `HomeView.swift` | L125 | TodayRecommendationInline 表示制御 | 正常 |
| `HomeView.swift` | L222 | メニュー提案表示制御 | 正常 |
| `HomeHelpers.swift` | L84, 103, 106, 183 | 推薦カード・ルーティン開始制御 | 正常 |
| `WorkoutCompletionView.swift` | L212 | CompletionProBanner 表示 | 正常 |
| `SettingsView.swift` | L27, 125 | Proバナー・Pro表示 | 正常 |
| `AnalyticsMenuView.swift` | L92, 258, 326 | Strength Map・Pro機能 | 正常 |
| `ChallengeProgressBanner.swift` | L39 | 90日チャレンジ | 正常 |
| `HistoryMapComponents.swift` | L39 | 種目トレンド | 正常 |

**全ゲートポイントで PaywallView が正しく表示される。Pro機能の漏れなし。**

### canRecordWorkout ロジック

```swift
var canRecordWorkout: Bool {
    isPremium || weeklyWorkoutCount < 1
}
```

`ContentView.swift` でのゲート:
```swift
.onChange(of: appState.selectedTab) { oldValue, newValue in
    if newValue == 1 && !PurchaseManager.shared.canRecordWorkout {
        appState.selectedTab = oldValue
        showingPaywall = true
    }
}
```

**ゲートロジック自体は正常。ただし `incrementWorkoutCount()` 未呼出のため制限が永久に発動しない（C-1参照）。**

### incrementWorkoutCount() 呼び出し状況

```
$ grep -r "incrementWorkoutCount" MuscleMap --include="*.swift"
→ PurchaseManager.swift:112 のみ（定義箇所のみ、呼出し箇所ゼロ）
```

**致命的: 無料ユーザーの週間ワークアウト制限が完全に無効。**

### resetIfNewWeek() の年末境界問題

```swift
let lastWeek = calendar.component(.weekOfYear, from: lastReset)
let currentWeek = calendar.component(.weekOfYear, from: now)
if lastWeek != currentWeek { /* reset */ }
```

`weekOfYear` のみ比較し `yearForWeekOfYear` を比較していない。2026年の第52週と2027年の第1週で正しくリセットされない可能性がある。ただし、現時点では incrementWorkoutCount() が未呼出のため実害はない。

### DEBUG isPremium トグル

```swift
#if DEBUG
var debugOverridePremium: Bool? = true  // ★ デフォルト true
#endif
```

`#if DEBUG` で囲まれているため Release ビルドには含まれない。ただしデフォルト値が `true` であるため、開発中は常にPremium状態。QAが無料ユーザーフローをテストする際に見落とすリスクがある（W-5）。

---

## F. UserRoutine / RoutineManager の接続確認

### RoutineManager 参照一覧

| ファイル | 参照 | 用途 |
|:---|:---|:---|
| `RoutineManager.swift` | 定義 | Singleton マネージャー |
| `RoutineBuilderPage.swift` L325 | `RoutineManager.shared.saveRoutine()` | オンボーディング時のルーティン保存 |
| `RoutineCompletionPage.swift` L18 | `RoutineManager.shared.routine` | サマリー表示 |
| `HomeViewModel.swift` L44-53 | **`UserRoutine.load()` を直接使用** | 今日のルーティン読込（RoutineManager 不使用） |

### ロジック不整合の詳細（C-2）

**HomeViewModel.loadTodayRoutine() (L44-54):**
```swift
func loadTodayRoutine() {
    let routine = UserRoutine.load()  // UserDefaults直接読込
    guard !routine.days.isEmpty else { todayRoutine = nil; return }
    let weekday = Calendar.current.component(.weekday, from: Date())
    let index = (weekday - 1) % routine.days.count  // 曜日ベースの固定ローテーション
    todayRoutine = routine.days[index]
}
```

**RoutineManager.todayRoutineDay() (L33-66):**
```swift
func todayRoutineDay(modelContext: ModelContext) -> RoutineDay? {
    // 直近セッションの種目マッチング → 次のルーティン日を返す
    let lastExerciseIds = Set(lastSession.sets.map { $0.exerciseId })
    // どのルーティン日に最もマッチするか判定 → 次の日を返す（循環）
    let nextIndex = (bestIndex + 1) % routine.days.count
    return routine.days[nextIndex]
}
```

**比較:**
| 項目 | HomeViewModel | RoutineManager |
|:---|:---|:---|
| アルゴリズム | 曜日 % days.count | 直近セッション種目マッチング |
| 入力データ | 現在の曜日のみ | SwiftData のセッション履歴 |
| 賢さ | 固定ローテーション | 適応型（実際のトレーニング履歴に基づく） |
| 使用状況 | **HomeView で使用中** | **未使用（デッドコード）** |

**影響:** ユーザーがルーティンを順番通りにやらなかった場合（月曜スキップして火曜に Day1 を実施）、HomeView は翌日に Day3 を表示するが、RoutineManager なら Day2 を返す。

### ワークアウト開始時のルーティン種目プリセット

```
HomeView → TodayRecommendationInline「ルーティンを開始」タップ
  → onStartWithMenu()
    → AppState.pendingRecommendedExercises = exercises
    → appState.selectedTab = 1
      → WorkoutStartView.handlePendingRecommendation()
        → vm.startOrResumeSession()
        → vm.applyRecommendedExercises(exercises)
```

**結果: End-to-End で正常動作。RoutineManager を経由しなくても機能している。**

---

## 致命的問題の詳細と修正提案

### C-1: incrementWorkoutCount() 未呼出

**修正提案:**
`WorkoutViewModel.endSession()` の末尾に追加:
```swift
func endSession() {
    workoutRepo.endSession(session)
    updateWidgetAfterSession()
    PurchaseManager.shared.incrementWorkoutCount()  // ← 追加
}
```
または `WorkoutCompletionView.onAppear` の `markFirstWorkoutCompleted()` 直後に追加。

### C-2: ルーティン判定ロジックの二重実装

**修正提案:**
`HomeViewModel.loadTodayRoutine()` を `RoutineManager.todayRoutineDay(modelContext:)` に委譲:
```swift
func loadTodayRoutine() {
    todayRoutine = RoutineManager.shared.todayRoutineDay(modelContext: modelContext)
}
```
これにより HomeViewModel は modelContext を保持する必要があるため、初期化時に渡すか、別の方法で提供する。

### C-3: 目標選択の単一/複数仕様不整合

**修正提案（2つの選択肢）:**
- **選択肢A（実装を仕様に合わせる）:** `GoalSelectionPage` を `Set<OnboardingGoal>` に変更し、AppState に `selectedGoals` を追加。`GoalMusclePriority` を複数目標の筋肉合算に対応。
- **選択肢B（仕様を実装に合わせる）:** CLAUDE.md の「複数選択可（Set<OnboardingGoal>）」の記述を「単一選択」に修正。

---

## データフロー図（テキスト形式）

### オンボーディング → UserProfile → エンジン

```
GoalSelectionPage
  +--[tap]---> AppState.primaryOnboardingGoal (UserDefaults)
               |-- GoalMusclePreviewPage (プレビュー表示)
               |-- CallToActionPage (目標別コピー)
               |-- WorkoutCompletionView.completionGoalCopy (完了メッセージ)
               +-- GoalMusclePriority.data(for:) --> muscles
                    +---> UserProfile.goalPriorityMuscles (UserDefaults)
                          |-- MenuSuggestionService.primaryGroupFromGoal() [初回]
                          +-- WorkoutRecommendationEngine.sortByPriority() [優先度]

FrequencySelectionPage
  +--[onNext]---> UserProfile.weeklyFrequency (UserDefaults)
                  |-- WorkoutRecommendationEngine.splitParts(for:) --> 分割法
                  |-- MenuSuggestionService.pairedGroups(for:) --> ペアリング
                  |-- RoutineBuilderPage (Day数生成)
                  +-- CallToActionPage (週X回テキスト)

LocationSelectionPage
  +--[onNext]---> UserProfile.trainingLocation (UserDefaults)
                  +-- WorkoutRecommendationEngine.filterByLocation()
                       +- "home" のみフィルタ発動
                       +- "gym" / "both" = フィルタなし [★ W-1]

TrainingHistoryPage
  +--[select]---> UserProfile.trainingExperience (UserDefaults)
                  |-- shouldShowPRInput --> PRInputPage スキップ判定
                  +-- WorkoutRecommendationEngine.buildRecommendedExercises()
                       +- デフォルト reps/sets 決定

PRInputPage
  +--[入力]---> UserProfile.initialPRs (UserDefaults)
                +-- StrengthScoreCalculator.muscleStrengthScores() Step 1.5
                     +- exerciseBest1RM にフォールバックマージ

WeightInputPage
  +--[入力]---> UserProfile.weightKg / .nickname / .heightCm (UserDefaults)
                +-- StrengthScoreCalculator: strengthRatio = best1RM / bodyweight
                +-- heightCm: 未使用（将来のBMI計算用）

RoutineBuilderPage
  +--[保存]---> RoutineManager.shared.saveRoutine() --> UserRoutine (UserDefaults)
                +-- HomeViewModel.loadTodayRoutine() [曜日ベース]
                    [★ C-2: RoutineManager.todayRoutineDay() は未使用]
```

### ワークアウト記録フロー

```
WorkoutStartView
  +--[開始]---> WorkoutViewModel.startOrResumeSession()
  |             +-- WorkoutRepository.startSession() --> WorkoutSession [SwiftData]
  |
  +--[セット]---> WorkoutViewModel.recordSet()
  |               |-- WorkoutRepository.addSet() --> WorkoutSet [SwiftData]
  |               |-- PRManager.checkIsWeightPR() --> PR判定
  |               |-- updateMuscleStimulations()
  |               |    +-- MuscleStateRepository.upsertStimulation()
  |               |         --> MuscleStimulation [SwiftData]
  |               |         [★ W-3: totalSets が種目単位]
  |               +-- startRestTimer()
  |
  +--[終了]---> endSession()
                |-- WorkoutRepository.endSession() --> endDate設定
                |-- updateWidgetAfterSession()
                |-- [★ C-1: incrementWorkoutCount() 未呼出]
                +-- WorkoutCompletionView
                     |-- checkPRUpdates()
                     |-- detectLevelUps()
                     |-- scheduleRecoveryNotification()
                     +-- prepareShareImage() --> WorkoutShareCard
```

### 回復計算 → ホーム表示

```
HomeView [onAppear]
  +-- HomeViewModel.loadMuscleStates()
       +-- MuscleStateRepository.fetchLatestStimulations()
            --> [Muscle: MuscleStimulation]
            +-- RecoveryCalculator.recoveryStatus()
                 |-- recoveryProgress() = elapsed / adjustedRecoveryHours()
                 |    +-- adjustedRecoveryHours = baseRecoveryHours * volumeCoefficient(sets)
                 +-- 判定優先順位:
                      14日+ --> .neglectedSevere --> .neglected(fast: true)  紫高速パルス
                      7日+  --> .neglected       --> .neglected(fast: false) 紫低速パルス
                      回復完了 --> .fullyRecovered  --> .inactive             灰色
                      回復中  --> .recovering(%)    --> .recovering(progress) 赤黄緑グラデ
```

---

## 付録: UserProfile フィールド参照マップ

| フィールド | 書き込み箇所 | 読み出し箇所 | 備考 |
|:---|:---|:---|:---|
| `nickname` | WeightInputPage | WorkoutCompletionView (StrengthShareCard) | |
| `heightCm` | WeightInputPage | **未使用** | 将来のBMI計算用 |
| `weightKg` | WeightInputPage | StrengthScoreCalculator, WorkoutCompletionView | |
| `trainingExperience` | TrainingHistoryPage | OnboardingV2View (shouldShowPRInput), WorkoutRecommendationEngine (defaultReps) | |
| `initialPRs` | PRInputPage | StrengthScoreCalculator (Step 1.5) | 編集UIなし (W-7) |
| `weeklyFrequency` | OnboardingV2View | RoutineBuilderPage, MenuSuggestionService, WorkoutRecommendationEngine, CallToActionPage | |
| `trainingLocation` | OnboardingV2View | WorkoutRecommendationEngine.filterByLocation() | "both"未対応 (W-1) |
| `goalPriorityMuscles` | OnboardingV2View | MenuSuggestionService, WorkoutRecommendationEngine | |

---

## 修正優先度

### Priority 1: Must Fix（リリースブロッカー）

| # | 問題 | 修正箇所 |
|:---|:---|:---|
| C-1 | `incrementWorkoutCount()` を呼び出す | `WorkoutViewModel.endSession()` or `WorkoutCompletionView.onAppear` |
| C-2 | HomeViewModel を RoutineManager に委譲 | `HomeViewModel.loadTodayRoutine()` |

### Priority 2: Should Fix（品質向上）

| # | 問題 | 修正箇所 |
|:---|:---|:---|
| C-3 | 目標選択の仕様/実装整合 | `GoalSelectionPage.swift` or `CLAUDE.md` |
| W-1 | "both" 用のフィルタロジック追加 | `WorkoutRecommendationEngine.filterByLocation()` |
| W-3 | totalSets を筋肉ごとに合算 | `WorkoutViewModel.updateMuscleStimulations()` |

### Priority 3: Nice to Have

| # | 問題 | 修正箇所 |
|:---|:---|:---|
| W-2 | 週1回の選択肢追加 | `FrequencySelectionPage.swift`, `WorkoutRecommendationEngine.splitParts()` |
| W-4 | 胸の回復時間カテゴリ統一 | `Muscle.swift` or `StrengthScoreCalculator.swift` |
| W-5 | debugOverridePremium デフォルトを nil に | `PurchaseManager.swift` |
| W-6 | maxIntensity の利用方針明記 | コメント追加 |
| W-7 | PR入力値の編集UI追加 | 設定画面に新規画面追加 |

---

## 結論

致命的な問題3件のうち、**C-1（incrementWorkoutCount未呼出）** は課金収益に直接影響するため最優先で対応すべきである。無料ユーザーが無制限にワークアウトを記録できる状態が放置されている。

**C-2（ルーティン判定ロジックの二重実装）** はユーザー体験の一貫性に影響する。RoutineManager に賢いアルゴリズムが実装されているにもかかわらず使われておらず、曜日ベースの固定ローテーションが使われている。

**C-3（単一/複数選択の仕様不整合）** は仕様ドキュメントと実装のどちらを正とするかの意思決定が必要。現状の単一選択UIは完成度が高く機能的に問題ないため、CLAUDE.md を修正する方が現実的。

要注意の7件は、いずれも機能自体は動作するが、エッジケースやデータの正確性に影響する。特に **W-3（totalSets が種目単位）** は回復計算の精度に直結するため、中期的に改善すべきである。
