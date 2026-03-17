# MuscleMap Code Quality Audit Report

> **Date:** 2026-03-17
> **Scope:** All 118 Swift files under `/MuscleMap/MuscleMap/`
> **Method:** Static analysis (automated, no code changes)

---

## Summary

| Category | Critical | High | Medium | Low | Total |
|:---------|:--------:|:----:|:------:|:---:|:-----:|
| A. Crash Risk | 0 | 1 | 4 | 20 | 25 |
| B. Performance | 6 | 4 | 14 | 9 | 33 |
| C. CLAUDE.md Violations | - | - | - | - | (systemic) |
| D. Dead Code | - | - | - | - | 12 items |
| E. Localization | - | - | - | - | 130+ strings |
| F. Security | 1 | 0 | 1 | 1 | 3 |

---

## 1. Fatal (Release Blocker)

### [F-1] CRITICAL: RevenueCat API Key Hardcoded in Source Code

- **File:** `Utilities/PurchaseManager.swift:30`
- **Code:** `Purchases.configure(withAPIKey: "appl_IzrrBdSVXMDZUylPnwcaJxvdlxb")`
- **Risk:** API key is committed to source control and also duplicated in `CLAUDE.md`. While RevenueCat public keys are client-side by design, best practice is to store in `.xcconfig` excluded from version control.
- **Fix:** Move to `Info.plist` or `.xcconfig` file excluded from git. Rotate key on RevenueCat dashboard.

### [F-2] CRITICAL: Unbounded FetchDescriptor -- ALL WorkoutSets loaded

- **File:** `Views/Workout/WorkoutCompletionView.swift:385`
- **Code:** `let allSetsDescriptor = FetchDescriptor<WorkoutSet>()`
- **Impact:** Fetches **every WorkoutSet in the entire database** with no predicate, no sortBy, no fetchLimit. Used to calculate overall strength level. Performance degrades linearly with workout history.

### [F-3] CRITICAL: Unbounded FetchDescriptor -- ALL WorkoutSets loaded (duplicate)

- **File:** `Views/Workout/WorkoutCompletionView.swift:517`
- **Code:** `let allSetsDescriptor = FetchDescriptor<WorkoutSet>()`
- **Impact:** Same unbounded fetch, called again in the same view for Strength Map share image generation.

### [F-4] CRITICAL: Unbounded FetchDescriptor -- ALL WorkoutSessions loaded

- **File:** `Views/Home/AnalyticsMenuView.swift:201`
- **Code:** `let sessionDescriptor = FetchDescriptor<WorkoutSession>()`
- **Impact:** Fetches ALL WorkoutSessions with no predicate, no limit. Only used to get `.count`.

### [F-5] CRITICAL: Unbounded FetchDescriptor -- ALL WorkoutSets for volume sum

- **File:** `Views/Home/AnalyticsMenuView.swift:205`
- **Code:** `let setsDescriptor = FetchDescriptor<WorkoutSet>()`
- **Impact:** Fetches ALL WorkoutSets then iterates every record with `.reduce` to sum total volume.

### [F-6] CRITICAL: FetchDescriptor in View Computed Property

- **File:** `Views/History/DayWorkoutDetailView.swift:24-36`
- **Code:**
  ```swift
  private var sessions: [WorkoutSession] {
      let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startDate)])
      let allSessions = (try? modelContext.fetch(descriptor)) ?? []
      return allSessions.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay }
  }
  ```
- **Impact:** Fetches ALL WorkoutSessions from the database and filters in-memory. Re-executes on every view re-render. Should use predicate and move to `onAppear`/`@State`.

---

## 2. High Priority

### [H-1] HIGH: Infinite Loop Risk in MuscleHeatmapViewModel

- **File:** `ViewModels/MuscleHeatmapViewModel.swift:161-191`
- **Code:**
  ```swift
  while currentDate <= endOfWeek {
      ...
      currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
  }
  ```
- **Risk:** If `calendar.date(byAdding:)` ever returns nil, the `?? currentDate` fallback causes `currentDate` to never advance, resulting in an infinite loop that freezes the UI.
- **Fix:** Replace `?? currentDate` with `guard let ... else { break }`.

### [H-2] HIGH: No GIF Caching in ExerciseGifView

- **File:** `Views/Components/ExerciseGifView.swift:97-108`
- **Problems:**
  1. **No caching.** Every appearance reads the GIF file from disk with `Data(contentsOf:)`.
  2. **No memory management.** `UIImage.gif(data:)` decodes ALL frames into memory (10-30MB per GIF).
  3. **`hasGif()` loads the entire file** (line 91-92) just to check existence. Should use `Bundle.main.url()` nil check.
  4. **`updateUIView` re-decodes** all GIF frames on every SwiftUI state change (line 129-133).
- **Impact:** 92 exercise GIFs in the app. Multiple GIFs visible in lists (WorkoutIdleComponents, MenuPreviewSheet) could cause memory pressure.

### [H-3] HIGH: MuscleBalanceDiagnosisViewModel fetches ALL sessions

- **File:** `ViewModels/MuscleBalanceDiagnosisViewModel.swift:182-213`
- **Impact:** Fetches ALL completed WorkoutSessions (no fetchLimit), then iterates over EVERY set in EVERY session with ExerciseStore lookups. For 100 sessions x 20 sets = 2000 iterations.

### [H-4] HIGH: StrengthScoreCalculator receives unbounded data

- **File:** `Utilities/StrengthScoreCalculator.swift:222-232`
- **Impact:** `muscleStrengthScores(allSets:)` receives ALL WorkoutSets from callers (WorkoutCompletionView lines 385, 517) and iterates every one.

---

## 3. Medium Priority

### [M-1] Array Out-of-Bounds Risk -- RoutineBuilderPage

- **File:** `Views/Onboarding/RoutineBuilderPage.swift:116, 148, 155, 181`
- **Code:** Multiple unguarded `days[selectedDayIndex]` accesses.
- **Risk:** `days` starts empty (line 10). Some access points guard with `days.indices.contains(selectedDayIndex)` (lines 86, 206, 293) but lines 116, 148, 155, 181 do NOT. If SwiftUI renders body before `onAppear` fires, these crash.
- **Fix:** Add `guard days.indices.contains(selectedDayIndex)` before each unguarded access.

### [M-2] Timer Leak -- WorkoutViewModel

- **File:** `ViewModels/WorkoutViewModel.swift:37, 223`
- **Issue:** `restTimer` uses `[weak self]` correctly, but no `deinit` calls `restTimer?.invalidate()`. Timer is invalidated in `stopRestTimer()` (line 261) but no safety net on deallocation.
- **Fix:** Add `deinit { restTimer?.invalidate() }`.

### [M-3] ModelContext Nil Race -- PhoneSessionManager

- **File:** `Connectivity/PhoneSessionManager.swift:12`
- **Code:** `var modelContext: ModelContext?`
- **Issue:** Set in `RootView.onAppear` (MuscleMapApp.swift:61). If WatchConnectivity callback arrives before `onAppear`, `modelContext` is nil and Watch data is silently dropped (lines 231-235 guard and return). No crash, but potential data loss.

### [M-4] CSV Date Parsing Without Timezone

- **File:** `Utilities/CSVParser.swift:155-159`
- **Issue:** DateFormatter uses `en_US_POSIX` locale (correct) but no explicit `timeZone`. If CSV was exported from a different timezone, dates could shift by a day.

### [M-5] Missing fetchLimit in MuscleStateRepository

- **File:** `Repositories/MuscleStateRepository.swift:16-17`
- **Issue:** Has `sortBy` but no `fetchLimit`. Fetches ALL MuscleStimulation records then deduplicates in-memory. Only 21 latest records needed.

### [M-6] Missing fetchLimit in PRManager (3 methods)

- **Files:** `Utilities/PRManager.swift:14-17, 35-38, 81-83`
- **Issue:** `getWeightPR` (sorted, no limit, uses `.first`), `getPreviousWeightPR` (fetches all, filters), `getBestEstimated1RM` (fetches all, maps to `.max()`). All should add `fetchLimit`.

### [M-7] N+1 Query Pattern in checkPRUpdates

- **File:** `Views/Workout/WorkoutCompletionView.swift:420-425`
- **Issue:** Inside a loop over every exercise in the session, fetches all WorkoutSets per exercise with no fetchLimit. If 5 exercises, that's 5 separate unbounded fetches.

### [M-8] O(n^2) in DayWorkoutDetailView.SessionDetailCard

- **File:** `Views/History/DayWorkoutDetailView.swift:118`
- **Code:** `session.sets.filter { $0.exerciseId == set.exerciseId }` inside a loop over sets.
- **Impact:** Quadratic behavior for sessions with many sets.

### [M-9] @Observable Multi-Property Update Cascade -- HomeViewModel

- **File:** `ViewModels/HomeViewModel.swift`
- **Issue:** `loadMuscleStates()` updates 4 properties sequentially (`muscleStates`, `neglectedMuscles`, `neglectedMuscleInfos`, `latestStimulations`), potentially triggering 4 separate view invalidations for the large HomeView hierarchy.

### [M-10] @Observable Multi-Property Update Cascade -- HistoryViewModel

- **File:** `ViewModels/HistoryViewModel.swift`
- **Issue:** `load()` calls 9 `calculate*` functions sequentially, each updating a property. 10 published stored properties total. Session.sets arrays traversed 7+ times across all methods.

### [M-11] Full User Profile Logged in DEBUG HomeView.onAppear

- **File:** `Views/Home/HomeView.swift:203-209`
- **Data Logged:** `primaryOnboardingGoal`, `weeklyFrequency`, `trainingLocation`, `goalPriorityMuscles`, `trainingExperience`, `initialPRs`, `weightKg`
- **Risk:** While DEBUG-only, could leak into crash logs if DEBUG builds are distributed via TestFlight.

### [M-12] Multiple Expensive Computed Properties in WorkoutCompletionView

- **File:** `Views/Workout/WorkoutCompletionView.swift:35-93`
- **Issue:** 7 computed properties iterate `session.sets` on every render: `totalVolume`, `uniqueExercises`, `exercisesDone`, `stimulatedMuscleMapping`, `stimulatedMusclesWithSets`, `setsCount`, `exerciseNames`.

### [M-13] DateFormatter Created in View Computed Property

- **File:** `Views/History/DayWorkoutDetailView.swift:12-22`
- **Issue:** `DateFormatter()` is expensive to initialize and is created on every render in `localizedDateString`.

### [M-14] Regex in Nested Loop -- HistoryViewModel

- **File:** `ViewModels/HistoryViewModel.swift:272-279`
- **Issue:** For every unmatched muscleId, iterates over all 21 Muscle.allCases and runs a regex `.replacingOccurrences(of:with:options:.regularExpression)` on each `.rawValue`. Inside a loop over sets inside a loop over sessions. Creates regex engine per call.

---

## 4. Low Priority

### [L-1] Force Unwrap -- `colors.randomElement()!`

- **File:** `Views/Workout/FullBodyConquestView.swift:271`
- **Note:** Safe (hardcoded 9-element array) but unnecessary.

### [L-2] Force Unwrap -- `lastWorkoutDate!`

- **File:** `ViewModels/HistoryViewModel.swift:384`
- **Note:** Guarded by short-circuit `||` but poor Swift style. Fragile if logic changes.

### [L-3] Force Unwrap -- `dailyMaxWeights[date]!`

- **File:** `ViewModels/HistoryViewModel.swift:415`
- **Note:** Safe (derived from same dictionary keys) but brittle if refactored.

### [L-4] Force Unwrap -- `exerciseDailyMax[exId]![dayStart]`

- **File:** `ViewModels/HistoryViewModel.swift:192`
- **Note:** Guarded by preceding nil check but fragile.

### [L-5] Force Unwrap -- `cal.date(byAdding:)!`

- **File:** `App/MuscleMapApp.swift:131`
- **Note:** DEBUG-only code (`seedDemoDataIfNeeded`). Never runs in production.

### [L-6] App Startup Blocking Main Thread

- **File:** `App/MuscleMapApp.swift:7-18`
- **Issue:** `ExerciseStore.load()`, `PhoneSessionManager.shared`, `PurchaseManager.configure()`, `configureAppearance()` all run synchronously in `init()`. Currently lightweight (92 exercises), but could become a problem if data grows.

### [L-7] ScrollView with VStack Instead of LazyVStack -- HomeView

- **File:** `Views/Home/HomeView.swift:33-34`
- **Issue:** HomeView's `ScrollView { VStack }` eagerly instantiates all children including muscle map, streak badge, recommended menu, neglected alert, coach mark, strength map.

### [L-8] Calendar.current Used Without Explicit Timezone

- **Files:** 30+ occurrences across the codebase (RecoveryCalculator, HistoryViewModel, StreakViewModel, WeeklySummaryViewModel, MuscleHeatmapViewModel, etc.)
- **Note:** For a personal fitness app with local-only data, this is generally correct behavior. Minor edge cases with timezone changes (streaks, daily grouping).

### [L-9] UserProfile in Plaintext UserDefaults

- **File:** `Models/UserProfile.swift:91, 107`
- **Note:** Stores nickname, weightKg, heightCm, initialPRs. Acceptable for a fitness app but accessible on jailbroken devices. Empty `KeychainHelper.swift` suggests this was considered.

---

## C. CLAUDE.md Violations

### C-1. Views Exceeding 200 Lines (MUST NOT)

**48 files** exceed the 200-line limit. Top offenders:

| File | Lines |
|:-----|------:|
| `Views/Home/MusclePathData.swift` | ~1175 |
| `Views/Home/HomeHelpers.swift` | ~685 |
| `Views/Onboarding/RoutineBuilderPage.swift` | ~648 |
| `Views/Settings/SettingsView.swift` | ~566 |
| `Views/Workout/WorkoutCompletionView.swift` | ~559 |
| `Views/Workout/WorkoutCompletionSections.swift` | ~549 |
| `Views/History/HistoryMapComponents.swift` | ~546 |
| `Views/Home/MuscleBalanceDiagnosisView.swift` | ~526 |
| `Views/Home/MuscleJourneyView.swift` | ~524 |
| `Views/MuscleDetail/MuscleDetailView.swift` | ~509 |

Note: `MusclePathData.swift` (1175 lines) is pure SVG Path data and may be exempt.

### C-2. Non-8pt Spacing (SHOULD)

**Hundreds of violations** across virtually all View files. The 8pt grid convention has effectively not been followed during development.

| Value | Approx Count | Notes |
|:------|:------------:|:------|
| `spacing: 12` | ~100+ | Most pervasive violation |
| `spacing: 4` | ~80+ | Tight layouts |
| `.padding(12)` | ~40+ | Card internal padding |
| `spacing: 2` | ~30+ | Very tight spacing |
| `spacing: 6` | ~25+ | Between labels |
| `spacing: 10` | ~20+ | Section gaps |
| `spacing: 20` | ~15+ | Between sections |
| `spacing: 3` | ~10+ | Minimal spacing |

### C-3. Missing Previews (SHOULD)

**12 files** (~30+ View structs) have no `#Preview` block:

| File | Missing Views |
|:-----|:-------------|
| `HomeNeglectedComponents.swift` | NeglectedWarningView, NeglectedShareCard, NeglectedMuscleMapView |
| `ChallengeProgressBanner.swift` | ChallengeProgressBanner, ChallengeDayCompleteBanner |
| `HomeStreakComponents.swift` | MilestoneView, MilestoneShareCard |
| `HomeHelpers.swift` | HomeCoachMarkView + 6 more helper Views |
| `CSVImportView.swift` | CSVImportView |
| `MicroBodyMapView.swift` | MicroBodyMapView |
| `HistoryStatsComponents.swift` | MonthlySummaryCard, PeriodSummaryCard |
| `HistorySessionComponents.swift` | SessionHistorySection, SessionRowView |
| `HistoryMapComponents.swift` | HistoryMapView + 3 more |
| `HistoryCalendarComponents.swift` | HistoryCalendarView + 3 more |
| `WorkoutIdleComponents.swift` | WorkoutIdleView + 3 more |
| `RecordedSetsComponents.swift` | RecordedSetsView (preview commented out) |

### C-4. Compliant Areas

| Rule | Status |
|:-----|:-------|
| Direct @Query from Views | **0 violations** -- Repository pattern used consistently |
| @Model schema changes | **0 violations** -- Models match spec exactly |
| Hardcoded muscleMapping | **0 production violations** (6 in DEBUG seed data only) |
| Missing haptic feedback | **0 violations** -- All 5 required haptic types implemented |
| Force Try (`try!`) | **0 occurrences** -- All uses are `try?` or `do/catch` |

### C-5. CLAUDE.md Itself Is Stale

- References 6 deleted onboarding files as "existing" in the file structure (GymCheckPage, OnboardingBranchPage, RecentTrainingInputPage, GuidedFirstWorkoutPage, ValuePropositionPage, PersonalizationPage)
- Claims 19 onboarding files exist (several have been deleted)

---

## D. Dead Code

### D-1. Dead/Empty Files (5)

| File | Issue |
|:-----|:------|
| `Data/ExerciseDescriptions.swift` | Empty stub. `import Foundation` + empty enum. Comment: "unused". |
| `Utilities/KeychainHelper.swift` | Empty stub. `import Foundation` + empty enum. |
| `Utilities/KeyManager.swift` | Empty stub. `import Foundation` + empty enum. |
| `Views/Components/MicroBodyMapView.swift` | Dead stub. Renders only `EmptyView()`. Never instantiated. |
| `Views/Onboarding/FavoriteExercisesPage.swift` | **282 lines of dead code.** Never used in OnboardingV2View or anywhere else. |

### D-2. Unused Methods (4)

| File:Line | Method | Issue |
|:----------|:-------|:------|
| `Utilities/HapticManager.swift:34` | `static func mediumTap()` | Zero call sites in entire codebase |
| `Data/RoutineManager.swift:33` | `func todayRoutineDay(modelContext:)` | HomeViewModel has its own duplicate implementation |
| `Data/RoutineManager.swift:69` | `func reload()` | Zero external call sites |
| `ViewModels/StreakViewModel.swift:164` | `func currentMilestoneLevel()` | Defined but never invoked |

### D-3. Unused Properties (3)

| File:Line | Property | Issue |
|:----------|:---------|:------|
| `Views/Onboarding/GoalSelectionPage.swift:63` | `@State private var showMusclePreview` | Written to (`= true`) but never read. View uses `selectedGoal != nil` instead |
| `Data/RoutineManager.swift:28` | `var hasRoutine: Bool` | Only used by dead method `todayRoutineDay()`. HomeViewModel has its own `hasRoutine` |
| `Utilities/AppConstants.swift:11` | `static let appName` | Never referenced anywhere |

### D-4. Unused Imports (3)

| File:Line | Import | Issue |
|:----------|:-------|:------|
| `ViewModels/HomeViewModel.swift:3` | `import WidgetKit` | Delegates to WidgetDataProvider which has its own import |
| `ViewModels/WorkoutViewModel.swift:1` | `import Foundation` | Redundant -- SwiftUI re-exports Foundation |
| `Utilities/LocalizationManager.swift:1` | `import Foundation` | Redundant -- SwiftUI re-exports Foundation |

---

## E. Localization

### E-1. Scale of the Problem

**~130+ hardcoded Japanese user-facing strings** across View, ViewModel, and Utility files that should be routed through `L10n`.

### E-2. Critical Patterns

**Equipment name matching (6 files):**
The strings `"自重"`, `"ダンベル"`, `"ケトルベル"`, `"バーベル"` appear as hardcoded string comparisons in:
- `Views/Onboarding/RoutineBuilderPage.swift` (lines 359, 516-517)
- `Repositories/ExerciseStore.swift` (line 89)
- `ViewModels/MuscleDetailViewModel.swift` (line 54)
- `ViewModels/WorkoutViewModel.swift` (line 94)
- `Views/Workout/SetInputComponents.swift` (line 18)

Since `exercises.json` stores equipment names in Japanese, this works, but it breaks the localization contract.

**Goal-based headlines duplicated (2 files):**
The same 7 goal-based Japanese headlines appear identically in both:
- `Views/Onboarding/CallToActionPage.swift` (lines 17-34)
- `Views/Onboarding/RoutineCompletionPage.swift` (lines 49-63)

Neither uses L10n.

**Duplicate muscle names:**
- `Views/Home/StrengthShareCard.swift` (lines 317-337) has 21 hardcoded `shareJapaneseName` values duplicating `Muscle.japaneseName`.

### E-3. Files with Most Hardcoded Strings

| File | Approx Count |
|:-----|:------------:|
| `Views/Home/AnalyticsMenuView.swift` | 20+ |
| `Views/Settings/SettingsView.swift` | 15+ |
| `Views/Onboarding/GoalSelectionPage.swift` | 14+ |
| `Views/Onboarding/CallToActionPage.swift` | 10+ |
| `Views/Home/HomeHelpers.swift` | 10+ |
| `Views/Workout/WorkoutCompletionView.swift` | 10+ |
| `Utilities/WorkoutRecommendationEngine.swift` | 10+ |
| `Views/Workout/WorkoutCompletionSections.swift` | 8+ |
| `Views/Onboarding/GoalMusclePreviewPage.swift` | 5 |
| `Views/Onboarding/WeightInputPage.swift` | 3 |
| `Utilities/PurchaseManager.swift` | 2 |

---

## F. Security

### F-1. Summary

| Category | Findings |
|:---------|:---------|
| Hardcoded API Keys | **1 CRITICAL** -- RevenueCat key in `PurchaseManager.swift:30` (see [F-1]) |
| UserDefaults Sensitive Data | **1 LOW** -- UserProfile in plaintext (see [L-9]) |
| print() in Release | **PASS** -- All wrapped in `#if DEBUG` or `#Preview` blocks |
| debugPrint() | **PASS** -- None found |
| NSLog | **PASS** -- None found |
| Sensitive Data Logging | **1 MEDIUM** -- Full profile logged in DEBUG (see [M-11]) |
| HTTP Endpoints | **PASS** -- All URLs use HTTPS |
| File System | **PASS** -- Only reads from Bundle.main (sandboxed) |
| @AppStorage | **PASS** -- Only `youtubeSearchLanguage` in SettingsView (non-sensitive) |

---

## Recommended Fix Priority

### P0: Immediate (before release)

1. **[F-1]** Move RevenueCat API key out of source code into `.xcconfig`
2. **[F-2] ~ [F-6]** Add `fetchLimit` and predicates to 5 unbounded FetchDescriptors. Move DayWorkoutDetailView's fetch out of computed property.
3. **[H-1]** Fix infinite loop risk in MuscleHeatmapViewModel (`?? currentDate` -> `guard else break`)

### P1: Next Sprint

4. **[H-2]** Add `NSCache`-based GIF caching to ExerciseGifView. Fix `hasGif()` to use URL existence check.
5. **[M-1]** Guard `days[selectedDayIndex]` accesses in RoutineBuilderPage (4 unguarded sites)
6. **[M-2]** Add `deinit { restTimer?.invalidate() }` to WorkoutViewModel
7. **[M-6]** Add `fetchLimit = 1` to PRManager's 3 methods
8. **[H-3] ~ [H-4]** Add fetchLimit to MuscleBalanceDiagnosisViewModel and scope StrengthScoreCalculator input
9. **[M-9] ~ [M-10]** Batch @Observable property updates to reduce re-render cascades

### P2: Backlog

10. **[D]** Delete 5 dead/empty files, 4 unused methods, 3 unused properties
11. **[E]** Route 130+ hardcoded Japanese strings through L10n
12. **[C-1]** Split 48 files exceeding 200-line limit (start with top 10)
13. **[C-3]** Add `#Preview` to 12 files missing previews
14. **[C-5]** Update CLAUDE.md to reflect current file structure (remove references to deleted files)
15. **[M-8]** Fix O(n^2) pattern in DayWorkoutDetailView.SessionDetailCard
16. **[M-14]** Cache regex results or use a dictionary lookup in HistoryViewModel
