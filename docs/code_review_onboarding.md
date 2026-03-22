# Code Review: Onboarding + Paywall + ContentView

> **Date:** 2026-03-22
> **Scope:** 16 files — Views/Onboarding/ (14), PaywallView.swift, ContentView.swift
> **Related:** PurchaseManager.swift, AppState.swift, WorkoutViewModel.swift, LocalizationManager.swift

---

## Summary

| Severity | Count | Description |
|----------|-------|-------------|
| **Critical** | 8 | Crash/data-loss/false-advertising risks |
| **High** | 20 | UX breakage, localization failures, billing logic issues |
| **Medium** | 33 | Performance, documentation drift, minor logic issues |
| **Low** | 33 | Cosmetic, dead code, defensive programming |
| **Total** | **94** | |

---

## CRITICAL (8)

### C-1: Page flow mismatch between code and CLAUDE.md
- **File:** `OnboardingV2View.swift:94-144`
- Code has 9 pages (0-8). CLAUDE.md documents 8 pages with different ordering. `GoalMusclePreviewPage` is included in CLAUDE.md but is actually dead code (never referenced in OnboardingV2View's page switch). NotificationPermissionView is at page 7, RoutineCompletionPage at page 8 — contradicts CLAUDE.md order.
- **Impact:** Developers relying on CLAUDE.md will implement incorrect page logic.
- **Fix:** Update CLAUDE.md to match actual code flow.

### C-2: `currentPage` can go negative via `goBack()`
- **File:** `OnboardingV2View.swift:166`
- `goBack()` decrements `currentPage` without a lower-bound guard. The back button is hidden at page 0, but programmatic calls at page 0 produce `currentPage = -1`, rendering an irrecoverable `EmptyView`.
- **Fix:** Add `guard currentPage > 0 else { return }` at the top of `goBack()`.

### C-3: Timer captures mutable @State in struct views
- **Files:** `GoalMusclePreviewPage.swift:309-312`, `PRInputPage.swift:577-592`, `RoutineCompletionPage.swift:441-445`
- `Timer.scheduledTimer` closures capture `[self]` or access `@State` properties. Struct `self` is a value type — the closure holds a stale copy. Works today due to SwiftUI's internal reference-backed `@State` storage, but this is undocumented behavior that could break in future SwiftUI versions.
- **Impact:** Potential stale state, timer leaks, or crashes on SwiftUI internals change.
- **Fix:** Move timer logic into an `@Observable` class or use `.task` + `AsyncStream`.

### C-4: Timer not explicitly scheduled on main RunLoop
- **File:** `RoutineCompletionPage.swift:441`
- `Timer.scheduledTimer` schedules on the current RunLoop. Currently called from `DispatchQueue.main.asyncAfter` (main RunLoop), but if the call path changes, the timer fires on a background thread causing UI updates off-main.
- **Fix:** Use `RunLoop.main.add(timer, forMode: .common)` explicitly.

### C-5: CLAUDE.md weekly workout limit says 1, code says 2
- **Files:** `PurchaseManager.swift:101`, `PaywallView.swift:266`, `CLAUDE.md`
- CLAUDE.md: `canRecordWorkout: isPremium || weeklyWorkoutCount < 1`
- Code: `weeklyFreeLimit = 2`
- L10n key `pwOncePerWeek` displays "2/wk". Code and UI are internally consistent (limit=2), but CLAUDE.md is wrong and the L10n key name is deceptive.
- **Fix:** Update CLAUDE.md to `weeklyWorkoutCount < 2`. Rename `pwOncePerWeek` to `pwTwicePerWeek`.

### C-6: PaywallView "Routines" row shows "2/wk" for free tier but no such limit exists in code
- **Files:** `PaywallView.swift:269-271`, `RoutineManager.swift`
- The comparison table advertises free users can use routines "2 times per week," but **no code enforces a weekly routine usage limit**. Free users can use routines unlimited times (only workout recording is limited).
- **Impact:** False advertising — potential App Store review rejection.
- **Fix:** Either implement the limit or change the comparison row to show the actual restriction (e.g., "2 workouts/wk" instead of "routines 2/wk").

### C-7: Timer leak risk in WeightInputSheet (PRInputPage)
- **File:** `PRInputPage.swift:577-592`
- `Timer.scheduledTimer` with `@State private var holdTimer` has a race condition: long press ending and sheet dismissal can overlap. The timer closure accesses `weight` (`@State`) from a non-main-actor context before dispatching to `@MainActor`, which is a data race under strict concurrency.
- **Fix:** Invalidate timer in `onDisappear`. Use `@MainActor` closure or `.task` pattern.

### C-8: PRInputPage timer capture race condition
- **File:** `PRInputPage.swift:577-592`
- Related to C-7: if the sheet dismisses while the timer is running, the timer callback writes to a `@State` property of a potentially deallocated view. The `holdTimer?.invalidate()` in the gesture's `onEnded` is not guaranteed to fire if the gesture is interrupted.
- **Fix:** Add `onDisappear { holdTimer?.invalidate() }`.

---

## HIGH (20)

### H-1: `isProceeding` never reset on swipe-back re-entry
- **Files:** `GoalSelectionPage.swift:230`, `FrequencySelectionPage.swift:232`, `LocationSelectionPage.swift:242`
- `isProceeding` is reset in `onAppear`, but `onAppear` is **not guaranteed to fire** when swiping back in a `TabView(.page)`. If a user advances via the "Next" button (setting `isProceeding = true`), then swipes back, the button remains disabled with a ProgressView spinner.
- **Fix:** Reset `isProceeding` in `onChange(of: currentPage)` instead of `onAppear`.

### H-2: SplashView recursive timer animation leak
- **File:** `SplashView.swift:218-236`
- `SplashMuscleMapHero.startWaveAnimation()` recursively schedules via `DispatchQueue.main.asyncAfter` with no cancellation mechanism. Multiple `onAppear` calls create concurrent chains that survive after the splash screen is dismissed.
- **Fix:** Use a `Task` with cancellation or add `onDisappear` invalidation.

### H-3: Equipment filter uses hardcoded localized strings
- **Files:** `LocationSelectionPage.swift:43-51`, `PRInputPage.swift:333-338`, `RoutineBuilderPage.swift:588-598`
- Equipment filter returns language-dependent strings (`"バーベル"` vs `"Barbell"`). If the exercise JSON equipment field language doesn't match the current locale, filtering returns zero results.
- **Fix:** Use equipment enum or locale-independent keys for filtering.

### H-4: Equipment filter mismatch between `equipmentFilter` and `filteredExercisesForMarquee`
- **File:** `LocationSelectionPage.swift:43-51` vs `74-89`
- Marquee preview shows exercises (e.g., Kettlebell for `.home`, Machine/Cable for `.both`) that don't appear in the actual generated routine. Misleading UX.
- **Fix:** Align marquee filter with routine generation filter.

### H-5: `resetIfNewWeek()` doesn't enforce Monday as week start
- **File:** `PurchaseManager.swift:125-140`
- Uses `Calendar.current` which inherits user's locale (Sunday start in US, Monday in Japan). CLAUDE.md specifies Monday reset.
- **Fix:** Set `calendar.firstWeekday = 2` explicitly.

### H-6: Mutation inside computed property getter (`weeklyWorkoutCount`)
- **File:** `PurchaseManager.swift:107-110`
- `resetIfNewWeek()` writes to UserDefaults inside a property getter. SwiftUI may call this getter multiple times per frame, causing redundant writes.
- **Fix:** Call `resetIfNewWeek()` from a dedicated method, not inside a getter.

### H-7: `PurchaseError` has hardcoded Japanese-only error descriptions
- **File:** `PurchaseManager.swift:147-157`
- Error messages like `"購入情報を取得できませんでした"` are not using L10n. Non-Japanese users see untranslated error text.
- **Fix:** Use L10n keys for all error descriptions.

### H-8: `incrementWorkoutCount()` called unconditionally for Pro users
- **Files:** `WorkoutViewModel.swift:145`, `PurchaseManager.swift:118-122`
- Counter accumulates even for Pro users. If subscription lapses mid-week, the user is immediately locked out because the counter already exceeds the limit.
- **Fix:** Guard with `guard !isPremium else { return }` in `incrementWorkoutCount()`.

### H-9: Double `@State private var appState = AppState.shared` in ContentView
- **File:** `ContentView.swift:12,31`
- Both `ContentView` and `MainTabView` declare separate `@State` wrappers around the same singleton. Works today but fragile — replacing `.shared` with `AppState()` would silently break.
- **Fix:** Pass `appState` from `ContentView` to `MainTabView` via parameter or `@Environment`.

### H-10: Indicator dots skip page 5 causing visual "jump"
- **File:** `OnboardingV2View.swift:171-177`
- `indicatorPages` excludes page 5 (MenuGeneratingPage). Users see dots jump from 4 to 6, which is disorienting.
- **Fix:** Hide the indicator entirely during the generating page, or animate the transition.

### H-11: Timer capture of non-Sendable type across actor boundary
- **File:** `FrequencySelectionPage.swift:338-343`
- `SplitPart` is not `Sendable`, captured in a non-`@Sendable` Timer closure. Will be a compile error under strict concurrency (Swift 6).
- **Fix:** Mark `SplitPart` as `Sendable` or use `@MainActor`-isolated timer pattern.

### H-12: RoutineCompletionPage timer fires after view disappears
- **File:** `RoutineCompletionPage.swift:441-445`
- If the view is removed without `onDisappear` firing (possible in `ZStack` + `.transition` edge cases), the timer continues running.
- **Fix:** Track timer reference and invalidate in `onDisappear`.

### H-13: `selectedDayIndex` can go out of bounds on "Next Day" tap
- **File:** `RoutineBuilderPage.swift:152-157`
- No bounds check inside the button action. If `days` mutates during a brief timing window, tapping could advance past the array.
- **Fix:** Add `guard selectedDayIndex < days.count - 1` before incrementing.

### H-14: `flatIndexFor` has out-of-bounds risk
- **File:** `RoutineCompletionPage.swift:427-433`
- `routine.days[d].exercises.count` would crash if `dayIndex` exceeds `routine.days.count`. Currently safe due to `enumerated()` but no defensive guard.
- **Fix:** Add bounds check on `dayIndex`.

### H-15: Weight stepper has no upper bound guard
- **File:** `TrainingHistoryPage.swift:139`
- `onAppear` clamps minimum to 30 but no maximum. Corrupted data (>200kg) passes through unchecked.
- **Fix:** Clamp to `30...250` range.

### H-16: `onLongPressGesture` conflicts with Button tap gesture
- **File:** `TrainingHistoryPage.swift:228-246`
- `.onLongPressGesture` on a `Button` creates gesture recognition delay. Users perceive the weight stepper as unresponsive.
- **Fix:** Use a custom gesture recognizer or `DragGesture(minimumDistance: 0)`.

### H-17: "kg" hardcoded in WeightInputSheet
- **File:** `PRInputPage.swift:522`
- PR weight always displays "kg" regardless of `AppState.shared.weightUnit`. Confusing for "lb" users.
- **Fix:** Use `AppState.shared.weightUnit` for display.

### H-18: FavoriteExercisesPage shows raw Japanese equipment string
- **File:** `FavoriteExercisesPage.swift:220`
- Uses `exercise.equipment` instead of `exercise.localizedEquipment`. Non-Japanese users see Japanese text.
- **Fix:** Use `exercise.localizedEquipment`.

### H-19: Page order mismatch — routine saved at page 6, read at page 8
- **Files:** `RoutineBuilderPage.swift:119-120`, `OnboardingV2View.swift:130-141`
- Routine saved in RoutineBuilderPage (page 6), then NotificationPermissionView (page 7) interrupts before RoutineCompletionPage (page 8) reads it. Works but contradicts CLAUDE.md ordering.
- **Fix:** Update CLAUDE.md or reorder pages.

### H-20: MenuGeneratingPage non-cancellable DispatchQueue timers
- **File:** `MenuGeneratingPage.swift:157-179`
- `DispatchQueue.main.asyncAfter` chains are non-cancellable. If the user navigates away and back, timers from the previous appearance fire alongside new ones, causing double-advancement.
- **Fix:** Use `Task` with cancellation or track a generation ID.

---

## MEDIUM (33)

### M-1: `showPRInput` dynamic re-evaluation
- **File:** `OnboardingV2View.swift:11-13`
- Computed property re-evaluates dynamically. Profile changes mid-flow could cause inconsistent skip logic.

### M-2: MenuGeneratingPage auto-advances on foreground return
- **File:** `MenuGeneratingPage.swift:177-179`
- `DispatchQueue.main.asyncAfter` timers pause when backgrounded, fire immediately on foreground return, causing jarring instant page transition.

### M-3: CLAUDE.md says "selectionOrder" but code uses slider-based `goalValues`
- **File:** `GoalSelectionPage.swift`
- Documentation drift. When multiple goals have the same slider value, `max(by:)` returns an arbitrary winner.

### M-4: Duplicate muscle intensity calculation (3x)
- **File:** `GoalSelectionPage.swift:73-97, 100-114, 255-264`
- Same aggregation logic copy-pasted three times, all evaluated during SwiftUI re-renders.

### M-5: Timer stored as `@State` requires manual invalidation
- **File:** `FrequencySelectionPage.swift:82`
- Timer could leak if view is removed without `onDisappear` firing.

### M-6: Recovery animation doesn't wrap around week boundary
- **File:** `FrequencySelectionPage.swift:393-406`
- Muscles trained on Friday appear instantly recovered on Monday (abrupt visual discontinuity).

### M-7: Empty marquee exercises creates unnecessary HStack children
- **File:** `LocationSelectionPage.swift:268-269`

### M-8: Sheet navigation title hardcodes Japanese for non-EN/JP users
- **File:** `GoalSelectionPage.swift:432-434`

### M-9: `dayLabels` array access without bounds check
- **File:** `FrequencySelectionPage.swift:271`

### M-10: `splitPartEnglishName` mapping incomplete
- **File:** `GoalMusclePreviewPage.swift:374-388`
- Partial localization. Unmatched Japanese names fall through to `?? jaName`.

### M-11: Double computation of `experienceMapStates` on every render
- **File:** `TrainingHistoryPage.swift:41-61`

### M-12: `coveragePercent` may never reach 100%
- **File:** `GoalMusclePreviewPage.swift:55-60`
- If any muscle is not in any `MuscleGroup.muscles`, coverage is capped below 100%.

### M-13: `onAppear` re-reads AppState — unclamped values on first render
- **File:** `TrainingHistoryPage.swift:11-16` vs `130-147`

### M-14: PRInputPage doesn't reload existing PRs on appear
- **File:** `PRInputPage.swift`
- `recordedPRs` starts empty and is only saved on "Next" tap. View recreation loses PRs from the UI.

### M-15: `bodyFatEnabled` onChange race in onAppear
- **File:** `TrainingHistoryPage.swift`
- Setting `bodyFatEnabled` in `onAppear` triggers `onChange` which writes `bodyFatPct` before it's updated.

### M-16: Animation timer not properly invalidated on view identity change
- **File:** `GoalMusclePreviewPage.swift`

### M-17: "BMI" string is hardcoded
- **File:** `TrainingHistoryPage.swift:514`

### M-18: Coverage percent from `splitParts` not from actual selected exercises
- **File:** `RoutineBuilderPage.swift:29-35`
- User-deleted exercises don't update the coverage badge.

### M-19: `confirmedUpToDay` not validated against `days.count` changes
- **File:** `RoutineBuilderPage.swift`

### M-20: `autoPickExercises` can return empty array
- **File:** `RoutineBuilderPage.swift:509-569`
- A `RoutineDay` could have zero exercises, saving an empty routine.

### M-21: Equipment filter strings hardcoded in Japanese and English
- **File:** `RoutineBuilderPage.swift:588-598, 761-769`

### M-22: `@Namespace` in struct body can cause issues on view identity changes
- **File:** `RoutineBuilderPage.swift:15`

### M-23: `muscleCoverage` uses string matches not exercise-derived muscles
- **File:** `RoutineCompletionPage.swift:45-49`

### M-24: `buttonGlow` animation never stops
- **File:** `RoutineCompletionPage.swift:205-207`

### M-25: PaywallView `isHardPaywall: true` naming misleading
- **File:** `RoutineCompletionPage.swift:217-219, 391-398`

### M-26: `currentStep` sequencing issue in MenuGeneratingPage
- **File:** `MenuGeneratingPage.swift:157-166`

### M-27: NotificationPermissionView animation phase 3 jarring visual
- **File:** `NotificationPermissionView.swift:26-31`

### M-28: `requestNotificationPermission` calls `onComplete()` regardless of result
- **File:** `NotificationPermissionView.swift:261-272`

### M-29: GeometryReader content not constrained to safe area
- **File:** `NotificationPermissionView.swift:43-46`

### M-30: GeometryReader proxy discarded in PaywallView
- **File:** `PaywallView.swift`

### M-31: Marquee animation no cleanup in PaywallView
- **File:** `PaywallView.swift`

### M-32: ForEach uses array index as id
- **File:** `PaywallView.swift`

### M-33: PurchaseDelegate not Sendable
- **File:** `PurchaseManager.swift`

---

## LOW (33)

### L-1: Force unwrap in DEBUG code
- **File:** `ContentView.swift`

### L-2: SplashMuscleMapHero zero-size GeometryReader
- **File:** `SplashView.swift`

### L-3: RoutineCompletionPage progress bar zero width
- **File:** `RoutineCompletionPage.swift`

### L-4: DST edge case in `challengeDay`
- **File:** `ContentView.swift`

### L-5: Dead `previousTab` variable
- **File:** `ContentView.swift`

### L-6: Animation value type performance
- **File:** `GoalSelectionPage.swift`

### L-7: Nonisolated id clarity
- **File:** `GoalSelectionPage.swift`

### L-8: Slider range semantics (0 vs 0.1)
- **File:** `GoalSelectionPage.swift`

### L-9: "5+" frequency semantics
- **File:** `FrequencySelectionPage.swift`

### L-10: No GeometryReader on GoalPage (no issue)
- **File:** `GoalSelectionPage.swift`

### L-11: Redundant `loadIfNeeded()`
- **File:** `LocationSelectionPage.swift`

### L-12: Synchronous save on main thread
- **File:** `LocationSelectionPage.swift`

### L-13: `loadIfNeeded()` in render pass
- **File:** `TrainingHistoryPage.swift`

### L-14: Weight display floating-point edge case
- **File:** `TrainingHistoryPage.swift`

### L-15: Hardcoded "cm"/"%"
- **File:** `TrainingHistoryPage.swift`

### L-16: Missing `isProceeding` guard in FavoriteExercisesPage
- **File:** `FavoriteExercisesPage.swift`

### L-17: ForEach hashable dependency
- **File:** `GoalMusclePreviewPage.swift`

### L-18: "Add" button defaults to `.chestUpper`
- **File:** `PRInputPage.swift`

### L-19: GeometryReader zero-size edge case
- **File:** `PRInputPage.swift`

### L-20: Experience detection heuristic overwrites beginner at 70kg
- **File:** `PRInputPage.swift`

### L-21: `ForEach(days.indices, id: \.self)` anti-pattern
- **File:** `RoutineBuilderPage.swift`

### L-22: Hardcoded emoji in routine names
- **File:** `RoutineBuilderPage.swift`

### L-23: `appeared` guard missing
- **File:** `RoutineCompletionPage.swift`

### L-24: Progress bar GeometryReader zero width
- **File:** `RoutineCompletionPage.swift`

### L-25: Dead `isJapanese` property
- **File:** `NotificationPermissionView.swift`

### L-26: Hardcoded "MuscleMap" string
- **File:** `NotificationPermissionView.swift`

### L-27: RevenueCat API key hardcoded
- **File:** `PurchaseManager.swift`

### L-28: Headline height may clip translations
- **File:** `PaywallView.swift`

### L-29: "Start Free Now" not disabled during purchase
- **File:** `PaywallView.swift`

### L-30: `goalSubtitle` silent nil on enum mismatch
- **File:** `PaywallView.swift`

### L-31: Single-exercise marquee shows identical rows
- **File:** `PaywallView.swift`

### L-32: Purchase() return routes through DEBUG override
- **File:** `PurchaseManager.swift`

### L-33: Task blocks rely on implicit MainActor inheritance
- **File:** `PurchaseManager.swift`

---

## Top 5 Actionable Fixes (Recommended Priority)

1. **C-5 + C-6:** Fix CLAUDE.md workout limit documentation (says 1, code is 2). Fix PaywallView "Routines" row — either implement a routine limit or change the label to "Workouts 2/wk".
2. **C-3 + C-4 + C-7 + C-8:** Refactor all `Timer.scheduledTimer` closures in onboarding views to use `Task`/`AsyncStream` or `@Observable` class pattern to eliminate struct self-capture and leak risks.
3. **H-1:** Fix `isProceeding` getting stuck on swipe-back by resetting it in `onChange(of: currentPage)` instead of relying on `onAppear`.
4. **H-3 + H-4 + H-17 + H-18:** Standardize equipment filtering to use locale-independent keys. Fix hardcoded "kg" and raw Japanese equipment strings.
5. **H-5 + H-6 + H-8:** Fix `PurchaseManager` — enforce Monday week start, remove mutation from getter, guard `incrementWorkoutCount()` for Pro users.
