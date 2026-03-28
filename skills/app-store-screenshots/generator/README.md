# MuscleMap App Store Screenshot Generator

## Quick Start

```bash
cd skills/app-store-screenshots/generator
npm install
npm run dev
```

Open http://localhost:3000

## How to use

1. Capture simulator screenshots into `public/screenshots/`:
   ```bash
   xcrun simctl io booted screenshot ./public/screenshots/shot1_screen.png
   ```

2. Open the dev server, select language, preview all 6 shots

3. Click "Export All Sizes" on any shot → downloads 4 PNGs (6.9", 6.5", 6.3", 6.1")

4. Upload to App Store Connect

## File naming

- Input: `shot{N}_screen.png` (from simulator)
- Output: `shot{N}_{lang}_{size}.png`

## iPhone mockup

The iPhone frame is rendered via CSS (see `globals.css`).
For a real mockup.png overlay, download from:
- [ParthJadhav/app-store-screenshots](https://github.com/ParthJadhav/app-store-screenshots) (`mockup.png`)
- [Figma Community iPhone 16 Pro mockup](https://www.figma.com/community/file/1428256954098627497)

Place as `public/mockup.png` and update `page.tsx` to use image overlay instead of CSS frame.

## Customization

- Edit `src/copy.ts` for headlines, sub-copy, and chips
- Edit `src/app/globals.css` for iPhone frame styling
- Edit `src/app/page.tsx` for layout, sizing, and export logic
