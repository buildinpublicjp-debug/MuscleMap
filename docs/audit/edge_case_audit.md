# MuscleMap Edge Case Audit Report

> **Audit Date:** 2026-03-18
> **Auditor:** Claude Code (Static Analysis)
> **Scope:** All `.swift` files under `/Users/og3939397/MuscleMap/MuscleMap/`, `/Users/og3939397/MuscleMap/Shared/`
> **Method:** Full-text Read of all source files + regex pattern scanning for crash-prone patterns

---

## Severity Summary

| Severity | Count | Description |
|:---------|:-----:|:------------|
| **Critical** | 2 | Data corruption or incorrect billing/limits affecting users |
| **High** | 5 | Potential crashes or significant data integrity issues |
| **Medium** | 9 | Performance degradation, boundary value errors, or subtle logic errors |
| **Low** | 7 | Minor UX inconsistencies or cosmetic issues |
| **Total** | **23** | |

---

## Critical Findings

### C-1: Double Increment of Weekly Workout Count (Data Integrity / Billing)

- **File:** `MuscleMap/Views/Workout/WorkoutStartView.swift:27-30` and `MuscleMap/ViewModels/WorkoutViewModel.swift:79`
- **Pattern:** Duplicate business logic call

**Description:**
When a workout is completed, `PurchaseManager.shared.incrementWorkoutCount()` is called **twice**:

1. Inside `WorkoutViewModel.endSession()` at line 79
2. In the `onWorkoutCompleted` callback in `WorkoutStartView` at line 30, which fires **after** calling `vm.endSession()` at line 27

```swift
// WorkoutStartView.swift:26-31
onWorkoutCompleted: { session in
    vm.endSession()                                    // <-- calls incrementWorkoutCount() internally
    HapticManager.workoutEnded()
    PurchaseManager.shared.incrementWorkoutCount()     // <-- called AGAIN
    completedSession = session
}
```

```swift
// WorkoutViewModel.swift:66-80
func endSession() {
    stopRestTimer()
    guard let session = activeSession else { return }
    workoutRepo.endSession(session)
    activeSession = nil
    exerciseSets = []
    updateWidgetAfterSession()
    PurchaseManager.shared.incrementWorkoutCount()     // <-- first call
}
```

**Impact:** Free users' weekly workout count is incremented by 2 instead of 1 per workout. Since the free tier limit is `weeklyWorkoutCount < 1` (i.e., 1 workout per week), this means the count goes from 0 to 2, which is functionally the same as going to 1 for the gate check. However, if the limit were ever increased (e.g., to 2 workouts per week), this bug would block users prematurely. More critically, this indicates a code quality issue where the same side effect is triggered from two separate ownership points with no guard.

**Reproduction:**
1. Start a workout as a free user
2. Record at least one set
3. Complete the workout
4. Check `UserDefaults.standard.integer(forKey: "weeklyWorkoutCount")` -- it will show 2 instead of 1

**Proposal:** Remove the `incrementWorkoutCount()` call from either `WorkoutViewModel.endSession()` or the `onWorkoutCompleted` callback in `WorkoutStartView`, not both. The ViewModel call is the more appropriate location since it encapsulates session lifecycle.

---

### C-2: No Active Session Recovery After App Kill

- **File:** `MuscleMap/Views/Workout/WorkoutStartView.swift:59-66`, `MuscleMap/ViewModels/WorkoutViewModel.swift:56-63`
- **Pattern:** State loss on process termination

**Description:**
When the app is force-killed during an active workout, `WorkoutSession` records remain in SwiftData with `endDate == nil` (i.e., `isActive == true`). On next launch, `WorkoutViewModel.startOrResumeSession()` does call `workoutRepo.fetchActiveSession()` which should find the orphaned session. However:

1. The `WorkoutStartView.viewModel` is `nil` until `onAppear`, and the check only runs when the user navigates to the workout tab.
2. If the user navigates to other tabs first, the orphaned session sits in the database.
3. The `WorkoutIdleView` (shown when `!vm.isSessionActive`) does not display any "resume previous session" prompt.
4. `startOrResumeSession()` silently resumes the orphaned session, but `exerciseSets` are populated from the old session's sets. If the user expects a fresh start, this can be confusing.

**Impact:** Orphaned sessions accumulate if the user repeatedly kills the app during workouts. The old session's sets persist and appear when the user next starts a workout, mixing old and new data. There is no UI to discard or explicitly resume an incomplete session.

**Reproduction:**
1. Start a workout and record some sets
2. Force-kill the app (swipe away from app switcher)
3. Relaunch and navigate to the workout tab
4. The previous session is silently resumed without any prompt

**Proposal:** On app launch or workout tab appearance, detect orphaned sessions (`endDate == nil`) and present a prompt: "You have an unfinished workout from [date]. Resume or Discard?"

---

## High Severity Findings

### H-1: Force Unwrap in Demo Data Seeding (DEBUG Only)

- **File:** `MuscleMap/App/MuscleMapApp.swift:131`
- **Pattern:** Force unwrap `!`

```swift
func daysAgo(_ d: Int) -> Date {
    cal.date(byAdding: .day, value: -d, to: now)!
}
```

**Description:** `Calendar.date(byAdding:value:to:)` returns `Date?`. While this is only in `#if DEBUG` code and the operation is highly unlikely to fail for simple day offsets, a force unwrap is still a crash risk if the calendar state is somehow invalid.

**Impact:** DEBUG builds could crash during demo data seeding. Since this runs at app launch for preview/testing, a crash here blocks all development.

**Proposal:** Replace with `cal.date(byAdding: .day, value: -d, to: now) ?? now`.

---

### H-2: Force Unwrap in HistoryViewModel

- **File:** `MuscleMap/ViewModels/HistoryViewModel.swift:384`
- **Pattern:** Force unwrap `!` after nil check

```swift
if lastWorkoutDate == nil || session.startDate > lastWorkoutDate! {
    lastWorkoutDate = session.startDate
}
```

**Description:** While the nil check before `||` prevents the force unwrap from being reached when `lastWorkoutDate` is nil (due to short-circuit evaluation), this pattern is fragile. If the condition is ever refactored (e.g., reordered or combined with `&&`), the force unwrap would crash.

**Impact:** Currently safe due to short-circuit evaluation, but high refactoring risk. Standard Swift style prefers `guard let` or `if let` over this pattern.

**Proposal:** Replace with `if let last = lastWorkoutDate { if session.startDate > last { ... } } else { lastWorkoutDate = session.startDate }`.

---

### H-3: Missing Bounds Check in RoutineEditView Delete/Move Operations

- **File:** `MuscleMap/Views/Settings/RoutineEditView.swift:199-206`
- **Pattern:** Array index access without bounds check

```swift
private func deleteExercises(at offsets: IndexSet) {
    days[selectedDayIndex].exercises.remove(atOffsets: offsets)  // No bounds check
    saveRoutine()
}

private func moveExercises(from source: IndexSet, to destination: Int) {
    days[selectedDayIndex].exercises.move(fromOffsets: source, toOffset: destination)  // No bounds check
    saveRoutine()
}
```

**Description:** Most other methods in `RoutineEditView` guard with `days.indices.contains(selectedDayIndex)`, but `deleteExercises` and `moveExercises` do not. If `days` is ever mutated concurrently (e.g., routine reset from settings) while the List is visible, `selectedDayIndex` could be out of bounds.

**Impact:** Index-out-of-bounds crash when `selectedDayIndex >= days.count`.

**Proposal:** Add `guard days.indices.contains(selectedDayIndex) else { return }` to both methods.

---

### H-4: Watch Connectivity -- PhoneSessionManager.modelContext Set Externally

- **File:** `MuscleMap/Connectivity/PhoneSessionManager.swift:12`
- **Pattern:** Externally settable optional dependency

```swift
var modelContext: ModelContext?
```

**Description:** `PhoneSessionManager.modelContext` is an optional property that must be set externally from a view's `onAppear`. If a Watch message arrives before the modelContext is set (e.g., during app launch before the UI is rendered), the data processor silently fails:

```swift
guard let modelContext = self.modelContext else {
    // message is silently dropped
    return
}
```

**Impact:** Watch-recorded workout data can be permanently lost if messages arrive before `modelContext` is set. `transferUserInfo` messages are queued by WatchConnectivity and delivered on session activation, which can happen before the UI lifecycle.

**Proposal:** Set `modelContext` during app initialization (e.g., in `MuscleMapApp.init` or a dedicated setup method) rather than relying on view lifecycle. Alternatively, queue received messages and process them once modelContext becomes available.

---

### H-5: Onboarding Progress Not Persisted Between Pages

- **File:** `MuscleMap/Views/Onboarding/OnboardingV2View.swift`
- **Pattern:** Ephemeral state loss

**Description:** The entire onboarding flow (up to 8 pages) is managed by `@State` properties in `OnboardingV2View`. Individual page selections (goal, frequency, location, training history) are saved to `UserProfile`/`AppState` as the user progresses, but the `currentPage` index is not persisted. If the user force-quits the app mid-onboarding:

1. `hasCompletedOnboarding` remains `false` (set only at the very end)
2. On relaunch, the user is sent back to the Splash screen
3. Previously saved data (e.g., goal selection from page 0) persists in UserDefaults, but the user sees the same pages again

**Impact:** Users who quit during the 8-page onboarding flow must restart from the beginning. Saved partial data in UserProfile creates a mismatch (e.g., goal is saved but the user is shown the goal selection page again with no pre-selection).

**Proposal:** Either persist `currentPage` to UserDefaults so the user can resume, or pre-populate selections from saved UserProfile data when re-entering the flow.

---

## Medium Severity Findings

### M-1: No fetchLimit on Large Data Queries

- **Files:**
  - `MuscleMap/Views/Home/HomeView.swift:310-311` -- `loadStrengthScores()` fetches ALL `WorkoutSet` records
  - `MuscleMap/ViewModels/MuscleJourneyViewModel.swift:163-168` -- `calculateSnapshot()` fetches ALL `MuscleStimulation` records before `targetDate`
  - `MuscleMap/ViewModels/MuscleHeatmapViewModel.swift:103` -- fetches ALL `WorkoutSession` records
  - `MuscleMap/ViewModels/MuscleBalanceDiagnosisViewModel.swift:182` -- fetches ALL `WorkoutSession` records
  - `MuscleMap/ViewModels/StreakViewModel.swift:80` -- fetches ALL `WorkoutSession` records
  - `MuscleMap/Views/MuscleDetail/MuscleDetailView.swift:324` -- fetches ALL `WorkoutSet` records for a muscle
- **Pattern:** Unbounded FetchDescriptor

**Description:** Several data-loading methods create `FetchDescriptor` without `fetchLimit`. For users with long training histories (e.g., 1+ year of daily workouts, ~10,000+ WorkoutSets, ~5,000+ MuscleStimulation records), these queries load all records into memory simultaneously.

**Impact:** Increasing memory usage and UI jank as the dataset grows. On older devices (iPhone SE, 3GB RAM), this could trigger memory pressure warnings or OOM kills. `HomeView.loadStrengthScores()` runs on every home screen appearance.

**Proposal:**
- For `loadStrengthScores()`: Fetch only the max-weight set per exercise (requires a more targeted query or post-fetch grouping with fetchLimit).
- For `MuscleJourneyViewModel.calculateSnapshot()`: Since only the latest stimulation per muscle is needed, add a per-muscle limit or query only the latest 21 records (one per muscle).
- Consider adding `fetchLimit` to all session/set queries in analytics ViewModels.

---

### M-2: 90-Day Challenge Day Calculation Does Not Account for DST

- **File:** `MuscleMap/App/AppState.swift:147-151`
- **Pattern:** Fixed-second day calculation

```swift
var challengeDay: Int {
    guard let start = challengeStartDate else { return 0 }
    let days = Int(Date().timeIntervalSince(start) / (24 * 60 * 60)) + 1
    return min(days, 90)
}
```

**Description:** Dividing `timeIntervalSince` by 86400 assumes every day has exactly 24 hours. During Daylight Saving Time transitions, a day can have 23 or 25 hours. This causes the day count to be off by 1 on the transition day.

**Impact:** On DST spring-forward day, `challengeDay` may skip a day (23h = 0.958 days, so day 2 could be reached late). On DST fall-back day, the same day number may be shown for two calendar days.

**Proposal:** Use `Calendar.current.dateComponents([.day], from: start, to: now).day` instead of `timeIntervalSince / 86400`.

---

### M-3: NotificationManager Schedules Without Permission Check

- **File:** `MuscleMap/Utilities/NotificationManager.swift`
- **Pattern:** Missing permission validation

**Description:** `scheduleRecoveryReminder` and `scheduleInactivityReminder` call `UNUserNotificationCenter.current().add(request)` without first checking if notification permission has been granted. If the user denied notification permission, these calls silently fail (the system ignores them), but this wastes processing and creates a false sense of functionality.

**Impact:** No crash, but notifications are scheduled without being deliverable. The app has no feedback mechanism to inform the user that notifications are not enabled. Also, the notification authorization check is only performed in `NotificationPermissionView` during onboarding.

**Proposal:** Check `UNUserNotificationCenter.current().notificationSettings()` before scheduling. If denied, skip scheduling and optionally prompt the user to re-enable in Settings.

---

### M-4: RoutineManager.todayRoutineDay() Default Index Logic

- **File:** `MuscleMap/Data/RoutineManager.swift:40-65`
- **Pattern:** Inaccurate default selection

**Description:** When determining which routine day to show today, the method fetches the last session, matches it to a routine day, and returns the next day in sequence. If no match is found (e.g., the user modified their routine after recording), it defaults to `bestIndex = 0`:

```swift
var bestIndex = 0
// ... matching logic ...
let nextIndex = (bestIndex + 1) % routine.days.count
return routine.days[nextIndex]
```

If the matching fails, `bestIndex` remains 0 and the user always gets `routine.days[1]` (the second day). This may not match the user's actual rotation.

**Impact:** Incorrect "today's routine" recommendation when the last workout's exercises don't match any routine day. Users see a potentially wrong training split suggestion.

**Proposal:** When no match is found, use a date-based rotation (e.g., `dayOfYear % routine.days.count`) or show a generic recommendation rather than defaulting to a fixed index.

---

### M-5: UserProfile.weightKg Used as Divisor Without Zero Guard

- **File:** `MuscleMap/Utilities/StrengthScoreCalculator.swift` (multiple locations)
- **Pattern:** Potential division by zero

**Description:** `StrengthScoreCalculator` computes `strengthRatio = estimated1RM / bodyweightKg`. The `bodyweightKg` comes from `AppState.shared.userProfile.weightKg`, which defaults to `70.0` in the model. However, the `ProfileEditSheet` allows the user to enter any positive value. If `weightKg` is somehow set to 0 (e.g., by a bug in profile editing), all strength ratio calculations produce `inf`.

Checking `PRInputPage`: `bodyweightKg` is computed with `weight > 0 ? weight : 70.0` (line 40-41), providing protection. But the main score calculator in `HomeView.loadStrengthScores()` reads `AppState.shared.userProfile.weightKg` directly.

**Impact:** If `weightKg` is 0, strength scores become `inf`, causing visual glitches in Strength Map (infinite stroke widths, NaN colors). The app may not crash but would display nonsensical data.

**Proposal:** Add `guard bodyweightKg > 0 else { return [:] }` at the top of `muscleStrengthScores()`, or clamp to a minimum (e.g., 30 kg).

---

### M-6: ImportDataConverter hasExistingSession() -- No fetchLimit on Duplicate Check

- **File:** `MuscleMap/Utilities/ImportDataConverter.swift:247-253`
- **Pattern:** Unbounded fetch for existence check

```swift
let descriptor = FetchDescriptor<WorkoutSession>(
    predicate: #Predicate { $0.startDate >= dayStart && $0.startDate < dayEnd }
)
return ((try? modelContext.fetch(descriptor))?.count ?? 0) > 0
```

**Description:** For each imported workout, a full fetch is performed to check for duplicates. If importing a large CSV (e.g., 365 days), this runs 365 separate fetch queries. Additionally, `fetch()` is used when `fetchCount()` would be more efficient for existence checking.

**Impact:** Import of large datasets is unnecessarily slow due to O(N) full fetches.

**Proposal:** Use `modelContext.fetchCount(descriptor) > 0` instead of `modelContext.fetch(descriptor)?.count ?? 0 > 0`. Also consider batching the duplicate check.

---

### M-7: Timer Thread Safety -- nonisolated(unsafe) restTimer

- **File:** `MuscleMap/ViewModels/WorkoutViewModel.swift:37`
- **Pattern:** Unsafe concurrency annotation

```swift
nonisolated(unsafe) private var restTimer: Timer?
```

**Description:** The `restTimer` is marked `nonisolated(unsafe)` to allow access from the Timer callback (which runs on the RunLoop thread). While the callback dispatches to `@MainActor` via `Task { @MainActor in }`, there is a theoretical race window between the Timer firing and the `@MainActor` Task executing. The `invalidate()` in `deinit` also runs on whatever thread deinit is called from.

**Impact:** Low probability of race condition in practice (since most access is on MainActor), but the `nonisolated(unsafe)` annotation explicitly opts out of Swift's concurrency safety guarantees.

**Proposal:** Consider using `MainActor.run` for timer invalidation in deinit, or restructure to use Swift Concurrency's `Task.sleep` pattern instead of `Timer.scheduledTimer`.

---

### M-8: ExerciseStore.load() Silently Fails on JSON Decode Error

- **File:** `MuscleMap/Repositories/ExerciseStore.swift:17-39`
- **Pattern:** Silent failure

**Description:** If `exercises.json` is corrupted or has an incompatible schema change, `load()` catches the error and only prints in DEBUG. The `exercises` array remains empty. All downstream code that calls `exerciseStore.exercise(for:)` returns `nil`, causing:

- Empty workout idle screen (no favorite/recent exercises shown)
- `selectExercise` silently fails
- Menu suggestions return empty
- Muscle stimulation updates are skipped

**Impact:** The app appears functional but is essentially broken -- no exercises are available. There is no user-visible error or recovery mechanism.

**Proposal:** Add a `loadError` state to `ExerciseStore` that can be observed by the UI to show an error banner. Consider a built-in fallback exercise set.

---

### M-9: Paywall Price Strings are Hardcoded

- **File:** `MuscleMap/Views/Paywall/PaywallView.swift:252-259`
- **Pattern:** Hardcoded pricing

```swift
private var yearlyPriceText: String { "¥4,900/年（月¥408）" }
private var monthlyPriceText: String { "¥590/月" }
```

**Description:** Prices are hardcoded in Japanese yen. They do not reflect the actual App Store product prices, which may vary by region, currency, and Apple's pricing tier adjustments. RevenueCat SDK provides `StoreProduct.localizedPriceString` for this purpose.

**Impact:** Users in non-Japanese locales see yen prices. If Apple adjusts pricing tiers, the displayed price won't match the actual charge. This could violate App Store Review Guidelines regarding accurate pricing display.

**Proposal:** Fetch product prices from RevenueCat at runtime and display `storeProduct.localizedPriceString`.

---

## Low Severity Findings

### L-1: RoutineBuilderPage exercisesForMuscleGroup Returns Empty Array Silently

- **File:** `MuscleMap/Views/Onboarding/RoutineBuilderPage.swift`
- **Pattern:** Empty state not communicated

**Description:** When `filterByLocation` returns no exercises for a muscle group (e.g., rare equipment configurations), the fallback logic falls through to an unfiltered list. However, if the unfiltered list is also empty (which can't happen with current 92 exercises but could with future data changes), the UI shows an empty list with no explanation.

**Impact:** Minimal with current data, but future-proof concern.

---

### L-2: ProfileEditSheet Does Not Validate Weight Range

- **File:** `MuscleMap/Views/Settings/SettingsView.swift:559`
- **Pattern:** Missing input validation

```swift
if let weight = Double(weightText), weight > 0 {
    profile.weightKg = weight
}
```

**Description:** The weight validation only checks `> 0`. A user could enter extremely high values (e.g., 99999 kg) or very low values (e.g., 0.001 kg). The onboarding `WeightInputPage` uses a Picker with a range of 40-160 kg, but the profile edit form uses a free-text `TextField`.

**Impact:** Extreme weight values would distort Strength Map scores. Very low weights would produce artificially high strength ratios.

**Proposal:** Add bounds check: `weight >= 30 && weight <= 300`.

---

### L-3: ColorCalculator Progress Boundary at Exactly 0.2, 0.4, etc.

- **File:** `MuscleMap/Utilities/ColorCalculator.swift:55-70`
- **Pattern:** Boundary value gaps

```swift
(progress - 0.2) / 0.2  // at progress=0.2, t=0
(progress - 0.4) / 0.2  // at progress=0.4, t=0
```

**Description:** The color interpolation function uses ranges like `0.0-0.2`, `0.2-0.4`, etc. At the exact boundary values (0.2, 0.4, 0.6, 0.8), the `t` parameter is 0.0, which means the color jumps to the next range's start. This creates a visual discontinuity at those exact values.

**Impact:** Barely perceptible visual artifact at exact boundary values. Progress values are floating-point, so exact boundaries are rare.

---

### L-4: AnalyticsMenuView Fetches Only Last 5000 Sets for Total Volume

- **File:** `MuscleMap/Views/Home/AnalyticsMenuView.swift:206-209`
- **Pattern:** Truncated aggregation

```swift
setsDescriptor.fetchLimit = 5000
let sets = (try? modelContext.fetch(setsDescriptor)) ?? []
totalVolume = sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
```

**Description:** The analytics summary limits fetching to the last 5000 sets. For power users who record 20+ sets per workout, 5 times a week, this covers only ~50 weeks. After that, the "Total Volume" statistic becomes inaccurate.

**Impact:** Long-term users see an underreported total volume. There is no indication that the number is approximate.

**Proposal:** Use a `fetchCount`-based approach or display "Last 5000 sets" qualification, or aggregate incrementally and cache.

---

### L-5: WatchDataProcessor countMuscleSets Minimum of 1

- **File:** `MuscleMap/Connectivity/WatchDataProcessor.swift:256`
- **Pattern:** Forced minimum

```swift
return max(count, 1) // 最低1セット
```

**Description:** Even if no sets match the muscle (which shouldn't happen given the calling context), the count is forced to at least 1. This is a defensive guard but could mask bugs where the muscle mapping is inconsistent between Watch and iPhone exercise data.

**Impact:** Recovery time calculations would use `volumeCoefficient(sets: 1)` = 0.7 instead of a more appropriate value if the actual count is wrong.

---

### L-6: MuscleStimulation Uses String for Muscle Instead of Enum

- **File:** `MuscleMap/Models/MuscleStimulation.swift`
- **Pattern:** Stringly-typed field

**Description:** `MuscleStimulation.muscle` is a `String` (the raw value of `Muscle` enum). All consumers must call `Muscle(rawValue: stim.muscle)` and handle the `nil` case where the string doesn't match any enum case. If a muscle is renamed or removed from the enum, orphaned stimulation records would become invisible.

**Impact:** No immediate crash, but data integrity risk if the Muscle enum evolves. Failed conversions silently skip records.

---

### L-7: YouTube Search Language Key Mismatch Risk

- **File:** `MuscleMap/Views/Settings/SettingsView.swift:18`
- **Pattern:** @AppStorage string key

```swift
@AppStorage("youtubeSearchLanguage") private var youtubeSearchLanguage: String = "auto"
```

**Description:** `@AppStorage` uses a raw string key. If this key is used elsewhere with a different default or type, it could cause inconsistencies. The key is only used in SettingsView, but there's no centralized key management.

**Impact:** Minimal. Only a concern if the key is duplicated elsewhere.

---

## Top 5 Subtle UX Issues

### UX-1: Free User Sees Workout Tab Blocked Without Understanding Why

- **File:** `MuscleMap/App/ContentView.swift:56-64`

When a free user has used their 1 weekly workout, tapping the Workout tab switches back to the previous tab and shows a PaywallView. There is no explanatory message like "You've reached your weekly limit." The PaywallView shows Pro upgrade messaging but doesn't explain the weekly limit context. Users may think the app is broken.

**Proposal:** Show a brief toast/alert explaining the weekly limit before presenting the paywall: "Free plan allows 1 workout per week. Upgrade to Pro for unlimited workouts."

---

### UX-2: Silently Resumed Workout After App Kill Creates Confusion

- **File:** `MuscleMap/ViewModels/WorkoutViewModel.swift:56-63`

As described in C-2, when an orphaned workout session is resumed without user acknowledgment, the user may see old sets from a previous workout mixed into what they think is a new session. There's no visual indicator that this is a resumed session.

**Proposal:** Show a banner "Resumed from [date]" or a confirmation dialog.

---

### UX-3: Onboarding Goal Selection Saved Immediately but No Pre-fill on Restart

- **File:** `MuscleMap/Views/Onboarding/GoalSelectionPage.swift:119`

`AppState.shared.primaryOnboardingGoal = goal.rawValue` is called on tap, saving the goal immediately. But if the user restarts onboarding (force quit and relaunch), the GoalSelectionPage shows no pre-selected goal despite one being saved. This creates cognitive dissonance.

**Proposal:** Pre-populate `selectedGoal` from `AppState.shared.primaryOnboardingGoal` in `onAppear`.

---

### UX-4: Strength Map Shows Zero State Without Clear CTA

- **File:** `MuscleMap/Views/Home/StrengthMapView.swift`

For new users who haven't recorded any workouts, the Strength Map shows all muscles with minimal/zero scores and an overall "D" grade. This can be discouraging. There's no onboarding-specific guidance like "Record your first workout to see your strength levels."

**Proposal:** Show a motivational empty state when all scores are 0, with a CTA to start a workout.

---

### UX-5: Rest Timer Continues Running After Workout Tab is Left

- **File:** `MuscleMap/ViewModels/WorkoutViewModel.swift:220-234`

The rest timer continues counting (and triggering haptic feedback) even when the user navigates away from the Workout tab. This is by design (the session remains active), but the compact timer badge is only visible on the workout screen. A user who switches to the Home tab won't know their rest timer completed.

**Proposal:** Consider a system notification or persistent banner when the rest timer completes while on another tab.

---

## Additional Observations

### Positive Patterns Noted

1. **Division by zero protection** is consistently applied across most analytics (using `guard !isEmpty`, `max(1, ...)`, or ternary checks).
2. **SwiftData fetchLimit** is used in most Repository methods, limiting memory impact for common operations.
3. **Timer invalidation** is properly handled in both `deinit` and `stopRestTimer()`.
4. **Bounds checking** with `days.indices.contains(selectedDayIndex)` is used in most RoutineBuilderPage access patterns.
5. **WatchConnectivity duplicate detection** prevents double-recording of sessions and sets synced from Watch.
6. **RecoveryCalculator** handles edge cases well (0 sets returns 0.7 coefficient, division by needed > 0 guard).

### Patterns That Were NOT Found (Positive)

- No `as!` force casts anywhere in the codebase
- No `.first!` or `.last!` force unwraps on collections
- No unguarded array subscript access by index (all use `.indices.contains` or safe access patterns)
- No unbounded recursion
- No retained `self` in closures without `[weak self]` (Timer uses `[weak self]`)

---

*End of Audit Report*
