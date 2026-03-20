# Logic Deep Audit — 2026-03-20

> 対象: MuscleMapデータフロー全体（オンボーディング→メイン画面、推薦エンジン、計算ロジック、課金制御）
> 目的: エッジケース・ロジックバグ・データ不整合の網羅的洗い出し
> **コード変更なし — 読み取り専用分析**

---

## 目次

1. [Critical Issues](#1-critical-issues)
2. [High Issues](#2-high-issues)
3. [Medium Issues](#3-medium-issues)
4. [Low Issues](#4-low-issues)
5. [分析領域A: オンボーディングデータフロー](#5-分析領域a-オンボーディングデータフロー)
6. [分析領域B: WorkoutRecommendationEngine 分割法ロジック](#6-分析領域b-workoutrecommendationengine-分割法ロジック)
7. [分析領域C: StrengthScore計算 + 回復計算](#7-分析領域c-strengthscore計算--回復計算)
8. [分析領域D: 無料/有料制限ロジック](#8-分析領域d-無料有料制限ロジック)
9. [分析領域E: 前回監査の修正確認](#9-分析領域e-前回監査の修正確認)

---

## 1. Critical Issues

### CRIT-1: goalPriorityMuscles がスワイプ送りで保存されない

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Critical |
| **場所** | `Views/Onboarding/GoalSelectionPage.swift:205-215` |
| **概要** | `goalPriorityMuscles` は「次へ」ボタンタップ時のみ保存される。ユーザーがGoalSelectionPageで目標を選択後、スワイプで次ページに進んだ場合、`goalPriorityMuscles` は `[]` のまま |
| **影響範囲** | RoutineBuilderPage（種目優先度ソート）、WorkoutRecommendationEngine（おすすめ生成）、PaywallView（筋肉ハイライト）、MenuSuggestionService（ターゲットグループ選択）が全て空配列でフォールバック（`.chest` デフォルト） |
| **再現条件** | オンボーディングPage 0で目標タップ後、「次へ」を押さずにスワイプで右に進む |

### CRIT-2: GoalSelectionPage がスワイプ戻りで状態復元しない

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Critical |
| **場所** | `Views/Onboarding/GoalSelectionPage.swift:237-248` |
| **概要** | `selectedGoals` と `selectionOrder` は `@State` で管理されており、`onAppear` では復元されない。ユーザーがPage 1以降からスワイプ戻りした場合、選択済み目標が空欄で表示される。`primaryOnboardingGoal` はUserDefaultsに保存済みだが、UIに反映されない |
| **影響** | ユーザー混乱。再選択すると `primaryOnboardingGoal` と `goalPriorityMuscles` が上書きされるが、元の選択が見えないため意図しない変更リスク |

---

## 2. High Issues

### HIGH-1: Frequency=6 が default ケースに落ち、3日分のルーティンしか生成されない

| 項目 | 内容 |
|:---|:---|
| **深刻度** | High |
| **場所** | `Utilities/WorkoutRecommendationEngine.swift:230-233` |
| **概要** | `splitParts(for: frequency)` は frequency 2〜5 を明示的にハンドルするが、6 は `default` ケースに落ちて `splitParts(for: 3)` を再帰呼出し。3日間のPush/Pull/Legsしか生成されない |
| **影響** | FrequencySelectionPage は 2-6 を提供するが、6を選んだユーザーは3Day分しかRoutineBuilderに表示されない。期待する6Day分との乖離 |
| **補足** | frequency=1 と 7 も同様だが、UIの選択肢が2-6なので影響は frequency=6 のみ |

### HIGH-2: ワークアウトタブ滞在による無料ユーザー制限バイパス

| 項目 | 内容 |
|:---|:---|
| **深刻度** | High |
| **場所** | `App/ContentView.swift:68-76` |
| **概要** | `canRecordWorkout` チェックはタブ**遷移時**（`.onChange(of: appState.selectedTab)`）のみ実行。ワークアウトタブに既に滞在中のユーザーはセッション開始時にチェックされないため、1回完了後もタブを離れなければ無制限に記録可能 |
| **影響** | 無料ユーザーの週1回制限が実質無効化。収益への直接影響 |

---

## 3. Medium Issues

### MED-1: 3日分割でTricepsが「Pull」日に配置

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Utilities/WorkoutRecommendationEngine.swift:209-210` |
| **概要** | 3日分割の "Pull" パートに `.arms` グループが割り当てられており、triceps（push系筋肉）が Pull 日に配置される。生理学的にはtricepsはPush日（胸・肩と同日）が適切 |
| **影響** | トレーニング知識のあるユーザーに不自然な分割に見える。実効的な筋肉成長への影響は限定的 |

### MED-2: RevenueCat オフライン時のプレミアム状態永続化なし

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Utilities/PurchaseManager.swift:35-43` |
| **概要** | RevenueCat SDK キャッシュが空（初回起動 or クリア後）かつオフラインの場合、`_isPremium` は `false` のまま。課金済みユーザーが無料扱いになる |
| **影響** | 機内モードやネットワーク障害時に Pro 機能が一時的に使えなくなる |

### MED-3: 週次リセット日がデバイスロケール依存

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Utilities/PurchaseManager.swift:119-134` |
| **概要** | `resetIfNewWeek()` は `Calendar.current` を使用。`firstWeekday` はデバイスのロケールに依存し、US=日曜始まり、ISO 8601/日本=月曜始まり。CLAUDE.md は「月曜リセット」と記載だが、コードは強制していない |
| **影響** | ロケールによりリセットタイミングが異なる。USユーザーは日曜にリセット |

### MED-4: 4日分割のパート名とMuscleGroupの不一致

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Utilities/WorkoutRecommendationEngine.swift:216` |
| **概要** | Day 1 名称「胸・肩・三頭」だが実際のMuscleGroupは `.chest, .shoulders` のみ（`.arms` なし）。Triceps は Day 1 に含まれないにもかかわらず名前にある |
| **影響** | ユーザーへの誤解。名称と実際の種目構成が一致しない |

### MED-5: PaywallView にハードコード円価格

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Views/Paywall/PaywallView.swift:285-292` |
| **概要** | `"¥4,900/年（月¥408）"` と `"¥590/月"` がハードコード。RevenueCat offerings からの動的取得ではない |
| **影響** | 非JPY市場で誤った価格が表示される。App Store審査リスク |

### MED-6: StrengthScoreCalculator の overallLevel がコメントと乖離

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Utilities/StrengthScoreCalculator.swift:339-343` |
| **概要** | コメントは「median-based」だが実装は算術平均（`reduce(0, +) / Double(scores.count)`）。極端に高い/低いスコアに引っ張られる |
| **影響** | 1つだけ高いPR種目があると全体レベルが不当に上がる |

### MED-7: weeklyFrequency / trainingLocation がスワイプ送りで保存されない

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Views/Onboarding/OnboardingV2View.swift:37,44` |
| **概要** | `weeklyFrequency` と `trainingLocation` は各ページの `onNext` クロージャ内でのみ保存。スワイプで次ページに進んだ場合、デフォルト値（`3`, `"gym"`）が使用される |
| **影響** | デフォルト値が妥当なためCRITICALほどではないが、ユーザー意図と異なる設定でルーティンが構築されるリスク |

### MED-8: 複数セッション間の疲労蓄積なし

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Medium |
| **場所** | `Repositories/MuscleStateRepository.swift:15-37` |
| **概要** | 最新の刺激記録のみ使用。月曜に胸トレ→水曜にも胸トレの場合、月曜のデータは完全無視。回復未完了状態での再トレーニングによる累積疲労は反映されない |
| **影響** | 過剰トレーニングのリスクをユーザーに伝えられない |

---

## 4. Low Issues

### LOW-1: English equipment strings in homeEquipment filter が exercises.json と不一致

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | `Utilities/WorkoutRecommendationEngine.swift:317`, `Views/Onboarding/RoutineBuilderPage.swift:514`, `Repositories/ExerciseStore.swift:89` |
| **概要** | homeEquipment フィルタに `"Bodyweight"`, `"Dumbbell"`, `"Kettlebell"` が含まれるが、exercises.json は全て日本語（`"自重"`, `"ダンベル"`, `"ケトルベル"`）。English文字列は dead code |
| **影響** | 動作に影響なし（日本語文字列で正しくマッチ）。英語翻訳版の種目JSONが追加された場合のみ関連 |

### LOW-2: TrainingLocation.equipmentFilter が未使用

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | `Views/Onboarding/LocationSelectionPage.swift:44-51` |
| **概要** | `equipmentFilter` プロパティは定義されているが、どのファイルからも参照されていない。各ページが独自にフィルタSetをハードコード |
| **影響** | DRY違反。フィルタ変更時に4箇所以上の修正が必要 |

### LOW-3: Ab Roller が home フィルタから除外

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | `Resources/exercises.json:1113` |
| **概要** | Ab Roller の equipment が `"器具"` で、homeEquipment Set に含まれない。自宅トレーニング選択時に Ab Roller が候補から外れる |

### LOW-4: UserProfile/UserRoutine の保存失敗が無通知

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | `Models/UserProfile.swift:108-112`, `Models/UserRoutine.swift:80-84` |
| **概要** | `save()` の JSONEncoder 失敗は `#if DEBUG` 内のみログ出力。Production では無通知 |
| **影響** | 稀なケースだが、データ消失のデバッグが困難 |

### LOW-5: StrengthScore カテゴリの不整合

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | `Utilities/StrengthScoreCalculator.swift:184-209`, `Models/Muscle.swift:120-136` |
| **概要** | 回復計算とStrengthScore計算で筋肉の分類が異なる。例: 胸は StrengthScore=Category A(大筋群) だが 回復=48h(中筋群)。trapsUpper は StrengthScore=B だが回復=72h(大筋群)。hipFlexors は両方で大筋群扱いだが実際は小筋群 |

### LOW-6: getPreviousWeightPR の fetchLimit=10 ヒューリスティック

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | `Utilities/PRManager.swift:41` |
| **概要** | 現セッションで10セット以上全て過去最高を超えた場合、true previous PR を見逃す可能性 |

### LOW-7: オンボーディング後に weeklyFrequency / trainingLocation の編集UI なし

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | 設定画面全般 |
| **概要** | `trainingExperience` とルーティン編集は設定から可能だが、`weeklyFrequency` と `trainingLocation` は変更不可。変更にはオンボーディングリセットが必要 |

### LOW-8: generateRecommendation() に空候補ガードなし

| 項目 | 内容 |
|:---|:---|
| **深刻度** | Low |
| **場所** | `Utilities/WorkoutRecommendationEngine.swift:96` |
| **概要** | `generateFirstTimeRecommendation()` には `guard !candidateExercises.isEmpty` があるが、`generateRecommendation()` にはない。空の `RecommendedWorkout` が返る可能性 |

---

## 5. 分析領域A: オンボーディングデータフロー

### 5-1. データポイント一覧と永続化メカニズム

| データ | 保存先 | 保存タイミング | デフォルト値 |
|:---|:---|:---|:---|
| `primaryOnboardingGoal` | UserDefaults（直接） | GoalSelectionPageでタップ時 | `nil` |
| `goalPriorityMuscles` | UserProfile JSON | GoalSelectionPage「次へ」ボタン時 | `[]` |
| `weeklyFrequency` | UserProfile JSON | OnboardingV2View `onNext` クロージャ | `3` |
| `trainingLocation` | UserProfile JSON | OnboardingV2View `onNext` クロージャ | `"gym"` |
| `trainingExperience` | UserProfile JSON | TrainingHistoryPage タップ時（即時） | `.beginner` |
| `weightKg` | UserProfile JSON | TrainingHistoryPage ステッパー変更時 | `70.0` |
| `nickname` | UserProfile JSON | TrainingHistoryPage テキスト入力時 | `""` |
| `initialPRs` | UserProfile JSON | PRInputPage「次へ」ボタン時 | `[:]` |
| `UserRoutine` | UserDefaults JSON | RoutineBuilderPage「保存して完了」時 | empty days |

### 5-2. スワイプ操作時のデータ保存状態

| スワイプパス | 保存されないデータ | 影響 |
|:---|:---|:---|
| Page 0 → Page 1（スワイプ） | `goalPriorityMuscles` | **CRIT-1** |
| Page 1 → Page 2（スワイプ） | `weeklyFrequency` | デフォルト 3 が使用 |
| Page 2 → Page 3（スワイプ） | `trainingLocation` | デフォルト "gym" が使用 |
| Page 3 → Page 4/5（スワイプ） | `trainingExperience` は即時保存済み | 影響なし |

### 5-3. スワイプ戻り時のUI復元状態

| ページ | onAppear で復元? | 詳細 |
|:---|:---|:---|
| GoalSelectionPage | **NO** | `selectedGoals` / `selectionOrder` は空表示 → **CRIT-2** |
| FrequencySelectionPage | 未確認 | |
| LocationSelectionPage | 未確認 | |
| TrainingHistoryPage | **YES** | `onAppear` で `trainingExperience`, `weightKg`, `nickname` を復元 |
| PRInputPage | 未確認 | |

### 5-4. 読み取り側フォールバック

| データ | 読み取り箇所 | フォールバック |
|:---|:---|:---|
| `primaryOnboardingGoal` = nil | RoutineCompletionPage:86 | `"あなた専用プログラム完成"` |
| `primaryOnboardingGoal` = nil | PaywallView:25 | 空文字（サブタイトルなし） |
| `primaryOnboardingGoal` = nil | HomeHelpers:565 | `.getBig` 扱い |
| `goalPriorityMuscles` = [] | WorkoutRecommendationEngine:130 | `.chest` デフォルト |
| `goalPriorityMuscles` = [] | MenuSuggestionService:114-117 | `.chest` デフォルト |

---

## 6. 分析領域B: WorkoutRecommendationEngine 分割法ロジック

### 6-1. splitParts(for: frequency) 全出力

**場所:** `Utilities/WorkoutRecommendationEngine.swift:198-234`

| Frequency | 処理 | Day数 | 分割 | 全21筋肉カバー? | 問題 |
|:---|:---|:---|:---|:---|:---|
| 1 | default→3 | 3 | Push/Pull/Legs | Yes | UIで選択不可（2-6） |
| **2** | 明示 | 2 | 上半身/下半身 | Yes | なし |
| **3** | 明示 | 3 | Push/Pull/Legs | Yes | **MED-1** Triceps in Pull |
| **4** | 明示 | 4 | 胸肩/背腕/脚/肩腕 | Yes | **MED-4** 名称不一致 |
| **5** | 明示 | 5 | 胸/背/脚/肩/腕 | Yes | なし |
| **6** | default→3 | 3 | Push/Pull/Legs | Yes | **HIGH-1** 3日しか生成されない |
| 7 | default→3 | 3 | Push/Pull/Legs | Yes | UIで選択不可 |

### 6-2. autoPickExercises ソートパイプライン

**場所:** `Views/Onboarding/RoutineBuilderPage.swift:387-441`

1. **候補収集** — MuscleGroup内の各Muscleに対しExerciseStore.exercises(targeting:)で刺激度%降順取得。primaryMuscle.groupがtargetGroupSetに含まれる種目のみ
2. **場所フィルタ** — home: `{"自重","ダンベル","ケトルベル","Bodyweight","Dumbbell","Kettlebell"}`。空なら全種目をフォールバック
3. **優先度ソート** — (a)お気に入り → (b)グループ関連スコア → (c)目標筋肉スコア → (d)安定ソート
4. **上位N選択** — 2+グループ: 4種目、1グループ: 3種目

### 6-3. 場所フィルタの equipment 文字列分析

| exercises.json の equipment値 | 件数 | homeEquipment に含まれるか |
|:---|:---|:---|
| バーベル | 18 | NO |
| ダンベル | 20 | YES |
| ケーブル | 8 | NO |
| 自重 | 14 | YES |
| マシン | 22 | NO |
| 器具 | 1 | NO |
| ケトルベル | 1 | YES |

---

## 7. 分析領域C: StrengthScore計算 + 回復計算

### 7-1. StrengthScore 計算フロー

1. 全WorkoutSetから種目ごとの最大推定1RM（Epley式: `weight * (1 + reps / 30)`）を取得
2. onboarding PR (`initialPRs`) をマージ（より大きい値のみ）
3. `strengthRatio = best1RM / bodyweight`（bodyweight ≤ 0 なら 70.0 にフォールバック）
4. カテゴリ別閾値テーブルで 0.0〜1.0 スコア化
5. 同一筋肉に複数種目がある場合は最高スコア採用

### 7-2. カテゴリ閾値テーブル

**場所:** `Utilities/StrengthScoreCalculator.swift:108-137`

**Category A (compoundLarge):** chest_upper/lower, lats, traps_middle_lower, quadriceps, hamstrings, glutes, erector_spinae, hipFlexors

| strengthRatio | Score |
|:---|:---|
| 0 → 0.5 | 0.0 → 0.15 |
| 0.5 → 0.75 | 0.15 → 0.30 |
| 0.75 → 1.0 | 0.30 → 0.50 |
| 1.0 → 1.25 | 0.50 → 0.70 |
| 1.25 → 1.5 | 0.70 → 0.85 |
| > 1.5 | 1.0 |

**Category B (compoundMedium):** deltoid_anterior/lateral/posterior, traps_upper, biceps, triceps

| strengthRatio | Score |
|:---|:---|
| 0 → 0.3 | 0.0 → 0.15 |
| 0.3 → 0.5 | 0.15 → 0.35 |
| 0.5 → 0.7 | 0.35 → 0.55 |
| 0.7 → 0.9 | 0.55 → 0.75 |
| 0.9 → 1.1 | 0.75 → 0.90 |
| > 1.1 | 1.0 |

**Category C (isolation):** forearms, gastrocnemius, soleus, obliques, rectus_abdominis, adductors

| strengthRatio | Score |
|:---|:---|
| 0 → 0.2 | 0.0 → 0.15 |
| 0.2 → 0.35 | 0.15 → 0.35 |
| 0.35 → 0.5 | 0.35 → 0.55 |
| 0.5 → 0.65 | 0.55 → 0.75 |
| 0.65 → 0.8 | 0.75 → 0.90 |
| > 0.8 | 1.0 |

### 7-3. グレード/レベル閾値

| Score | Grade | Level |
|:---|:---|:---|
| ≥ 0.85 | S | freak |
| ≥ 0.70 | A+ | |
| ≥ 0.65 | | elite |
| ≥ 0.55 | A | |
| ≥ 0.40 | B+ | advanced |
| ≥ 0.30 | B | |
| ≥ 0.20 | C | intermediate |
| < 0.20 | D | beginner |

### 7-4. 回復計算 (RecoveryCalculator)

**場所:** `Utilities/RecoveryCalculator.swift`

**基本回復時間:**

| 分類 | 時間 | 筋肉 |
|:---|:---|:---|
| 大筋群 | 72h | lats, traps_upper, traps_middle_lower, erector_spinae, glutes, quadriceps, hamstrings, adductors, hip_flexors |
| 中筋群 | 48h | chest_upper, chest_lower, deltoid_anterior/lateral/posterior, biceps, triceps |
| 小筋群 | 24h | forearms, rectus_abdominis, obliques, gastrocnemius, soleus |

**ボリューム係数:**

| セット数 | 係数 |
|:---|:---|
| 0以下 | 0.70 |
| 1 | 0.70 |
| 2 | 0.85 |
| 3 | 1.00 |
| 4 | 1.10 |
| 5+ | 1.15 |

**回復進捗:** `progress = min(1.0, max(0.0, elapsed_hours / (base_hours * volume_coefficient)))` — 線形モデル

**未刺激警告:**
- 7-13日: `.neglected`（紫色表示）
- 14日+: `.neglectedSevere`（重度警告）

### 7-5. ゼロ除算リスク分析

全除算箇所を検証。**ゼロ除算リスクなし。** 全て適切にガードされている:

- `bodyweight` → 70.0 フォールバック（`StrengthScoreCalculator.swift:223,310`）
- `inverseLerp` → `guard scoreTo != scoreFrom`（`:176`）
- `overallLevel` → `guard !scores.isEmpty`（`:342`）
- `increasePercent` → `guard previousWeight > 0`（`PRManager.swift:107`）
- `recoveryProgress` → `guard needed > 0`（`RecoveryCalculator.swift:39`）

---

## 8. 分析領域D: 無料/有料制限ロジック

### 8-1. canRecordWorkout 判定式

**場所:** `Utilities/PurchaseManager.swift:107-108`

```
canRecordWorkout = isPremium || weeklyWorkoutCount < 1
```

無料ユーザー: 週1回のみ（count == 0 で許可、完了時に increment）

### 8-2. incrementWorkoutCount コールサイト

**現在の状態:** `WorkoutViewModel.endSession()` 内の1箇所のみ（`:80`）。正しく1回だけ呼出し。

### 8-3. ペイウォールトリガー一覧（12箇所）

**ハードペイウォール（1箇所）:**

| # | 場所 | ファイル:行 | トリガー |
|:---|:---|:---|:---|
| 1 | オンボーディング完了 | `RoutineCompletionPage.swift:189-190` | 「Pro版を解放」タップ |

ハードペイウォールのエスケープ: PaywallView内で3秒後に「Continue for Free」ボタン表示（`:327-338`）

**ソフトペイウォール（11箇所）:**

| # | 場所 | ファイル:行 | トリガー |
|:---|:---|:---|:---|
| 2 | ワークアウトタブゲート | `ContentView.swift:84,93-94` | 無料ユーザーが制限到達後にタブ遷移 |
| 3 | Strength Map バナー | `HomeView.swift:131-132,289-290` | 無料ユーザーがバナータップ |
| 4 | 今日のメニュー（ブラー版） | `HomeView.swift:93-94,289-290` | 無料ユーザーがメニューカードタップ |
| 5 | ルーティン開始ロック | `HomeHelpers.swift:243-244` | 無料ユーザーがロックボタンタップ |
| 6 | 90日チャレンジ | `ChallengeProgressBanner.swift:44` | 無料ユーザーがStart タップ |
| 7 | ワークアウト完了Proバナー | `WorkoutCompletionView.swift:213-214,258-259` | 完了後Proバナータップ |
| 8 | 履歴トレンドバナー | `HistoryView.swift:67,106-107` | 無料ユーザーがバナータップ |
| 9 | 分析メニュー Strength Map | `AnalyticsMenuView.swift:99,137` | 無料ユーザーがメニュー項目タップ |
| 10 | 分析メニュー 90日Recap | `AnalyticsMenuView.swift:111,137` | 全ユーザー（coming soon） |
| 11 | 設定 Pro バナー | `SettingsView.swift:414,63-64` | Proバナータップ |
| 12 | 設定 Pro セル | `SettingsView.swift:148,63-64` | Pro行タップ |

### 8-4. 無料ユーザーの機能アクセス一覧

| 機能 | アクセス | 備考 |
|:---|:---|:---|
| 回復マップ（ホーム） | ○ | 無条件表示 |
| ワークアウト記録 | △ | 週1回制限 + タブゲートバイパス |
| 種目辞典 | ○ | 無条件表示 |
| 履歴（マップ+カレンダー） | ○ | 閲覧のみ |
| 設定 | ○ | 無条件表示 |
| Strength Map | × | Proバナー表示 |
| 今日のメニュー（詳細） | × | ブラー表示 |
| ルーティン開始 | × | ロックボタン |
| 履歴トレンドグラフ | × | Proバナー表示 |
| ワークアウト完了シェア | ○ | 無条件表示 |
| 分析4画面 | ○ | 無条件表示 |

### 8-5. RevenueCat 統合

- Entitlement key: `"premium"`
- `_isPremium` 更新タイミング: 起動時（`refreshPremiumStatus()`）、購入後、復元後、Delegate リアルタイム通知
- **DEBUG オーバーライド:** `debugOverridePremium: Bool? = nil`（現在は nil = 実値使用。以前の true デフォルトは修正済み）

---

## 9. 分析領域E: 前回監査の修正確認

### 対象: `onboarding_logic_audit_0320.md` の H-L1 〜 C-3

| ID | 内容 | ステータス | 詳細 |
|:---|:---|:---|:---|
| **H-L1** | `selectionOrder` 配列で目標選択順序を保持 | **FIXED** | `GoalSelectionPage.swift:62` に `@State selectionOrder` 定義。`:175-189` でタップ順管理、`:205-215` で順序保持の `goalPriorityMuscles` 保存 |
| **H-L2** | GoalMusclePreviewPage での `goalPriorityMuscles` 上書き除去 | **FIXED** | grep 確認: GoalMusclePreviewPage に `goalPriorityMuscles` への書き込みゼロ。読み取り専用ページ |
| **H-L3** | Equipment filter バイリンガル化 | **PARTIAL** | `equipmentFilter` プロパティは日英切替対応したが、**そもそも未使用の dead code**。実際のフィルタリングは各ページでハードコードされた bilingual Set で正しく動作 |
| **C-1** | RoutineBuilderPage `locationPicker` Binding ガード | **FIXED** | `:258-265` に `days.indices.contains(selectedDayIndex)` ガード。get/set 両方 + ファイル全体の配列アクセスにガード追加済み（8箇所以上） |
| **C-2** | `startSession()` nil ハンドリング | **FIXED** | `WorkoutRepository.startSession()` → `Optional<WorkoutSession>` 返却、失敗時 cleanup + nil。`WorkoutViewModel:62` に `guard activeSession != nil else { return }` |
| **C-3** | `deleteSet()` アトミシティ | **PARTIAL** | Repository に try/catch 追加済み（`:145-151`）。ただし: (1)削除前の存在チェックなし (2)エラーがViewModelに伝播しない (3)delete→renumber→stimulation更新の3段階がアトミックでない |

**総合: 4/6 FIXED、2/6 PARTIALLY FIXED**

---

## 付録: 修正優先度マトリクス

| ID | 深刻度 | 影響範囲 | 修正工数 | 推奨優先度 |
|:---|:---|:---|:---|:---|
| CRIT-1 | Critical | 全ルーティン/推薦 | 小 | **P0** |
| CRIT-2 | Critical | UX | 小 | **P0** |
| HIGH-1 | High | frequency=6 ユーザー | 小 | **P0** |
| HIGH-2 | High | 収益 | 中 | **P1** |
| MED-1 | Medium | 3日分割ユーザー | 小 | P2 |
| MED-2 | Medium | オフラインPro | 中 | P2 |
| MED-3 | Medium | USロケール | 小 | P2 |
| MED-4 | Medium | 4日分割表示 | 小 | P2 |
| MED-5 | Medium | 非JPY市場 | 中 | P1（審査前必須） |
| MED-6 | Medium | Strength Map | 小 | P3 |
| MED-7 | Medium | スワイプ操作 | 小 | P1 |
| MED-8 | Medium | 回復精度 | 大 | P3 |
| LOW-1〜8 | Low | 限定的 | 小〜中 | P3 |
