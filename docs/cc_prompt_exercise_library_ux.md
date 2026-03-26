# CC Prompt: Exercise Library & Picker UX Upgrade

## Goal
Make the exercise browsing and selection experience feel premium. The library has 92 exercises with GIFs — this is a major differentiator vs competitors. Make it shine.

## Read first
1. `CLAUDE.md`
2. `MuscleMap/Views/Workout/ExercisePickerView.swift`
3. `MuscleMap/Views/Workout/ExercisePreviewSheet.swift`
4. `MuscleMap/Views/Exercise/ExerciseLibraryView.swift`
5. `MuscleMap/Views/Exercise/ExerciseDetailView.swift`
6. `MuscleMap/Views/Exercise/ExerciseMuscleMapView.swift`
7. `MuscleMap/Views/Components/ExerciseGifView.swift`

## Do NOT touch these files (other CC windows are working on them)
- Anything in `Views/Home/` — another window is redesigning HomeView
- `SetInputComponents.swift` and related input files — another window handles this
- `WorkoutCompletion*.swift` — another window handles this

## Improvements to implement

### 1. Exercise picker visual upgrade
The picker (modal during workout) needs to feel faster and more visual:
- **Larger GIF thumbnails**: Current thumbnails are small. Increase to 60×60px minimum
- **Grid view option**: Add a toggle to switch between list view (current) and 2-column grid view with larger GIF cards
- **Grid card**: 170px width, GIF takes top 120px, name + muscle badge below
- Default to grid view (more visual impact)
- Remember preference in UserDefaults

### 2. Muscle group filter bar improvements
- Currently shows text tabs ("Chest", "Back", etc.)
- Add small colored dots next to each muscle group that indicate recovery status:
  - Red dot = fatigued, Green dot = recovered, Purple dot = neglected
  - This helps users avoid overtraining — they can see at a glance which muscles are recovered
- Data source: use RecoveryCalculator with latest MuscleStimulation data

### 3. Exercise detail view upgrade
- **Hero GIF**: Make the GIF larger (full width, 300px height) at the top of the detail view
- **Muscle map highlight**: Below the GIF, show a compact muscle map with the target muscles highlighted (already exists in ExerciseMuscleMapView, just ensure it's prominent)
- **"Start with this exercise" button**: If the user is in a workout session, show a prominent button to add this exercise to the current workout
- **Previous performance**: Show the user's last 3 sessions with this exercise:
  ```
  Previous performance:
  Mar 20: 80kg × 8, 82.5kg × 6, 85kg × 5
  Mar 15: 77.5kg × 10, 80kg × 8, 82.5kg × 6  
  Mar 10: 75kg × 10, 77.5kg × 8, 80kg × 6
  ```
- This creates the progressive overload motivation

### 4. Search improvements
- **Instant search**: Filter results as user types (debounce 200ms)
- **Search by muscle**: Typing "chest" should also surface exercises that target chest even if "chest" isn't in the name
- **Search by equipment**: Typing "dumbbell" or "ダンベル" shows all dumbbell exercises
- **Recent searches**: Show last 3 searches when search field is focused but empty

### 5. Favorites section
- Pin favorited exercises at the top of the picker/library
- Show favorites as a horizontal scroll row above the main list
- Easy favorite toggle: heart icon on each exercise card
- Persist in FavoritesManager (already exists)

### 6. Exercise comparison (bonus)
- Long-press on two exercises → compare sheet showing:
  - Side-by-side GIFs
  - Target muscles comparison (muscle map with both highlighted)
  - User's best performance on each
  - Equipment needed

## Technical notes
- Files: ExercisePickerView.swift, ExercisePreviewSheet.swift, ExerciseLibraryView.swift, ExerciseDetailView.swift
- Use ExerciseStore.shared for exercise data
- Use FavoritesManager for favorites
- GIFs: ExerciseGifView component (don't modify, just use with different .size params)
- Recovery data: MuscleStateRepository + RecoveryCalculator
- Follow CLAUDE.md 200-line rule — split views into subcomponents

## Checklist
- [ ] Grid view option in exercise picker (2-column, larger GIF cards)
- [ ] Grid/list toggle persisted in UserDefaults
- [ ] Muscle group filter has recovery status dots (red/green/purple)
- [ ] Exercise detail has hero GIF (full width, 300px)
- [ ] Exercise detail shows last 3 sessions of performance data
- [ ] "Add to workout" button in detail view during active session
- [ ] Search filters by muscle name and equipment type
- [ ] Recent searches shown when search field is focused
- [ ] Favorites pinned at top as horizontal scroll row
- [ ] All text L10n (isJapanese pattern)
- [ ] All views under 200 lines
