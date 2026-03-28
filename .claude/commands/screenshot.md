# Screenshot & Verify

Take a simulator screenshot, resize it for safe API consumption, and read it.

```bash
xcrun simctl io booted screenshot /tmp/check.png
sips -Z 800 /tmp/check.png --out /tmp/check_small.png
```

Read `/tmp/check_small.png` and verify against DESIGN_SYSTEM.md principles:
1. No dead whitespace (Principle 1)
2. Most important info is largest (Principle 2)
3. GIFs are identifiable size (Principle 3)
4. Screen is 80%+ filled with content (Principle 4)
5. UI components are consistent across screens (Principle 5)
6. Text is readable in dark mode
