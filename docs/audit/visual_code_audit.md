# MuscleMap Visual Code Audit Report

> **Date:** 2026-03-18
> **Scope:** All `.swift` files under `MuscleMap/Views/` (67 files)
> **Reference:** CLAUDE.md v4.0 design system rules
> **Method:** Static code analysis (grep/read), no runtime inspection

---

## Summary Table

| # | Item | Compliance Rate | Violation Count | Severity |
|---|------|:-:|:-:|:-:|
| 1 | Spacing (8pt grid) | **~41%** | ~330 | HIGH |
| 2 | Font Hierarchy (L1-L4) | **67.6%** semantic | 266 ad-hoc | HIGH |
| 3 | Color System | **~98.5%** | 17 | LOW |
| 4 | cornerRadius (4-tier) | **72.0%** | 68 | MEDIUM |
| 5 | Tap Area (44pt min) | **~98%** | 2 definite | LOW |
| 6 | Haptic + Animation | **3/5 PASS** | 2 partial | MEDIUM |
| 7 | Empty State | **12/20 covered** | 8 missing | MEDIUM |

---

## 1. Spacing (8pt Grid)

**Rule:** All spacing values must be multiples of 8 (0, 8, 16, 24, 32, 40, 48...).

### Overall Statistics (Non-Onboarding)

| Category | Total | Compliant | Violations | Rate |
|----------|------:|----------:|-----------:|-----:|
| `spacing:` | ~310 | ~120 | ~190 | 39% |
| `.padding()` | ~210 | ~95 | ~115 | 45% |
| `Spacer().frame(height:)` | 0 | 0 | 0 | N/A |
| `.frame()` spacing | ~35 | ~10 | ~25 | 29% |
| **TOTAL** | **~555** | **~225** | **~330** | **~41%** |

### Most Frequent Violation Values

| Value | Count | Nearest 8pt | Disposition |
|------:|------:|:-----------:|:------------|
| 12 | ~95 | 16 | Most common -- should be 16 |
| 4 | ~75 | 8 | Should be 8 |
| 2 | ~45 | 8 | Should be 8 |
| 6 | ~35 | 8 | Should be 8 |
| 10 | ~15 | 8 | Should be 8 |
| 20 | ~15 | 24 | Should be 24 |
| 3 | ~8 | 8 | Should be 8 |
| 1 | ~6 | 8 | Divider/hairline (intentional?) |
| 14 | ~3 | 16 | Should be 16 |

### Top Files by Violation Count

| File | Approx Violations |
|------|------------------:|
| `Views/Home/HomeHelpers.swift` | ~30 |
| `Views/Workout/WorkoutCompletionComponents.swift` | ~25 |
| `Views/Home/MuscleHeatmapView.swift` | ~20 |
| `Views/Workout/SetInputComponents.swift` | ~18 |
| `Views/Home/MuscleJourneyView.swift` | ~18 |
| `Views/Settings/SettingsView.swift` | ~18 |
| `Views/Home/MuscleBalanceDiagnosisView.swift` | ~16 |
| `Views/Workout/ExercisePreviewSheet.swift` | ~16 |
| `Views/Home/WeeklySummaryView.swift` | ~14 |
| `Views/Workout/WorkoutCompletionSections.swift` | ~14 |

### Key Finding

`spacing: 12` and `.padding(12)` account for ~95 violations. A single systematic `12 -> 16` migration would eliminate **~29%** of all spacing violations.

---

## 2. Font Hierarchy

**Rule:** L1 `.largeTitle` + Heavy, L2 `.title2` + Bold, L3 `.title3` + Bold, L4 `.body`/`.caption` Regular. Key numbers must be 2x+ the label font size.

### Global Counts

| Metric | Count |
|--------|------:|
| Ad-hoc `.font(.system(size:))` | **266** |
| Semantic font usage | **554** |
| Ratio (semantic : ad-hoc) | **2.08 : 1** |
| `.largeTitle` usage (L1) | **3** |
| `.headline` used as section title (should be `.title2`) | **~40+** |

### L1 Violations: Screen Titles

Only **3** `.largeTitle` usages exist in all Views/:

| File | Line | Usage | Status |
|------|------|-------|--------|
| `WorkoutCompletionView.swift` | 142 | `.largeTitle.weight(.heavy)` | PASS |
| `FullBodyConquestView.swift` | 46 | `.largeTitle.bold()` | PARTIAL (bold, not heavy) |
| `HomeStreakComponents.swift` | 78 | `.largeTitle.bold()` | PARTIAL (bold, not heavy) |

**13 onboarding pages** use `.system(size: 28, weight: .heavy)` instead of `.largeTitle` (34pt).

### L2 Violations: Section Titles Using `.headline` Instead of `.title2.bold()`

~40+ occurrences across 15 files including:
- `HistoryCalendarComponents.swift`, `HistoryStatsComponents.swift`, `HistorySessionComponents.swift`
- `MuscleDetailView.swift` (4 locations), `ActiveWorkoutComponents.swift` (2 locations)
- `ExerciseDetailView.swift` (4 locations), `WorkoutIdleComponents.swift` (3 locations)
- `HomeView.swift`, `WeeklySummaryView.swift`, `DayWorkoutDetailView.swift`
- `ExerciseLibraryView.swift`, `MonthlyCalendarView.swift`, `SettingsView.swift`

### 2x Key Number Rule Violations

| File | Number Font | Label Font | Ratio | Status |
|------|-------------|-----------|------:|--------|
| `HomeHelpers.swift` (5 locations) | `size: 16, bold` | `size: 14` | 1.14x | FAIL |
| `MenuPreviewSheet.swift` L228 | `size: 14` | `size: 14` | 1.0x | FAIL |
| `PRInputPage.swift` L143 | `size: 32` | `size: 24` | 1.3x | FAIL |
| `StrengthShareCard.swift` L83 | `size: 15` | `size: 11` | 1.4x | FAIL |
| `DayWorkoutDetailView.swift` L195 | `.title3.bold()` (~20pt) | `.caption` (~12pt) | 1.67x | BORDERLINE |

### Files with Zero Semantic Fonts (100% Ad-Hoc)

- `StrengthShareCard.swift` (12 ad-hoc)
- `MenuPreviewSheet.swift` (11 ad-hoc)
- `GoalSelectionPage.swift` (10 ad-hoc)
- `LocationSelectionPage.swift` (11 ad-hoc)
- `FrequencySelectionPage.swift` (9 ad-hoc)
- `GoalMusclePreviewPage.swift` (9 ad-hoc)

**Note:** StrengthShareCard and WorkoutCompletionComponents are image-rendered share cards (@3x PNG). Ad-hoc sizes may be justified to avoid Dynamic Type shifts in exported images.

---

## 3. Color System

**Rule:** Use `mm*` design tokens only. No `Color.black`, no raw `Color(red:)`, no system colors. `foregroundStyle` over `foregroundColor`. Onboarding tokens (`mmOnboarding*`) must not leak outside `Views/Onboarding/`.

### Results

| Check | Result | Status |
|-------|--------|--------|
| `Color.black` (#000000) | **0** occurrences | PASS |
| System colors (`.gray`, `.red`, etc.) | **0** occurrences | PASS |
| `foregroundStyle` adoption | **866** of 869 (99.65%) | PASS |
| Design token coverage | ~98.5% of color references | PASS |
| `foregroundColor` (deprecated) | **3** (all TextField prompt context) | MINOR |

### Violations (17 total across 4 files)

| File | Line | Issue | Severity |
|------|------|-------|----------|
| `AnalyticsMenuView.swift` | 47 | `Color(red: 0.2, green: 0.8, blue: 0.5)` -- should use mmAccentPrimary | MEDIUM |
| `AnalyticsMenuView.swift` | 105 | `Color(red: 0.6, green: 0.4, blue: 1.0)` -- should use mmBrandPurple | MEDIUM |
| `PaywallView.swift` | 175 | `.background(Color.mmOnboardingCard)` -- should use mmBgCard | MEDIUM |
| `PaywallView.swift` | 218 | `.foregroundStyle(Color.mmOnboardingTextSub)` -- should use mmTextSecondary | MEDIUM |
| `FriendActivityCard.swift` | 211-228 | 3 custom `mm*` tokens via `UIColor(red:)` (mmPRCardBg, mmPRBorder, mmPRAccent) | MEDIUM |
| `WorkoutCompletionComponents.swift` | 348 | `Color.white.opacity(0.02)` in Canvas | LOW |
| 3 files | various | `.foregroundColor()` on TextField prompts | LOW |

### Under-Utilized Tokens

| Token | Usage Count | Note |
|-------|:----------:|------|
| `Color.mmPRGold` | 1 | FriendActivityCard defines its own gold via UIColor |
| `Color.mmWarning` | 1 | |
| `Color.mmBrandPurple` | 1 | AnalyticsMenuView uses raw Color(red:) instead |

---

## 4. cornerRadius (4-Tier Normalization)

**Rule:** Only 4pt (small badge), 8pt (tag), 16pt (card/button), 24pt (large modal) allowed.

### Overall Statistics

| Metric | Count |
|--------|------:|
| Total cornerRadius usages | **243** |
| Compliant (4/8/16/24) | **175** |
| Violations | **68** |
| Compliance rate | **72.0%** |
| `Capsule()` (allowed) | 40 |
| Deprecated `.cornerRadius()` | 1 |

### Value Distribution

| Value | Count | Status | Nearest Tier |
|------:|------:|--------|:------------:|
| 1 | 1 | VIOLATION | 4pt |
| 2 | 10 | VIOLATION | 4pt |
| 3 | 6 | VIOLATION | 4pt |
| **4** | **15** | COMPLIANT | T1 |
| 6 | 6 | VIOLATION | 8pt |
| **8** | **30** | COMPLIANT | T2 |
| 10 | 5 | VIOLATION | 8pt |
| **12** | **57** | VIOLATION | 16pt |
| **16** | **101** | COMPLIANT | T3 |
| **24** | **12** | COMPLIANT | T4 |

### Key Finding

`cornerRadius: 12` accounts for **57 of 68 violations (83.8%)**. A single `12 -> 16` migration would bring compliance from 72% to ~95%.

### Top Offending Files

| File | Violations |
|------|:---------:|
| `Views/Home/HomeHelpers.swift` | 9 |
| `Views/Workout/ExercisePreviewSheet.swift` | 5 |
| `Views/Home/MuscleHeatmapView.swift` | 5 |
| `Views/Home/MuscleBalanceDiagnosisView.swift` | 5 |
| `Views/Settings/RoutineEditView.swift` | 3 |
| `Views/Components/ExerciseGifView.swift` | 3 |
| `Views/Exercise/ExerciseDetailView.swift` | 3 |

---

## 5. Tap Area (44pt Minimum)

**Rule:** All interactive elements must have a minimum 44x44pt tap target (Apple HIG).

### Summary

- **131 Button instances** scanned in Views/
- **0** uses of `.frame(minHeight: 44)` (no explicit enforcement)
- Most primary action buttons are 44-60pt height (compliant)

### Definite Violations

| File | Line | Element | Size | Severity |
|------|------|---------|------|----------|
| `DayWorkoutDetailView.swift` | 183 | Ellipsis "..." Button | 28x28pt | HIGH |
| `WeightInputPage.swift` | 92 | kg/lb unit toggle | 48x32pt | HIGH |

### Medium-Risk Items

- `RoutineEditView.swift` L316-362: +/- stepper buttons use `.font(.title2)` SF Symbol without explicit frame. Intrinsic size ~28pt, may be insufficient.

---

## 6. Haptic + Animation

**Rule:** 5 required micro-interactions per CLAUDE.md.

### HapticManager Stats

- **9 haptic methods** available in `HapticManager.swift`
- **115 total calls** across 45 files
- **71 `withAnimation` calls** across 28 View files

### Required Haptics Compliance

| # | Required Interaction | Haptic | Animation | Status |
|---|---------------------|--------|-----------|--------|
| 1 | Set completion -> medium + check animation | `setCompleted()` medium | bounce scale | **PASS** |
| 2 | Workout end -> heavy + summary transition | `workoutEnded()` heavy | summary nav | **PASS** |
| 3 | PR achievement -> heavy + celebration + confetti | `prAchieved()` heavy x3 | confetti + spring | **PASS** |
| 4 | Exercise add -> light + slide-in | `lightTap()` light | **NO slide-in transition** | **FAIL** |
| 5 | Button tap -> light + scale animation | `lightTap()` 80+ calls | **Most buttons lack `.scaleEffect`** | **FAIL** |

### Detail: Exercise Add (FAIL)

`HapticManager.lightTap()` fires correctly when exercise is added, but no `.transition(.move(edge:))` exists on exercise list items in `ActiveWorkoutComponents` or `RecordedSetsComponents`. The only `.move(edge:)` in Workout/ is in `FullBodyConquestView:340` (unrelated).

### Detail: Button Tap Scale (FAIL)

`HapticManager.lightTap()` is called on 80+ buttons, but only the record-set button (`SetInputComponents:296`) has `.scaleEffect` animation. All other buttons (including primary CTAs, navigation buttons, onboarding "Continue" buttons) lack scale feedback.

---

## 7. Empty State

**Rule:** All data-dependent screens should show meaningful empty states with icon + explanatory text + action button when data is absent.

### Summary

- **0 uses of `ContentUnavailableView`** (available since iOS 17.0, the minimum target)
- **12 screens** with good custom empty states
- **8 screens** missing empty states

### Screens WITH Empty States (12)

| Screen | File | Quality |
|--------|------|---------|
| ActiveWorkoutView (no sets) | `ActiveWorkoutComponents.swift` | icon+text+action |
| HomeView coach mark (first time) | `HomeHelpers.swift` | icon+text+action |
| ExercisePicker (recent filter) | `ExercisePickerView.swift` | icon+text |
| ExercisePicker (favorites filter) | `ExercisePickerView.swift` | icon+text |
| DayWorkoutDetailView (no sessions) | `DayWorkoutDetailView.swift` | icon+text |
| MuscleHistoryDetailSheet (chart) | `MuscleHistoryDetailSheet.swift` | icon+text |
| MuscleHistoryDetailSheet (exercises) | `MuscleHistoryDetailSheet.swift` | icon+text |
| MuscleJourneyView (no data) | `MuscleJourneyView.swift` | icon+text |
| HistoryMapComponents (trend) | `HistoryMapComponents.swift` | icon+text |
| SessionHistorySection | `HistoryCalendarComponents.swift` | icon+text |
| DailyVolumeChart | `HistoryCalendarComponents.swift` | icon+text |
| WeeklySummaryView (lazy muscles) | `WeeklySummaryView.swift` | text-only |

### Screens MISSING Empty States (8)

| Screen | File | Priority | Issue |
|--------|------|----------|-------|
| HistoryView (map mode) | `HistoryMapComponents.swift` | **HIGH** | Gray muscle map with no guidance for new users |
| HistoryView (calendar mode) | `HistoryCalendarComponents.swift` | **HIGH** | Calendar renders with no dots, no first-time explanation |
| WeeklySummaryView (0 sessions) | `WeeklySummaryView.swift` | MEDIUM | Shows zeros everywhere, no "no workouts this week" state |
| MuscleHeatmapView | `MuscleHeatmapView.swift` | MEDIUM | Empty grid renders, no "no data yet" message |
| ExercisePicker (search) | `ExercisePickerView.swift` | LOW | No "no results for 'xyz'" state |
| ExerciseLibrary (search) | `ExerciseLibraryView.swift` | LOW | No "no results for 'xyz'" state |
| MuscleDetailView (history) | `MuscleDetailView.swift` | LOW | Sections silently hidden when empty |
| ActivityFeedView | `ActivityFeedView.swift` | LOW | Uses mock data; needs empty state for real data |

---

## Improvement Impact TOP 10

Ranked by the number of violations fixed per unit of effort.

| Rank | Action | Files Affected | Violations Fixed | Effort |
|-----:|--------|:-:|:-:|:---:|
| 1 | **`cornerRadius: 12` -> `16`** across all Views/ | ~25 | ~57 | Low (find-replace) |
| 2 | **`spacing: 12` -> `16`** across all Views/ | ~30 | ~95 | Low (find-replace, visual review needed) |
| 3 | **`.headline` -> `.title2.bold()`** for section titles | ~15 | ~40+ | Low (find-replace) |
| 4 | **`spacing: 4` -> `8`** in VStack/HStack | ~25 | ~75 | Medium (some may need visual adjustment) |
| 5 | **Onboarding `.system(size:28)` -> `.largeTitle`** | 13 | 13 | Low (consistent pattern) |
| 6 | **Add `.scaleEffect` to all lightTap() buttons** | ~30 | 1 rule (80+ buttons) | Medium (needs reusable ButtonStyle) |
| 7 | **Add slide-in transition to exercise add** | 1-2 | 1 rule | Low |
| 8 | **HistoryView empty states** (map + calendar) | 2 | 2 missing screens | Medium |
| 9 | **PaywallView `mmOnboarding*` -> `mm*`** token fix | 1 | 2 | Low |
| 10 | **FriendActivityCard UIColor -> ColorExtensions** | 1 | 9 (3 token defs) | Low |

---

## Appendix: Notes

- **Onboarding views** are reported separately in each audit section. They follow their own color palette (`mmOnboarding*`) but should still comply with spacing, cornerRadius, and font rules.
- **Share cards** (`StrengthShareCard.swift`, `WorkoutCompletionComponents.swift`) render at @3x into PNG via `ImageRenderer`. Ad-hoc font sizes are partially justified here to avoid Dynamic Type interference.
- **Divider/hairline values** (0.5pt, 1pt) in `.frame(height:)` are borderline -- these serve as visual separators where 8pt would be inappropriate. Consider documenting as an explicit exception.
- **No files were modified** during this audit.
