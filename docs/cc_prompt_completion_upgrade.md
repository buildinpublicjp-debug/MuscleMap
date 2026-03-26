# CC Prompt: Workout Completion Experience Upgrade

## Goal
Make the workout completion screen feel like a genuine reward. This is the moment users feel proud. It should be the most polished, emotionally impactful screen in the app.

## Read first
1. `CLAUDE.md`
2. `MuscleMap/Views/Workout/WorkoutCompletionView.swift`
3. `MuscleMap/Views/Workout/WorkoutCompletionComponents.swift`
4. `MuscleMap/Views/Workout/WorkoutCompletionSections.swift`
5. `MuscleMap/Views/Workout/ShareMuscleMapView.swift`

## Do NOT touch these files (other CC windows are working on them)
- Anything in `Views/Home/` — another window is redesigning HomeView
- `SetInputComponents.swift` and related input files — another window handles this
- `ExercisePickerView.swift` — another window handles this

## Improvements to implement

### 1. Entrance animation
When the completion screen appears:
- Background fades in (0.3s)
- Checkmark icon scales up with spring animation (0 → 1, spring bounce)
- "Workout Complete" text fades in with 0.2s delay
- Stats (volume, exercises, sets, duration) cascade in from bottom, staggered 0.1s each
- If PR was achieved: confetti particle animation (use simple circles/squares, 30 particles, 2s duration)

### 2. Stats section redesign
Current stats are small and plain. Make them the hero:
- Total volume in HUGE text (48px Heavy) with the unit smaller (16px)
- Format: "12,450 kg" not "12450"
- Below volume: 3 secondary stats in a horizontal row (exercises / sets / duration) in rounded cards
- Each stat card: number in 24px bold, label in 10px secondary

### 3. Muscle map section
- Increase map height slightly for the completion view
- Add a subtle pulsing glow animation on the muscles that were just trained (use mmAccentPrimary with opacity animation)
- Show muscle group names below the map: "Chest, Triceps" in accent color

### 4. PR celebration section
When PRs are achieved:
- Gold gradient header bar with "NEW PR!" text
- Each PR item: exercise name, previous weight → new weight, increase percentage in a green badge
- Scale animation on each PR card (staggered)
- Haptic: heavy impact when PR section appears

### 5. Summary text (emotional copy)
Add a motivational summary below the stats based on workout quality:
- Volume > 10000kg: "Beast mode activated" / "怪物モード発動"
- PR achieved: "New records set!" / "自己ベスト更新！"
- 4+ exercises: "Solid session" / "充実のセッション"
- Default: "Good work" / "おつかれさま"

Use 22px bold, centered, with the text in mmAccentPrimary.

### 6. Share card improvements
- Make the share button more prominent (not just text, use a gradient button like the CTA)
- Add Instagram Stories format option (9:16 ratio) alongside the existing square format
- Share text should include the motivational summary

### 7. Next workout suggestion
At the bottom of the completion screen, add:
- "Next recommended workout" section
- Show the next routine day (e.g., "Tomorrow: Back + Biceps")
- Based on recovery data, show estimated best next training day
- Small CTA: "Schedule reminder" → triggers notification scheduling

## Technical notes
- All changes in WorkoutCompletion*.swift and ShareMuscleMapView.swift
- Use @keyframes-equivalent SwiftUI animations (.spring, .easeInOut with delays)
- Confetti: create a simple ParticleEffect view with random position/color circles
- Follow CLAUDE.md design system strictly
- Use HapticManager for all feedback

## Checklist
- [ ] Entrance animation (fade + scale + cascade)
- [ ] Volume displayed huge (48px) with proper formatting
- [ ] 3 stat cards in horizontal row
- [ ] Muscle map has pulsing glow on trained muscles
- [ ] PR section with gold gradient + scale animation + confetti
- [ ] Motivational summary text based on workout quality
- [ ] Share button is prominent gradient button
- [ ] Next workout suggestion at bottom
- [ ] All animations have spring/easeInOut timing
- [ ] All haptics use HapticManager
- [ ] L10n for all text
