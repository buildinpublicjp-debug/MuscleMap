# CC Prompt: Workout Input UX Upgrade

## Goal
Make set recording faster and more satisfying. The moment-to-moment experience of logging weight/reps is what users do 50+ times per session. Every tap saved = better app.

## Read first
1. `CLAUDE.md`
2. `MuscleMap/Views/Workout/SetInputComponents.swift`
3. `MuscleMap/Views/Workout/ActiveWorkoutComponents.swift`
4. `MuscleMap/Views/Workout/WorkoutInputHelpers.swift`
5. `MuscleMap/Views/Workout/RecordedSetsComponents.swift`
6. `MuscleMap/Views/Workout/WorkoutTimerComponents.swift`

## Do NOT touch these files (other CC windows are working on them)
- Anything in `Views/Home/` — another window is redesigning HomeView
- `WorkoutCompletionView.swift` and related — another window handles this
- `ExercisePickerView.swift` — another window handles this

## Improvements to implement

### 1. Smart weight pre-fill
When a user selects an exercise they've done before, auto-fill the weight field with their last recorded weight for that exercise. Currently users start from 0.

**Implementation:**
- In the set input area, when exercise changes, query the most recent WorkoutSet for that exerciseId
- Pre-fill weight with that value
- Pre-fill reps with the last recorded reps
- Show a subtle label: "前回: 80kg × 8" (isJapanese) / "Last: 80kg × 8" below the input

### 2. Weight stepper improvements
The +/- buttons for weight should have:
- **Long press acceleration**: Hold the button → starts at 2.5kg increments, after 1s speeds up to 5kg increments
- **Haptic feedback on each increment** (HapticManager.lightTap)
- **Quick-set buttons**: Show 3 preset buttons below the stepper based on recent weights for this exercise (e.g., "75", "80", "85")
- Keep the existing stepper working, just enhance it

### 3. Rep counter improvements  
- **Quick-set row**: Show common rep counts as tappable pills: 5, 8, 10, 12, 15
- Highlight the pill that matches current rep count
- Tapping a pill sets the rep count instantly

### 4. Set completion animation
When user taps "Record Set" (セットを記録):
- Brief scale animation on the button (0.95 → 1.0)
- The recorded set card slides in from the right with a spring animation
- Haptic: medium impact
- If this set is a PR (higher weight × reps than any previous), show a brief gold flash + "PR!" badge on the card

### 5. Previous sets visibility
Show the user's previous session's sets for the current exercise, displayed as ghost/reference data above the input area:
```
前回の記録:                    ← section header, subtle
Set 1: 80kg × 10  ✓           ← light gray, reference
Set 2: 82.5kg × 8  ✓
Set 3: 85kg × 6  ✓
─────────────────────
今回:                          ← section header
Set 1: 80kg × 10  ✓ (recorded)
Set 2: [input area]            ← current input
```

This helps users see what they did last time and try to beat it (progressive overload).

### 6. Rest timer auto-start
After recording a set, automatically start the rest timer (if not already running). Currently users have to manually start it.

## Technical notes
- All changes are in `Views/Workout/` files listed above
- Use existing patterns: HapticManager, L10n, mmAccentPrimary colors
- Follow CLAUDE.md spacing/font rules
- Keep views under 200 lines, split if needed

## Checklist
- [ ] Weight pre-fills with last session's value
- [ ] "Last: Xkg × Y" label shown below input
- [ ] Weight stepper has long-press acceleration
- [ ] Quick-set weight buttons shown (3 recent weights)
- [ ] Rep quick-set pills (5, 8, 10, 12, 15)
- [ ] Set completion has scale + slide animation + haptic
- [ ] PR detection on individual sets with gold badge
- [ ] Previous session's sets shown as reference
- [ ] Rest timer auto-starts after set completion
- [ ] All text L10n (isJapanese pattern)
