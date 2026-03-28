# Build & Verify

Build the project and take a screenshot to verify changes.

```bash
xcodebuild -project /Users/og3939397/MuscleMap/MuscleMap.xcodeproj -scheme MuscleMap -destination 'platform=iOS Simulator,id=BOOTED' build 2>&1 | tail -5
```

If BUILD SUCCEEDED:
```bash
xcrun simctl io booted screenshot /tmp/check.png
sips -Z 800 /tmp/check.png --out /tmp/check_small.png
```

Read the screenshot and verify the changes look correct.

If BUILD FAILED: read the error, fix it, and rebuild.
