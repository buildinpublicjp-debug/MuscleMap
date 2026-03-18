# MuscleMap UX Flow Audit Report

> **Date:** 2026-03-18
> **Method:** Code-only analysis (no simulator, no screenshots)
> **Scope:** 7 primary user flows, all Views/ViewModels

---

## Table of Contents

1. [Flow 1: First-Time User (DL -> First Workout)](#flow-1)
2. [Flow 2: Returning User Startup](#flow-2)
3. [Flow 3: Workout Recording](#flow-3)
4. [Flow 4: Calendar -> Past Workout Editing](#flow-4)
5. [Flow 5: Routine Editing (Settings)](#flow-5)
6. [Flow 6: Free User Restriction Experience](#flow-6)
7. [Flow 7: Strength Map -> Share](#flow-7)
8. [Friction Point Danger Ranking TOP 10](#top-10)

---

<a id="flow-1"></a>
## Flow 1: First-Time User (DL -> First Workout Completion)

### Navigation Path

```
MuscleMapApp.init()
  -> ContentView (hasCompletedOnboarding == false)
    -> OnboardingView [3 phases: splash -> mainFlow -> notification]
      -> SplashView                         [1.5s wait, tap "始める"]
      -> OnboardingV2View (TabView, pages 0-8)
        -> Page 0: GoalSelectionPage        [select 1/7, tap "次へ"]
        -> Page 1: FrequencySelectionPage   [select 1/4, tap "次へ"]
        -> Page 2: LocationSelectionPage    [select 1/3, tap "次へ"]
        -> Page 3: TrainingHistoryPage      [select 1/4, tap "次へ"]
        -> Page 4: PRInputPage              [conditional: 経験者のみ]
        -> Page 5: GoalMusclePreviewPage    [tap "次へ"]
        -> Page 6: WeightInputPage          [picker + nickname, tap "次へ"]
        -> Page 7: RoutineBuilderPage       [multi-day, min 1 exercise/day]
        -> Page 8: RoutineCompletionPage    ["無料ではじめる" or "Pro版を解放"]
      -> NotificationPermissionView         ["通知を許可" or "あとで"]
    -> MainTabView (Tab 0: HomeView)
      -> Coach mark overlay (first time)
      -> "今日のおすすめ" recommendation
      -> Tap recommendation -> Tab 1 (Workout)
      -> Start session -> Record sets -> Complete
```

### Operation Steps: 14+ taps minimum (splash -> goal -> frequency -> location -> history -> [PR] -> muscle preview -> weight -> routine build (multi-day) -> completion -> notification -> home -> start workout -> complete)

### Friction Points

| ID | Severity | Description | File:Line |
|----|----------|-------------|-----------|
| F1-1 | **CRITICAL** | Hard paywall trap: Tapping "Pro版を解放" on Page 8 opens `PaywallView(isHardPaywall: true)` as `.fullScreenCover`. Close button hidden, interactive dismiss disabled. User cannot return without purchasing, restoring, or force-quitting the app. | `RoutineCompletionPage.swift:130-155`, `PaywallView.swift:77,117` |
| F1-2 | HIGH | PR input (Page 4) hardcodes "kg" but unit preference isn't set until Page 6 (WeightInputPage). Imperial users enter incorrect values. | `PRInputPage.swift:297-299` |
| F1-3 | HIGH | TabView with `.page` style allows backward swiping. Users can revisit completed pages and overwrite previously saved state. No visible back button communicates this affordance. | `OnboardingV2View.swift:89` |
| F1-4 | MEDIUM | RoutineBuilderPage (Page 7) has no skip option. Users must add at least 1 exercise per day for all days. A 5-day user must review 5 exercise lists. | `RoutineBuilderPage.swift` |
| F1-5 | MEDIUM | WeightInputPage has no validation. Users can proceed with default 170cm/70kg, which affects Strength Score calculations. | `WeightInputPage.swift:154-180` |
| F1-6 | MEDIUM | PR level badges on Page 4 use default bodyweight 70kg (weight not yet entered). Badges may be inaccurate. | `PRInputPage.swift:39-42` |
| F1-7 | LOW | SplashView muscle animation fires `asyncAfter` callbacks that continue after view transition. Minor memory/animation leak. | `SplashView.swift:201-213` |
| F1-8 | LOW | GoalSelectionPage comment says "複数選択可" but implementation is single selection. | `GoalSelectionPage.swift:1,59` |
| F1-9 | LOW | FrequencySelectionPage minimum is 2/week. Users training 1x/week have no accurate option. | `FrequencySelectionPage.swift` |

### Empty State Handling: **Good** -- Each page has selection required before proceeding. RoutineBuilderPage has fallback if auto-pick finds no exercises.

### Error Handling: **Weak** -- All `try?` patterns in MuscleMapApp.swift silently swallow errors. Non-critical at this stage.

---

<a id="flow-2"></a>
## Flow 2: Returning User Startup

### Navigation Path

```
App launch -> ContentView (hasCompletedOnboarding == true) -> MainTabView (Tab 0)
  -> HomeView.onAppear:
    1. Initialize HomeViewModel (lazy, once)
    2. loadMuscleStates()           -- fetches ALL MuscleStimulation records
    3. checkActiveSession()         -- fetches incomplete session (unused in UI)
    4. loadTodayRoutine()           -- RoutineManager.todayRoutineDay()
    5. Generate recommendation      -- based on routine/recovery/premium status
    6. Streak calculation           -- synchronous on main thread
    7. Demo animation check         -- one-time flag
    8. Coach mark check             -- one-time flag
```

### Operation Steps: 0 taps (automatic on launch)

### Friction Points

| ID | Severity | Description | File:Line |
|----|----------|-------------|-----------|
| F2-1 | MEDIUM | Routine rotation uses single-session overlap matching. Ad-hoc workouts outside the routine confuse the rotation (always returns Day 2). | `RoutineManager.swift:49-65` |
| F2-2 | LOW | No loading indicator. HomeView body gated on `if let vm = viewModel`. Before init, blank screen with background color. Typically instantaneous but no spinner. | `HomeView.swift:32` |
| F2-3 | LOW | `fetchLatestStimulations()` fetches ALL MuscleStimulation records with no limit. O(n) in-memory dedup. Could grow large over months. | `MuscleStateRepository.swift:16-17` |
| F2-4 | LOW | `checkActiveSession()` result stored in `activeSession` but never used in HomeView body. Dead code. | `HomeViewModel.swift:118-120` |
| F2-5 | LOW | Free returning users (has history, not premium, no routine) get no `recommendedWorkout`. Falls to generic card or empty. | `HomeView.swift:221-234` |

### pendingRecommendedExercises Chain

```
HomeView "開始する" button
  -> AppState.pendingRecommendedExercises = exercises
  -> AppState.pendingRecommendationTrigger = UUID()
  -> AppState.selectedTab = 1
  -> WorkoutStartView.onChange(of: trigger) / .onAppear
    -> handlePendingRecommendation()
      -> vm.startOrResumeSession()
      -> vm.applyRecommendedExercises(exercises)
```

Dual trigger mechanism (onAppear + onChange) correctly handles both first-load and tab-switch scenarios.

### Empty State Handling: **Good** -- `TodayRecommendationInline` has 5 branches covering: routine, first-time, pro+recommendation, free user (blurred), and fallback.

### Error Handling: **Weak** -- `try?` at HomeView.swift:255,311 silently swallows errors.

---

<a id="flow-3"></a>
## Flow 3: Workout Recording Full Operations

### Navigation Path

```
Tab 1 (Workout) -> WorkoutStartView
  -> WorkoutIdleView (no active session)
    -> "Start" -> startOrResumeSession() -> ActiveWorkoutView
      -> Select exercise -> Set weight/reps
      -> recordSet() -> validation -> save -> PR check -> rest timer
      -> Repeat for all sets
      -> "End Workout" -> confirmation dialog -> endSession()
  -> WorkoutCompletionView (.fullScreenCover)
    -> Stats, PR display, share, muscle map, next recommended day
    -> Close -> return to WorkoutStartView
```

### Operation Steps: ~6 taps per set (select exercise + adjust weight + adjust reps + record)

### recordSet() Validation

| Check | Action on Failure | User Feedback |
|-------|-------------------|---------------|
| `activeSession == nil` | Returns `false` | **None** |
| `selectedExercise == nil` | Returns `false` | **None** |
| `currentReps < 1` | Returns `false` | **None** |
| `currentWeight < 0` | Clamped to 0 | Silent |

No upper bound on weight or reps. No user-visible error messages for any rejection.

### Friction Points

| ID | Severity | Description | File:Line |
|----|----------|-------------|-----------|
| F3-1 | **HIGH** | **Double increment bug:** `PurchaseManager.incrementWorkoutCount()` called in BOTH `WorkoutViewModel.endSession()` AND `WorkoutStartView.onWorkoutCompleted`. Free user count incremented 2x per workout. | `WorkoutStartView.swift:30`, `WorkoutViewModel.swift:79` |
| F3-2 | **HIGH** | **MuscleStimulation totalSets overwritten, not accumulated:** `updateMuscleStimulations()` sets `totalSets` to the count for the *current exercise* only. If Exercise A (3 sets) and Exercise B (2 sets) both target chest, chest's totalSets = 2 (last exercise), not 5 (cumulative). Affects recovery calculation accuracy. | `WorkoutViewModel.swift:355-368`, `MuscleStateRepository.swift:85` |
| F3-3 | MEDIUM | Silent validation failures in `recordSet()`. Returns `false` with no UI feedback. User taps "Record" and nothing happens. | `WorkoutViewModel.swift:167-170` |
| F3-4 | MEDIUM | All repository save errors silently swallowed in production. No retry UI, no error toast. If SwiftData save fails, set is lost. | `WorkoutRepository.swift` (all catch blocks) |
| F3-5 | MEDIUM | PR inconsistency: Real-time PR detection counts first-ever record as PR, but `getSessionPRUpdates()` on completion screen excludes first-time exercises (requires `previousMax > 0`). | `PRManager.swift:28-30` vs `PRManager.swift:64` |
| F3-6 | LOW | "Save and End" with 0 recorded sets is not prevented. Completion view shows 0 volume, 0 exercises, 0 sets. | `ActiveWorkoutComponents.swift:101-106` |
| F3-7 | LOW | `startSession()` returns session object even if `modelContext.save()` fails. Subsequent operations act on potentially unpersisted session. | `WorkoutRepository.swift:34-45` |

### Weight/Rep Persistence on Exercise Switch: **Well-designed**

- If sets recorded for this exercise in current session: restores last recorded set's values.
- Else if previous session history exists: uses first set of most recent session.
- Else: defaults to weight=0, reps=10.

### Rest Timer: **Well-implemented**

- Auto-starts after each `recordSet()`.
- Uses absolute time (`restTimerStartDate`) immune to Timer drift.
- Handles background recovery correctly via `recalculateRestTimerAfterBackground()`.
- Haptic warnings at 10s remaining and on completion.

### Error Handling: **Weak** -- Fire-and-forget persistence model. All errors silently discarded in production.

---

<a id="flow-4"></a>
## Flow 4: Calendar -> Past Workout Editing

### Navigation Path

```
Tab 2 (History) -> HistoryView
  -> Segmented picker: "Map" / "Calendar"
    -> Calendar -> MonthlyCalendarView
      -> Tap day cell -> DayWorkoutDetailView (.sheet)
        -> SessionDetailCard (per session)
          -> Tap set row -> HistorySetEditSheet (edit weight/reps)
          -> Long-press set -> Context menu (edit / delete)
          -> "..." menu -> Delete session
```

### Operation Steps

| Action | Taps from History tab |
|--------|----------------------|
| View day details | 2 (calendar segment + day cell) |
| Edit a set | 4 (segment + day + set row + save) |
| Delete a set | 5 (segment + day + long-press + delete + confirm) |
| Delete session | 4 (segment + day + "..." + delete + confirm) |

### Friction Points

| ID | Severity | Description | File:Line |
|----|----------|-------------|-----------|
| F4-1 | MEDIUM | Weight stepper fixed at 2.5kg increments with no direct input. Users with 1.25kg plates must tap many times. Cannot reach weight=0 by decrementing (but bodyweight exercises may start at 0). | `DayWorkoutDetailView.swift:496-498` |
| F4-2 | LOW | `HapticManager.error()` fires on successful deletion. Semantically misleading -- error haptic suggests something went wrong. | `DayWorkoutDetailView.swift:378,393` |
| F4-3 | LOW | `try?` silently swallows `loadDaySessions()` fetch errors. Empty state indistinguishable from "no workouts on this day" vs. actual error. | `DayWorkoutDetailView.swift:40` |
| F4-4 | LOW | MuscleStimulation recalculation uses delete-then-recreate pattern. Not atomic -- crash between delete and upsert leaves session with no stimulations. | `DayWorkoutDetailView.swift:403` + upsert loop |
| F4-5 | LOW | After all sessions deleted for a day, the sheet remains open showing empty state. User must manually dismiss. | `DayWorkoutDetailView.swift:48-56` |

### setNumber Renumbering: **Correct** -- Filters by exerciseId, sorts by current setNumber, reassigns sequential numbers starting from 1.

### MuscleStimulation Recalculation: **Correct** -- Unlike Flow 3's per-exercise totalSets, the history recalculation properly accumulates totalSets across all exercises targeting each muscle. This is the correct implementation.

### Empty State: **Good** -- Icon + text for no sessions. Auto-deletes session when last set removed.

### Error Handling: **Weak** -- All persistence operations use `try?`. No user-facing error notifications.

---

<a id="flow-5"></a>
## Flow 5: Routine Editing (Settings)

### Navigation Path

```
Tab 3 (Settings) -> SettingsView
  -> "My Routine" row (visible ONLY if RoutineManager.shared.hasRoutine)
    -> RoutineEditView (NavigationLink push)
      -> Day tab bar (Day 1, Day 2, ...)
      -> Exercise list (always in edit mode)
        -> Tap exercise -> RoutineExerciseEditSheet (sets/reps)
        -> Swipe to delete exercise (no confirmation)
        -> Drag to reorder
      -> "+" button -> RoutineEditExercisePickerSheet
```

### Operation Steps

| Action | Taps from Settings tab |
|--------|----------------------|
| View routine | 1 (tap "My Routine") |
| Edit exercise sets/reps | 3 (routine + exercise + save) |
| Add exercise | 3 (routine + "+" + select exercise) |
| Delete exercise | 2 (routine + swipe) |
| Reorder exercise | 2 (routine + drag) |

### Friction Points

| ID | Severity | Description | File:Line |
|----|----------|-------------|-----------|
| F5-1 | **HIGH** | "My Routine" row is completely hidden if no routine exists (`hasRoutine == false`). No way to create a routine from Settings. Only path is through onboarding. Dead-end for users who skipped or cleared their routine. | `SettingsView.swift:180` |
| F5-2 | **HIGH** | Days cannot be added, removed, or renamed from RoutineEditView. Users locked into the split created during onboarding. Want to change from 3-day to 4-day split? No path available. | `RoutineEditView.swift` (absent feature) |
| F5-3 | MEDIUM | HomeView's `todayRoutine` is not reactively updated when routines change in RoutineEditView. Requires navigating away and back to Home for `.onAppear` to re-fire. | `HomeViewModel.swift:45` |
| F5-4 | LOW | Exercise delete via swipe has no confirmation dialog (unlike history flow). Instant deletion. Arguably acceptable since exercises are easily re-added. | `RoutineEditView.swift:169-171` |
| F5-5 | LOW | `UserRoutine.save()` uses `try/catch` but only logs in `#if DEBUG`. Silent failure in production. | `UserRoutine.swift:63-71` |

### Save Mechanism: **Immediate** -- Every mutation (add, delete, move, edit) auto-saves via `RoutineManager.saveRoutine()`. No explicit "Save" button needed.

### Validation: **Good** -- Sets bounded 1-10, reps bounded 1-30. Duplicate exercise prevention. Max 8 exercises per day.

### Empty State: **Partially handled** -- Hidden row if no routine. `RoutineEditView` shows `ContentUnavailableView` with message to create via onboarding if somehow accessed with no days.

### Error Handling: **Mixed** -- Bounds checking is good; persistence error handling is weak.

---

<a id="flow-6"></a>
## Flow 6: Free User Restriction Experience

### Restriction Logic

```swift
// PurchaseManager.swift:107-108
var canRecordWorkout: Bool {
    isPremium || weeklyWorkoutCount < 1
}
```

**Limit:** 1 workout per week for free users.

### Weekly Reset

- Uses `Calendar.current.component(.weekOfYear, ...)` -- locale-dependent week start (Monday in ISO, Sunday in US).
- Correctly handles year boundaries via `yearForWeekOfYear`.
- Resets on first access after week number changes.

### Restriction Flow

```
Free user taps Workout tab (Tab 1)
  -> ContentView.onChange(of: selectedTab)
    -> if newValue == 1 && !canRecordWorkout
      -> Revert tab to previous
      -> Show PaywallView(isHardPaywall: false)
```

Mid-workout: **No interruption.** Once on the Workout tab, there is no mid-session restriction check. The user can finish their workout uninterrupted. Count incremented only after `endSession()`.

### Friction Points

| ID | Severity | Description | File:Line |
|----|----------|-------------|-----------|
| F6-1 | **HIGH** | **No remaining workout indicator.** No UI anywhere shows "0/1 workouts used this week" or "1 free workout remaining." Restriction is invisible until triggered. | Absent |
| F6-2 | **HIGH** | **Double increment bug** (shared with F3-1). `incrementWorkoutCount()` called twice per workout: once in `WorkoutViewModel.endSession()`, once in `WorkoutStartView.onWorkoutCompleted`. | `WorkoutStartView.swift:30`, `WorkoutViewModel.swift:79` |
| F6-3 | MEDIUM | **No explanation when blocked.** When free user taps Workout tab and is redirected, the paywall appears with no prior message explaining "You've used your 1 free workout this week." | `ContentView.swift:57-63` |
| F6-4 | LOW | Week start day is locale-dependent. Japanese users (Monday start) and US users (Sunday start) have different reset timing. | `PurchaseManager.swift:120` |
| F6-5 | LOW | `refreshPremiumStatus()` failure at launch is silent. Premium user with no network may appear as free until next refresh. | `PurchaseManager.swift:40-43` |

### PaywallView Hard vs Soft

| Aspect | Hard (`true`) | Soft (`false`) |
|--------|---------------|----------------|
| Close button | Hidden | Visible (xmark) |
| Interactive dismiss | Disabled | Enabled (swipe down) |
| Usage | Onboarding Page 8 | Tab restriction, Pro features |

### Error Handling: **Good** for purchase/restore flows (alerts shown). **Poor** for the restriction UX (no explanation, no counter).

---

<a id="flow-7"></a>
## Flow 7: Strength Map -> Share

### Navigation Path

```
HomeView (Tab 0)
  -> Pro user: Tap "Strength Map" button (1 tap)
    -> loadStrengthScores() -- fetches ALL WorkoutSets (no limit)
    -> StrengthScoreCalculator.muscleStrengthScores()
    -> StrengthMapView renders inline
    -> Share image pre-generated on .onAppear (ImageRenderer @3x)
    -> Tap ShareLink -> system share sheet
  -> Non-Pro user: Tap banner (1 tap)
    -> PaywallView(isHardPaywall: false)
```

### Operation Steps: 2 taps (Strength Map button + Share button)

### Score Calculation Edge Cases

| Scenario | Behavior | Result |
|----------|----------|--------|
| Zero data | All scores 0.0 | Grade "D", all muscles gray/inactive. No guidance message. |
| Only 1 exercise | Only mapped muscles have scores | Very low average. Few highlighted muscles. |
| bodyweightKg = 0 | Falls back to 70kg | `StrengthScoreCalculator.swift:223` |
| Exercise not in store | Silently skipped | Safe |

### Friction Points

| ID | Severity | Description | File:Line |
|----|----------|-------------|-----------|
| F7-1 | MEDIUM | **Unbounded fetch:** `loadStrengthScores()` fetches ALL WorkoutSets with no `fetchLimit`. For power users (1000+ sets), synchronous main-thread database fetch. | `HomeView.swift:310-311` |
| F7-2 | MEDIUM | **ImageRenderer on main thread:** Generates 1080x1920px image synchronously on every `.onAppear`. Could cause frame drops. | `StrengthMapView.swift:46-47` |
| F7-3 | LOW | Share card falls back to empty `UIImage()` if ImageRenderer fails. User would share a blank image with no error indication. | `StrengthShareCard.swift:351` |
| F7-4 | LOW | `ShareSheet.completionWithItemsHandler` ignores 4th parameter (error). Share errors silently swallowed. | `WorkoutCompletionComponents.swift:400` |
| F7-5 | LOW | No empty state guidance for Strength Map. With zero data, user sees a completely gray body map with "D" grade and no explanation. | `StrengthMapView.swift` (absent) |

### Error Handling: **Weak** -- `try?` for data fetch, silent fallback for ImageRenderer, error parameter ignored in ShareSheet.

---

<a id="top-10"></a>
## Friction Point Danger Ranking TOP 10

| Rank | ID | Severity | Description | Impact | Fix Complexity |
|------|----|----------|-------------|--------|----------------|
| **1** | F1-1 | CRITICAL | Hard paywall trap on onboarding Page 8. User taps "Pro版を解放" and cannot escape without purchasing or force-quit. | User abandons app entirely. 1-star review risk. | Low: Add close button or timeout to hard paywall. |
| **2** | F3-1 / F6-2 | HIGH | Double increment of `weeklyWorkoutCount`. Free user's single workout sets count to 2, not 1. If limit ever increases, effective allowance is halved. | Free user experience degraded. Business logic corrupted. | Low: Remove one of the two `incrementWorkoutCount()` calls. |
| **3** | F3-2 | HIGH | MuscleStimulation `totalSets` overwritten per-exercise, not accumulated. Last exercise targeting a muscle determines totalSets. Recovery calculations use incorrect data. | Core feature (recovery map) shows inaccurate recovery times. | Medium: Change `upsertStimulation` to accumulate totalSets or refactor to calculate cumulative in `updateMuscleStimulations()`. |
| **4** | F6-1 | HIGH | No UI shows remaining free workouts. User has no idea they have a weekly limit until the paywall appears. | Frustration, perceived as bug. High churn risk. | Low: Add "残り1回/週" badge on Workout tab or HomeView. |
| **5** | F5-1 / F5-2 | HIGH | Routine editing only accessible with existing routine. No way to create/add/remove routine days from Settings. Locked into onboarding split. | Users outgrow their initial split. No self-service recovery. | Medium: Add routine creation/day management in RoutineEditView. |
| **6** | F1-2 | HIGH | PR input page uses kg before unit preference is set. Imperial users enter incorrect values that affect Strength Score. | Bad initial data pollutes Strength Map accuracy. | Low: Move unit selector to before PR input, or add unit toggle on PR page. |
| **7** | F6-3 | MEDIUM | No explanation when Workout tab is blocked for free users. Paywall appears without context. | User confused why the tab stopped working. | Low: Add brief message above paywall: "今週の無料ワークアウトを使い切りました". |
| **8** | F3-3 | MEDIUM | `recordSet()` silent validation failures. Tapping "Record" with invalid state does nothing. No toast, no shake, no highlight. | User repeatedly taps button thinking it's broken. | Low: Add visual feedback (shake animation, toast). |
| **9** | F7-1 / F7-2 | MEDIUM | Unbounded WorkoutSet fetch + synchronous ImageRenderer on main thread. Both run on every Strength Map appearance. | Frame drops and UI hitches for power users. | Medium: Add fetchLimit or background rendering with loading state. |
| **10** | F4-1 | MEDIUM | Weight stepper in history edit fixed at 2.5kg increments with no freeform input. Tedious for small adjustments. | Editing a past set from 100kg to 60kg requires 16 taps. | Low: Add direct numeric input or configurable step size. |

---

## Cross-Cutting Observations

### Error Handling Pattern (All Flows)

The entire app follows a **"best effort" persistence model**. Every SwiftData operation uses `try?` or `do { } catch { #if DEBUG print }`. In production:

- **No user-facing error alerts** exist for save/fetch failures
- **No retry mechanism** for failed operations
- **No offline/corruption detection**
- If `modelContext.save()` fails, in-memory state diverges from persisted state. Data is lost on next app launch with no indication.

**Risk:** Low in practice (local SwiftData failures are rare), but when it happens, the user experience is silent data loss.

### Empty State Coverage

| Screen | Empty State | Quality |
|--------|-------------|---------|
| HomeView (no workouts) | Coach mark + recommendation | Good |
| HomeView (no routine) | Falls to generic recommendation | Adequate |
| Workout (no exercise selected) | EmptyWorkoutGuidance | Good |
| History Calendar (no data for day) | Icon + text | Good |
| Strength Map (no PR data) | Gray map + "D" grade, no guidance text | Poor |
| RoutineEditView (no routine) | Hidden from Settings entirely | Poor |
| Free user (limit reached) | Paywall with no explanation | Poor |

### Haptic Feedback Consistency

| Action | Haptic | Appropriate? |
|--------|--------|-------------|
| Set recorded | `.setCompleted()` (medium) | Yes |
| Workout ended | `.workoutEnded()` (heavy) | Yes |
| PR achieved | `.prAchieved()` (heavy x3) | Yes |
| Edit saved | `.lightTap()` | Yes |
| Set/session deleted | `.error()` | **No** -- error haptic for successful deletion is misleading |
| Stepper changed | `.stepperChanged()` (selection) | Yes |

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total friction points identified | 38 |
| CRITICAL severity | 1 |
| HIGH severity | 6 |
| MEDIUM severity | 12 |
| LOW severity | 19 |
| `try?` silent error sites | 15+ |
| Missing empty states | 3 |
| Missing loading indicators | 2 |
| Confirmed bugs | 2 (double increment, totalSets overwrite) |
