# CC Prompt: HomeView redesign — Action-First Layout

## Goal
Restructure the home screen so users know "what to train today" within 0.3 seconds of opening the app.

## Read first
1. `CLAUDE.md`
2. `MuscleMap/Views/Home/HomeView.swift`
3. `MuscleMap/Views/Home/HomeHelpers.swift`
4. `MuscleMap/Views/Home/MuscleMapView.swift`

## Current layout (problematic)
```
1. WeeklyStreakBadge
2. ChallengeProgressBanner
3. MuscleMapView (height: 350) ← 44% of screen. Core problem.
4. TodayRecommendationInline ← Below fold, invisible without scroll
5. StrengthMap area
```

## New layout (Action-First)
```
1. TodayActionCard (today's plan + CTA) ← Move to TOP
2. RecoveryStatusSection (compact map front+back + status chips)
3. StatsRow (sessions / volume / PRs)
4. QuickAccessRow (Strength Map / History shortcuts)
5. StrengthMapPreviewBanner (if not premium)
```

---

## Section A: TodayActionCard (NEW component)

### File: `MuscleMap/Views/Home/TodayActionCard.swift`

```
+----------------------------------------------+
| Today: Chest + Triceps         fire 6 weeks  |
| Day 1 - 4 exercises, ~45 min                |
|                                              |
| [Bench][Incline][Fly][TricepsPD]             | <- horizontal scroll GIF thumbnails
|                                              |
| +------------------------------------------+|
| |       Start Workout                       ||  <- main CTA (mmAccentPrimary gradient)
| +------------------------------------------+|
+----------------------------------------------+
```

### Specs
- Background: `LinearGradient(colors: [Color(red:0.05,green:0.16,blue:0.09), Color.mmBgSecondary])` with 170deg angle
- Border: `mmAccentPrimary.opacity(0.15)` 1px
- Corner: 16pt
- Title: "Today: [muscle group]" - 18px Heavy white
- Sub: "Day N - N exercises, ~N min" - 12px white 50%
- Streak badge: small pill top-right (move from current WeeklyStreakBadge)
- Exercise cards: ScrollView(.horizontal), each card 82pt wide
  - Top: ExerciseGifView(size: .thumbnail) or dumbbell placeholder
  - Bottom: exercise name (10px) + sets x reps (9px gray)
- CTA: "Start Workout" button
  - Height 48px, corner 14pt
  - Background: LinearGradient green
  - Text: 16px Heavy black
  - onTap: AppState.shared.selectedTab = 1

### Data
- From `vm.todayRoutine`: day name, exercises, sets
- Fallback to `recommendedWorkout` if no routine
- If neither: show "Set up your routine" card

### L10n
- isJapanese ? "今日:" : "Today:"
- isJapanese ? "ワークアウトを開始" : "Start Workout"

---

## Section B: RecoveryStatusSection (MODIFIED)

### File: `MuscleMap/Views/Home/RecoveryStatusSection.swift`

```
+----------------------------------------------+
| Recovery Status                    Details > |
|                                              |
| +------+ +------+  +----------------------+ |
| | Front| | Back |  | * Chest - 6h ago     | |
| | map  | | map  |  | * Back - 28h ago     | | <- status chips
| |      | |      |  | * Legs - recovered   | |
| |      | |      |  | * Shoulders - alert  | |
| +------+ +------+  +----------------------+ |
+----------------------------------------------+
```

### Specs
- Background: mmBgSecondary, corner 16pt, padding 14pt
- Header: "Recovery Status" 14px Bold + "Details >" text button
- HStack(spacing: 10):
  - Front map: MuscleMapView - **height: 160pt** (down from 350)
  - Back map: MuscleMapView - **height: 160pt**
  - Status chips: VStack(spacing: 6)
    - Each chip: rounded rect with color-coded background
    - Red = fatigued (0-30%), Yellow = recovering (30-70%), Green = recovered (70%+), Purple = neglected (7+ days)
    - Text: "[Group]" + "Nh ago, N% recovered" or "Recovered" or "Neglected warning"

### CRITICAL: Do NOT modify MuscleMapView.swift
- Control height via .frame(height: 160) on the outside
- Keep front/back side-by-side (current approach)

### Status chips data
- From vm.muscleStates: recovery % and last stimulation date per muscle
- Group by muscle group (chest = avg of chest_upper + chest_lower)
- Show top 4 groups as chips

---

## Section C: HomeStatsRow

### File: `MuscleMap/Views/Home/HomeStatsRow.swift`

```
+----------+ +----------+ +----------+
|    18    | |   76.4k  | |    3     |
| Sessions | | Volume   | | PRs      |
+----------+ +----------+ +----------+
```

- Each card: mmBgSecondary, corner 12pt, padding 12pt, center text
- Number: 20px Heavy white
- Label: 10px mmTextSecondary
- Data: this month's sessions / total volume / PR count

---

## Section D: QuickAccessRow (in HomeStatsRow.swift)

```
+------------------+ +------------------+
| Strength Map     | | History          |
| See your balance | | 17 days trained  |
+------------------+ +------------------+
```

- Strength Map: border mmAccentSecondary.opacity(0.15), tap toggles showingStrengthMap
- History: mmBgSecondary, tap navigates to history tab

---

## Files to change

### Modify
1. `HomeView.swift` - Reorder sections, replace TodayRecommendationInline with TodayActionCard

### Create new
2. `TodayActionCard.swift` - Section A
3. `RecoveryStatusSection.swift` - Section B
4. `HomeStatsRow.swift` - Section C + D

### Do NOT change
- MuscleMapView.swift (control height externally)
- MusclePathData.swift (SVG path data, never touch)
- HomeHelpers.swift (keep for other helpers, TodayRecommendationInline stays as fallback)

---

## Rules
1. Do NOT modify MuscleMapView.swift or MusclePathData.swift
2. Split views over 200 lines into separate files
3. Keep all existing sheets (selectedMuscle, showingStrengthMap, showingPaywall, etc.)
4. L10n: use isJapanese pattern for all new strings
5. Keep coach marks and map explanation overlays
6. Free user limit check is in ContentView, CTA just switches tab
7. Follow CLAUDE.md design system (colors, spacing, corner radius)

## Checklist
- [ ] "What to train today" visible within 0.3s of opening
- [ ] Muscle map shows both front and back (compact)
- [ ] Status chips show recovery % and time
- [ ] "Start Workout" CTA is prominent at top
- [ ] Streak badge is visible
- [ ] Fallback for no routine set
- [ ] Strength Map access preserved
- [ ] Muscle tap -> detail sheet works
- [ ] Pro/free display switching correct
