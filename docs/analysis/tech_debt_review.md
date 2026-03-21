# MuscleMap Technical Debt Review

> **Date:** 2026-03-21
> **Scope:** MuscleMap iOS app (`MuscleMap/` directory)
> **Status:** 118 Swift files, 34,418 lines

---

## 1. Codebase Structure Summary

| Metric | Value |
|:---|:---|
| Swift files | 118 |
| Total lines | 34,418 |
| Files > 500 lines | 17 |
| Files > 200 lines (CLAUDE.md View limit) | 30+ |
| TODOs | 1 |
| FIXMEs / HACKs | 0 |
| Force unwraps (`as!` / `try!`) | 0 |
| Singletons (`.shared`) | 12 |
| Unguarded `print()` statements | 80+ |

### Largest Files

| Lines | File | Type |
|:---|:---|:---|
| 1,290 | LocalizationManager.swift | Utility |
| 1,175 | MusclePathData.swift | Data (SVG paths) |
| 1,138 | HomeHelpers.swift | View |
| 1,077 | RoutineBuilderPage.swift | View |
| 766 | PRInputPage.swift | View |
| 651 | WorkoutRecommendationEngine.swift | Utility |
| 641 | SettingsView.swift | View |
| 623 | HistoryViewModel.swift | ViewModel |
| 617 | DayWorkoutDetailView.swift | View |
| 615 | TrainingHistoryPage.swift | View |

CLAUDE.md mandates a 200-line View limit. **17 View files exceed 400 lines.**

---

## 2. Performance Issues

### P0 Critical

#### 2.1 TimelineView(.animation) per-frame re-renders
- **File:** `LocationSelectionPage.swift:284-316`
- **Issue:** `TimelineView(.animation)` triggers SwiftUI body re-evaluation on **every display frame** (~60-120 FPS). The entire VStack of 2 rows x 20 ExerciseGifCard views re-renders per frame, but only the `.offset(x:)` value changes.
- **Impact:** Battery drain, potential frame drops on older devices.
- **Fix:** Use `CADisplayLink` wrapper that only updates the offset, or move GIF card construction outside the TimelineView.

#### 2.2 GIF memory: unbounded loading without cache
- **File:** `ExerciseGifView.swift:89-173`
- **Issue:** `Data(contentsOf: url)` loads entire GIF into memory per card. `UIImage.animatedImage(with:duration:)` decodes ALL frames upfront. The marquee creates 2 copies of each row (seamless loop), loading the same GIF twice. With 20 GIFs at 500KB-2MB each = 10-40MB.
- **Impact:** Memory pressure on lower-end devices (iPhone SE, iPad mini).
- **Fix:** Implement `NSCache<NSString, Data>` for GIF data. Use static first-frame for `.card` size instead of animated. Limit marquee visible cards.

#### 2.3 Repeated computed property evaluation in View body
- **File:** `LocationSelectionPage.swift:83-130`
- **Issue:** `filteredExercises` re-filters 92 exercises on every body evaluation. `topRowExercises` and `bottomRowExercises` each call `filteredExercises` again. `totalFilteredCount` duplicates the same filter logic separately.
- **Fix:** Cache in `@State`, recalculate only when `selected` changes.

Similar patterns in:
- `GoalSelectionPage.swift:77-115` — `muscleStates` + `priorityMuscles` both loop all goals
- `WorkoutCompletionView.swift:35-98` — `stimulatedMuscleMapping` iterates all sets per render

#### 2.4 SwiftData queries without fetchLimit
- **File:** `WorkoutCompletionView.swift:423-429` — PR check loop fetches all sets per exercise, no limit
- **File:** `MuscleHeatmapViewModel.swift:103` — Fetches all sessions (should limit to 90 days)
- **File:** `HomeView.swift:259-261` — `fetchCount` on entire WorkoutSet table just to check if any exist
- **Fix:** Add `fetchLimit` and date-range predicates.

### P1 High

#### 2.5 HistoryViewModel triple-nested reduce
- **File:** `HistoryViewModel.swift:82-106`
- **Issue:** `weekSessions.reduce { session.sets.reduce { ... } }` is O(sessions x sets). Runs synchronously on MainActor.
- **Fix:** Flatten to single loop; memoize with date check.

#### 2.6 God files: body size exceeds 200 lines
- `RoutineBuilderPage.swift` (~1077 lines, body estimated >300 lines)
- `WorkoutCompletionView.swift` (574 lines, 14+ @State properties)
- `HomeHelpers.swift` (1138 lines, multiple unrelated views in one file)
- **Fix:** Extract sub-views and move logic to ViewModels.

---

## 3. Crash Risks

### P0 Critical

**None found.** The codebase has zero `as!` / `try!` and uses optional binding consistently.

### P1 High

#### 3.1 Division by zero in lerp functions
- **File:** `StrengthScoreCalculator.swift:108-177`
- **Issue:** `(value - from) / (to - from)` crashes if `to == from`. Called during Strength Map rendering.
- **Fix:** `guard to != from else { return scoreFrom }`

#### 3.2 Stale index after array mutation
- **File:** `RoutineBuilderPage.swift:151-155`
- **Issue:** `editingExerciseIndex` is validated with `.indices.contains()` but the array can mutate between check and access if user deletes an exercise.
- **Fix:** Use safe subscript extension `array[safe: index]`.

### P2 Medium

#### 3.3 DispatchQueue.main.asyncAfter not cancelled on dismiss
- **Files:** `SplashView.swift:125,133,140`, multiple onboarding pages
- **Issue:** Queued blocks fire even if View is dismissed. Could update stale state.
- **Fix:** Use `Task { try await Task.sleep(nanoseconds:) }` which auto-cancels.

---

## 4. Thread Safety

### P1 High

#### 4.1 WorkoutRepository not @MainActor
- **File:** `WorkoutRepository.swift`
- **Issue:** `modelContext.insert()` / `.save()` / `.delete()` are called without `@MainActor` isolation. `ModelContext` is not thread-safe.
- **Fix:** Add `@MainActor` to class declaration.

#### 4.2 GIF decoding on MainThread
- **File:** `ExerciseGifView.swift:120`
- **Issue:** `UIImage.gif(data:)` decodes all frames synchronously. For large GIFs, blocks UI.
- **Fix:** Decode on background thread, show placeholder until ready.

### P2 Medium

#### 4.3 Timer retain cycle risks (3 locations)
- `PRInputPage.swift:600` — No capture list
- `NotificationPermissionView.swift:166` — No capture list
- `RoutineCompletionPage.swift:436` — `[self]` strong capture

These are SwiftUI structs, so risk is lower (struct value semantics), but worth auditing.

---

## 5. Architecture & Code Quality

### P0 Critical

#### 5.1 AppState is a god object
- **File:** `AppState.swift` (175 lines, 27 properties)
- **Issue:** Mixes navigation state, settings, onboarding flags, challenge data, and user profile. Accessed directly from 37+ View files.
- **Fix:** Split into `NavigationState`, `OnboardingState`, `ChallengeState`, `SettingsState`.

#### 5.2 Child Views mutate global state directly
- **Examples:**
  - `ExerciseDetailView.swift:117` — `AppState.shared.pendingExerciseId = exercise.id`
  - `ExerciseDetailView.swift:118` — `AppState.shared.selectedTab = 1`
  - `AnalyticsMenuView.swift:96` — `AppState.shared.selectedTab = 0`
  - `TrainingHistoryPage.swift:316` — `AppState.shared.weightUnit` mutation
- **Issue:** No unidirectional data flow. Views bypass ViewModels to mutate global state.
- **Fix:** Use callbacks/closures from child to parent. Only top-level ContentView should write to AppState.

### P1 High

#### 5.3 12 singletons create tight coupling
| Singleton | Usage Count (est.) |
|:---|:---|
| AppState.shared | 37+ files |
| ExerciseStore.shared | 20+ files |
| PurchaseManager.shared | 15+ files |
| LocalizationManager.shared | 30+ files |
| FavoritesManager.shared | 5 files |
| RoutineManager.shared | 5 files |
| PRManager.shared | 5 files |
| Others (5) | 2-3 files each |

**Impact:** Unit testing requires mocking all singletons. No dependency injection.

#### 5.4 Silent error handling in production
- **20+ `try?` locations** suppress errors without logging
- **15+ `#if DEBUG print(...)` blocks** — release builds have zero error visibility
- **Critical example:** `ExerciseStore.swift:34` — exercises.json decode failure returns empty array silently. App becomes non-functional with no feedback.
- **Fix:** Use `os.Logger` for production logging; show user-facing error for critical failures.

#### 5.5 80+ unguarded print() statements
- None wrapped in `#if DEBUG`
- Will execute in release builds, writing to system log
- **Fix:** Replace with `os.Logger` or wrap in `#if DEBUG`.

### P2 Medium

#### 5.6 Duplicated logic (5 patterns)
1. **Weight conversion** `* 2.20462` — 3 locations (`AppState`, `TrainingHistoryPage`)
2. **Equipment filter** — 3 locations (`ExerciseStore`, `LocationSelectionPage`, `WorkoutRecommendationEngine`)
3. **Estimated 1RM (Epley)** — referenced in multiple PRManager methods
4. **Neglect threshold** (7/14 days) — `RecoveryCalculator` + Views
5. **UserDefaults persistence pattern** — repeated across `UserProfile`, `RoutineManager`, `AppState`

#### 5.7 Magic numbers without constants
- `2.20462` (kg-to-lb) in 3 files
- `90` (rest timer seconds) in AppState
- `90 * 24 * 60 * 60` (challenge duration) inline
- `7`, `14` (neglect thresholds) in RecoveryCalculator
- Font sizes, padding values scattered across View files
- **Fix:** Create `AppConstants.swift` with `Timing`, `Conversion`, `UI` namespaces.

#### 5.8 Deprecated API usage
- **6x `@ObservedObject`** — Project targets iOS 17+ with `@Observable`. Should migrate:
  - `ExerciseDetailView.swift:11`
  - `ExerciseLibraryView.swift:7-8`
  - `WorkoutIdleComponents.swift:12`
  - `ExercisePickerView.swift:12-13`
- **5x `UIApplication.shared.open(url)`** — Should use `@Environment(\.openURL)`:
  - `SettingsView.swift:129, 388`
  - `ExerciseDetailView.swift:95`
  - `ExercisePreviewSheet.swift:234`
  - `WorkoutCompletionView.swift:562`

---

## 6. Priority Fix Roadmap

### Immediate (before App Store submission)

| # | Issue | Impact | Effort |
|:---|:---|:---|:---|
| 1 | Wrap 80+ print() in `#if DEBUG` or replace with os.Logger | Release log pollution | Low |
| 2 | Add `fetchLimit` to unbounded SwiftData queries | Scales poorly with data growth | Low |
| 3 | Guard division by zero in `StrengthScoreCalculator.lerp` | Potential crash | Low |
| 4 | Add `@MainActor` to `WorkoutRepository` | Thread safety crash | Low |

### Short-term (v1.1)

| # | Issue | Impact | Effort |
|:---|:---|:---|:---|
| 5 | Implement NSCache for GIF data in ExerciseGifView | Memory pressure | Medium |
| 6 | Cache computed properties in LocationSelectionPage, GoalSelectionPage | Wasted CPU per frame | Medium |
| 7 | Replace DispatchQueue.asyncAfter with Task.sleep | Stale state updates | Low |
| 8 | Create AppConstants.swift for magic numbers | Maintainability | Low |
| 9 | Deduplicate equipment filter logic | DRY violation | Medium |
| 10 | Migrate @ObservedObject to @Observable | Deprecated pattern | Low |

### Medium-term (v1.2)

| # | Issue | Impact | Effort |
|:---|:---|:---|:---|
| 11 | Split AppState into 4 focused state managers | God object | High |
| 12 | Replace direct AppState mutation with ViewModel callbacks | Data flow | High |
| 13 | Add production error logging (os.Logger) | Invisible failures | Medium |
| 14 | Extract large Views into sub-components (< 200 lines) | Maintainability | High |
| 15 | Background GIF decoding with placeholder | UI responsiveness | Medium |

---

## 7. Positive Findings

- **Zero force unwraps** (`as!` / `try!`) — excellent safety discipline
- **Only 1 TODO** — codebase is clean of tech debt markers
- **Consistent naming** — all enum cases follow conventions, Japanese comments are uniform
- **SwiftData relationships properly configured** — cascade delete set correctly
- **Optional binding used consistently** — `.first?`, `guard let`, `if let` patterns correct
- **Recovery progress guard** — `RecoveryCalculator` properly guards against division by zero
- **Array slicing safe** — `.prefix()`, `.dropFirst()` used instead of raw subscripts
