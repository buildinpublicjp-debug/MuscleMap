# Localization Audit Report — 2026-03-20

## Summary
- Total .swift files: 119
- Japanese text detected in: 50 files
- Localized (isJapanese / L10n): majority
- **Unlocalized: 107 strings across 19 files**
  - Critical: 10 strings (4 files)
  - High: 21 strings (3 files)
  - Medium: 68 strings (8 files)
  - Low: 8 strings (4 files)
- Internal data (equipment filter keys, not display): 22 strings (5 files) -- excluded from counts

> **Impact:** 11% of DL are English-speaking users. Unlocalized Japanese on the splash, paywall, and workout completion screens will cause immediate churn before reaching the paywall.

---

## Critical (Billing / First Impression)

These strings are on the splash screen, paywall, or free-user upgrade gates. English users hit these strings before or during conversion.

| File | Line | Japanese Text | English Suggestion |
|---|---|---|---|
| SplashView.swift | 47 | `"鍛えた筋肉が光る。"` | "Your trained muscles light up." |
| SplashView.swift | 51 | `"あなたの体の変化を、目で見る。"` | "See your body's transformation." |
| SplashView.swift | 66 | `"始める"` | "Get Started" |
| ContentView.swift | 66 | `"今週の無料ワークアウト"` | "Free Workouts This Week" |
| ContentView.swift | 67 | `"Proにアップグレード"` | "Upgrade to Pro" |
| ContentView.swift | 70 | `"閉じる"` | "Close" |
| ContentView.swift | 72 | `"無料プランでは週1回まで..."` | "Free plan allows 1 workout/week. Upgrade to Pro for unlimited." |
| PaywallView.swift | 286 | `"¥4,900/年（月¥408）"` | "¥4,900/year (¥408/mo)" |
| PaywallView.swift | 291 | `"¥590/月"` | "¥590/month" |
| WorkoutCompletionSections.swift | 196 | `"Proを始める"` | "Start Pro" |

---

## High (Onboarding Flow)

English users see these during onboarding. Unlocalized text here causes confusion and abandonment before routine creation.

| File | Line | Japanese Text | English Suggestion |
|---|---|---|---|
| GoalSelectionPage.swift | 44 | `"Tシャツが似合う体に"` | "A body that fills out a T-shirt" |
| GoalSelectionPage.swift | 45 | `"存在感のある体で生きる"` | "Live with a commanding presence" |
| GoalSelectionPage.swift | 46 | `"パンチ力・タックル・組み力"` | "Punching power, tackling, grappling" |
| GoalSelectionPage.swift | 47 | `"ゴルフ飛距離、スイング速度"` | "Golf distance, swing speed" |
| GoalSelectionPage.swift | 48 | `"自信のある体が全てを変える"` | "A confident body changes everything" |
| GoalSelectionPage.swift | 49 | `"階段で息切れしない"` | "No more getting winded on stairs" |
| GoalSelectionPage.swift | 50 | `"家族のために"` | "For your family" |
| CallToActionPage.swift | 17 | `"あなたの体の変化を記録しよう。"` | "Track your body's transformation." |
| CallToActionPage.swift | 21-33 | 7x goal headlines (全て未ローカライズ) | (Same as RoutineCompletionPage EN texts) |
| CallToActionPage.swift | 91 | `"あなたの目標に合った筋肉を優先提案"` | "Prioritized muscle suggestions for your goal" |
| CallToActionPage.swift | 92 | `"種目・重量・セット数まで自動で出る"` | "Auto-generated exercises, weights & sets" |
| CallToActionPage.swift | 93 | `"週N回に最適化された分割法"` | "Split routine optimized for N days/week" |
| WeightInputPage.swift | 46 | `"身長"` | "Height" |
| WeightInputPage.swift | 69 | `"体重"` | "Weight" |
| WeightInputPage.swift | 126 | `"ニックネーム"` | "Nickname" |

> **Note:** CallToActionPage.swift is documented as "legacy (merged into RoutineCompletionPage)" but the file still exists. Verify if it's reachable. WeightInputPage.swift may also be superseded by ProfileInputPage inside TrainingHistoryPage.swift.

---

## Medium (Main App Screens)

Users who complete onboarding see these during regular use.

### WorkoutCompletionView.swift — Goal copy block (lines 301-309)

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 301 | `"全身、しっかり追い込んだ"` | "Full body, pushed hard" |
| 304 | `"胸板、また一段厚くなった"` | "Chest, thicker than ever" |
| 305 | `"背中の広がり、レベルアップ"` | "Back width, leveled up" |
| 306 | `"肩幅、また一歩広がった"` | "Shoulders, one step wider" |
| 307 | `"脚の土台、さらに強固に"` | "Leg foundation, even stronger" |
| 308 | `"腕、パンプした"` | "Arms, pumped up" |
| 309 | `"体幹、ブレない体へ"` | "Core, building a stable body" |
| 509 | `"トレーニング"` | "Training" |

### WorkoutCompletionSections.swift — Pro banner (lines 184-196)

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 184 | `"90日で体の変化を証明する"` | "Prove your transformation in 90 days" |
| 189 | `"Strength Map + 種目別グラフで成長を可視化"` | "Visualize growth with Strength Map + exercise charts" |

### HomeView.swift

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 148 | `"筋力レベルを見る"` | "View strength levels" |

### GoalMusclePriority.swift — All 7 goal data blocks (lines 71-135)

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 71 | `"大きい筋肉から鍛えれば効率最大"` | "Train big muscles first for max efficiency" |
| 73 | `"大胸筋"` / `"上半身のボリューム"` | "Pectorals" / "Upper body mass" |
| 74 | `"広背筋"` / `"背中の広がり"` | "Lats" / "Back width" |
| 75 | `"脚"` / `"体の60%の筋肉量"` | "Legs" / "60% of total muscle mass" |
| 81 | `"存在感は上半身の幅で決まる"` | "Presence is defined by upper body width" |
| 83 | `"三角筋"` / `"肩幅を広げる"` | "Deltoids" / "Widen your shoulders" |
| 84 | `"大胸筋"` / `"厚みを出す"` | "Pectorals" / "Add thickness" |
| 85 | `"僧帽筋"` / `"首回りの迫力"` | "Trapezius" / "Powerful neck presence" |
| 91 | `"打撃力は背中と脚から生まれる"` | "Striking power comes from back and legs" |
| 93 | `"広背筋"` / `"パンチの引き"` | "Lats" / "Punch retraction power" |
| 94 | `"脚"` / `"踏み込みの力"` | "Legs" / "Stepping-in power" |
| 95 | `"体幹"` / `"打撃の安定性"` | "Core" / "Strike stability" |
| 101 | `"パフォーマンスは下半身と体幹が土台"` | "Performance is built on lower body and core" |
| 103 | `"脚"` / `"爆発的なパワー"` | "Legs" / "Explosive power" |
| 104 | `"体幹"` / `"動きの安定性"` | "Core" / "Movement stability" |
| 105 | `"肩"` / `"腕の振りの起点"` | "Shoulders" / "Origin point for arm swing" |
| 111 | `"Tシャツ映えは胸と肩のシルエット"` | "T-shirt look is chest & shoulder silhouette" |
| 113 | `"大胸筋"` / `"胸板の厚み"` | "Pectorals" / "Chest thickness" |
| 114 | `"三角筋"` / `"肩のライン"` | "Deltoids" / "Shoulder line definition" |
| 115 | `"腹直筋"` / `"引き締まったウエスト"` | "Abs" / "A toned waist" |
| 121 | `"日常の動きは全部ここから"` | "All daily movements start here" |
| 123 | `"脚"` / `"階段・歩行の基盤"` | "Legs" / "Foundation for stairs & walking" |
| 124 | `"体幹"` / `"姿勢の維持"` | "Core" / "Posture maintenance" |
| 125 | `"背中"` / `"物を持つ力"` | "Back" / "Lifting & carrying strength" |
| 131 | `"抗老化に最も効くのは大筋群"` | "Large muscles are most effective against aging" |
| 133 | `"脚"` / `"転倒予防・代謝維持"` | "Legs" / "Fall prevention & metabolism" |
| 134 | `"背中"` / `"姿勢と骨密度"` | "Back" / "Posture & bone density" |
| 135 | `"体幹"` / `"腰痛予防"` | "Core" / "Lower back pain prevention" |

### WorkoutRecommendationEngine.swift — SplitPart names & schedule descriptions (lines 203-265)

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 203 | `"上半身"` / `"下半身"` | "Upper Body" / "Lower Body" |
| 216-219 | `"胸・肩・三頭"` / `"背中・二頭"` / `"脚"` / `"肩・腕"` | "Chest/Shoulders/Triceps" / "Back/Biceps" / "Legs" / "Shoulders/Arms" |
| 224-228 | `"胸"` / `"背中"` / `"脚"` / `"肩"` / `"腕"` | "Chest" / "Back" / "Legs" / "Shoulders" / "Arms" |
| 243-265 | Day abbreviations + part descriptions (月/火/水/木/金 + full descriptions) | Mon/Tue/Wed/Thu/Fri + English part names |

### AnalyticsMenuView.swift (lines 32-164)

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 32 | `"データ分析"` | "Data Analysis" |
| 37 | `"週間サマリー"` | "Weekly Summary" |
| 38 | `"今週どこを鍛えたか、ボリューム推移を確認"` | "See what you trained this week and track volume" |
| 48 | `"トレーニング頻度マップ"` | "Training Frequency Map" |
| 49 | `"過去90日間でどの部位を何回鍛えたか..."` | "See which muscles you trained over the past 90 days" |
| 57 | `"AI診断"` | "AI Diagnosis" |
| 62 | `"筋肉バランス診断"` | "Muscle Balance Diagnosis" |
| 63 | `"4軸・8タイプで体のアンバランスを可視化..."` | "Visualize imbalances across 4 axes. See what to fix" |
| 73 | `"マッスル・ジャーニー"` | "Muscle Journey" |
| 74 | `"記録開始からの筋肉変化の全記録..."` | "Full record of muscle changes since day one" |
| 82 | `"Pro機能"` | "Pro Features" |
| 88 | `"全21筋肉の発達レベルをスコア化..."` | "Score all 21 muscles by development level" |
| 106 | `"90日 Recap（近日公開）"` | "90-Day Recap (Coming Soon)" |
| 107 | `"90日間の変化をまとめた動画を自動生成..."` | "Auto-generate a video of 90 days of progress" |
| 108 | `"近日公開"` | "Coming Soon" |
| 119 | `"分析"` | "Analysis" |
| 148 | `"ワークアウト"` | "Workouts" |
| 156 | `"総ボリューム"` | "Total Volume" |
| 164 | `"活性筋肉部位"` | "Active Muscles" |

### HistoryMapComponents.swift (lines 69-524)

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 69 | `"種目別 重量推移"` | "Weight Progress by Exercise" |
| 73 | `"全期間"` | "All Time" |
| 88 | `"まずトレーニングを記録しよう"` | "Record your first workout" |
| 144 | `"重量データなし（体重のみの種目は表示されません）"` | "No weight data (bodyweight-only exercises not shown)" |
| 215 | `"PR達成"` | "PR Achieved" |
| 219 | `"最大重量"` | "Max Weight" |
| 232 | `"合計セット"` | "Total Sets" |
| 243 | `"ベスト"` | "Best" |
| 255 | `"成長率"` | "Growth Rate" |
| 261 | `"成長率"` | "Growth Rate" |
| 524 | `"全期間の種目別 重量推移グラフ"` | "All-time weight progress chart by exercise" |

### StrengthShareCard.swift — muscleJapaneseName() (lines 317-337)

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 317-337 | 21 muscle names (大胸筋上部, 広背筋, 僧帽筋, etc.) | Use `muscle.englishName` instead of hardcoded function |

### DayWorkoutDetailView.swift

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 197 | `"種目"` | "Exercises" |
| 241 | `"\(count)セット"` | "\(count) sets" |

### RoutineEditView.swift

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 23 | `"ルーティンがありません"` | "No routine found" |
| 25 | `"オンボーディングでルーティンを作成してください"` | "Create a routine during onboarding" |
| 45 | `"マイルーティン"` | "My Routine" |
| 312 | `"セット数"` | "Sets" |
| 343 | `"レップ数"` | "Reps" |
| 375 | `"セット・レップ編集"` | "Edit Sets & Reps" |

### HistoryViewModel.swift — HistoryPeriod enum

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 497 | `"7日"` | "7 Days" |
| 498 | `"30日"` | "30 Days" |
| 499 | `"全期間"` | "All Time" |

### StrengthMapView.swift

| Line | Japanese Text | English Suggestion |
|---|---|---|
| 69 | `"私の筋力マップ"` | "My Strength Map" |

---

## Low (Edge Cases / Debug / Errors)

| File | Line | Japanese Text | English Suggestion |
|---|---|---|---|
| SettingsView.swift | 90 | `"オンボーディングをリセットしました"` (DEBUG) | "Onboarding has been reset" |
| SettingsView.swift | 93 | `"アプリを再起動すると..."` (DEBUG) | "Restart the app to see onboarding again." |
| SettingsView.swift | 482 | `"オンボーディングをリセット"` (DEBUG) | "Reset Onboarding" |
| PurchaseManager.swift | 147 | `"購入情報を取得できませんでした..."` | "Unable to fetch purchase info. Please try again." |
| PurchaseManager.swift | 148 | `"対象のプランが見つかりませんでした。"` | "The target plan could not be found." |
| ImportDataConverter.swift | 18 | `"N件のワークアウトをインポート"` | "N workouts imported" |
| ImportDataConverter.swift | 19 | `"Nセットを追加"` | "N sets added" |
| ImportDataConverter.swift | 21 | `"未登録の種目: ..."` | "Unmatched exercises: ..." |
| ImportDataConverter.swift | 24 | `"N件の重複をスキップ"` | "N duplicates skipped" |
| ImportDataConverter.swift | 157 | `"保存エラー: ..."` | "Save error: ..." |
| MockFriendData.swift | 30-198 | 15 strings (names + exercises) | Use exercise IDs / English names |
| SetInputComponents.swift | 18 | `"自重"` (data comparison) | Use constant |
| RecordedSetsComponents.swift | 67 | `"自重"` (data comparison) | Use constant |

---

## Internal Data (Equipment Filter Keys -- Not Display Strings)

These match against `exercises.json` field values. Not user-visible, but should be centralized into a constant.

| File | Line(s) | Strings |
|---|---|---|
| LocationSelectionPage.swift | 38-40 | `"バーベル"`, `"マシン"`, `"ダンベル"`, `"ケーブル"`, `"自重"` |
| LocationSelectionPage.swift | 64, 95 | `"自重"`, `"ダンベル"`, `"ケトルベル"` (+ English equivalents -- OK) |
| GoalMusclePreviewPage.swift | 220 | `"自重"`, `"ダンベル"`, `"ケトルベル"` |
| RoutineBuilderPage.swift | 471, 702 | `"自重"`, `"ダンベル"`, `"ケトルベル"` |
| WorkoutRecommendationEngine.swift | 317 | `"自重"`, `"ダンベル"`, `"ケトルベル"` |
| WorkoutViewModel.swift | 101 | `"自重"` (+ "Bodyweight") |
| MuscleDetailViewModel.swift | 54 | `"自重"`, `"ダンベル"`, `"ケトルベル"` |
| RoutineEditView.swift | 439 | `"自重"`, `"ダンベル"`, `"ケトルベル"` |
| SetInputComponents.swift | 18 | `"自重"` |
| RecordedSetsComponents.swift | 67 | `"自重"` |

> **Recommendation:** Create `Equipment.bodyweight`, `.dumbbell`, `.kettlebell` constants that include both Japanese and English values for matching.

---

## Correctly Localized Files (No Action Needed)

The following files have all Japanese text properly wrapped in `isJapanese ? ... : ...` or `L10n` keys:

- RoutineCompletionPage.swift
- HomeHelpers.swift
- MenuPreviewSheet.swift
- FrequencySelectionPage.swift
- TrainingHistoryPage.swift (ProfileInputPage)
- PRInputPage.swift
- OnboardingView.swift / OnboardingV2View.swift
- NotificationPermissionView.swift / FavoriteExercisesPage.swift
- WorkoutStartView.swift / ActiveWorkoutComponents.swift
- ExercisePickerView.swift / WorkoutTimerComponents.swift / WorkoutInputHelpers.swift
- WorkoutIdleComponents.swift
- MuscleDetailView.swift
- HistoryView.swift

---

## Recommended Fix Pattern

```swift
// Before
Text("今日のメニュー")

// After
private var isJapanese: Bool {
    LocalizationManager.shared.currentLanguage == .japanese
}
Text(isJapanese ? "今日のメニュー" : "Today's Menu")
```

For data structures like GoalMusclePriority:
```swift
// Before
headline: "大きい筋肉から鍛えれば効率最大"

// After
headline: isJapanese
    ? "大きい筋肉から鍛えれば効率最大"
    : "Train big muscles first for max efficiency"
```

---

## L10n Key Migration Candidates (Frequently Repeated)

| Text Pattern | Occurrences | Recommended Key |
|---|---|---|
| `"種目"` (exercises) | 4+ | `L10n.exercises` (existing?) |
| `"セット"` (sets) | 3+ | `L10n.sets` |
| `"全期間"` (all time) | 3 | `L10n.allTime` |
| `"成長率"` (growth rate) | 2 | `L10n.growthRate` |
| `"Proを始める"` / `"Proにアップグレード"` | 2 | `L10n.startPro` / `L10n.upgradeToPro` |
| Equipment filter set (`"自重"`, `"ダンベル"`, `"ケトルベル"`) | 8 locations | `Equipment.homeFilterSet` constant |

---

## Priority Fix Order

1. **SplashView.swift** (3 strings) -- First screen every user sees
2. **ContentView.swift** (4 strings) -- Blocks free users from understanding upgrade gate
3. **PaywallView.swift** (2 strings) -- Pricing text on paywall
4. **GoalSelectionPage.swift** (7 strings) -- `localizedDescription` has zero EN branch
5. **WorkoutCompletionView.swift** (8 strings) -- Post-workout goal copy
6. **WorkoutCompletionSections.swift** (2 strings) -- Pro banner
7. **GoalMusclePriority.swift** (28 strings) -- Displayed in GoalMusclePreviewPage
8. **WorkoutRecommendationEngine.swift** (39 strings) -- SplitPart names flow into UI
9. **AnalyticsMenuView.swift** (19 strings) -- Full screen unlocalized
10. **HistoryMapComponents.swift** (11 strings) -- Charts and labels
11. **Remaining files** (RoutineEditView, DayWorkoutDetail, StrengthShareCard, etc.)
