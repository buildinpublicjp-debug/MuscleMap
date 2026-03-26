# CC Prompt: Progress Photo Feature

## Goal
Add the ability to take and save body progress photos after completing a workout. This is the #1 requested feature for body recomposition tracking.

## Read first
1. `CLAUDE.md`
2. `MuscleMap/Views/Workout/WorkoutCompletionView.swift` (add photo button here)
3. `MuscleMap/Models/` (add ProgressPhoto model)

## Do NOT touch these files
- Anything in `Views/Home/`
- `SetInputComponents.swift` and related input files
- `ExercisePickerView.swift` and related

## Feature spec

### 1. Data Model: ProgressPhoto
Create `MuscleMap/Models/ProgressPhoto.swift`:
```swift
@Model
class ProgressPhoto {
    var id: UUID
    var captureDate: Date
    var imagePath: String  // relative path in app documents
    var sessionId: UUID?   // optional link to workout session
    var note: String?      // optional user note
    
    init(captureDate: Date = Date(), imagePath: String, sessionId: UUID? = nil, note: String? = nil) {
        self.id = UUID()
        self.captureDate = captureDate
        self.imagePath = imagePath
        self.sessionId = sessionId
        self.note = note
    }
}
```

Register in MuscleMapApp.swift's modelContainer.

### 2. Photo capture on completion screen
In WorkoutCompletionView, add a button:
- Position: below the share button, above "Close"
- Style: secondary button (mmBgSecondary background, white text)
- Label: isJapanese ? "体の記録を撮る" : "Take Progress Photo"
- Tap: open camera via UIImagePickerController (camera source)
- After capture:
  - Save to documents: `progress_photos/YYYY-MM-DD_HHmmss.jpg`
  - JPEG quality 0.8
  - Create ProgressPhoto record linked to current session
  - Show success animation + haptic

### 3. Progress photo gallery
Create `MuscleMap/Views/Progress/ProgressPhotoGalleryView.swift`:
- Access from Settings or History tab
- 3-column grid, chronological
- Tap: full screen viewer with swipe navigation
- Before/After comparison: select 2 photos, side-by-side with slider

### 4. Photo reminder
On completion screen, if no photo in 7+ days:
- Subtle prompt: "It's been N days since your last progress photo"

## Privacy
- ALL photos local-only (Documents directory)
- Never uploaded (matches local-first architecture)
- Include in data deletion option

## Checklist
- [ ] ProgressPhoto SwiftData model created and registered
- [ ] Camera capture from completion screen
- [ ] Photos saved locally as JPEG
- [ ] Gallery view with 3-column grid
- [ ] Full screen viewer with swipe
- [ ] Before/After comparison
- [ ] 7-day reminder on completion screen
- [ ] L10n for all strings
