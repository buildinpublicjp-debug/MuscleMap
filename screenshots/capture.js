/**
 * MuscleMap App Store Screenshot Capture
 *
 * Usage:
 *   npx puppeteer browsers install chrome
 *   node capture.js
 *
 * Prerequisites:
 *   - Node.js 18+
 *   - npm install puppeteer
 *   - Place simulator screenshots in screenshots/screens/
 *
 * Output: screenshots/output/*.png (1284x2778px)
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const shots = [
  'shot1_recovery_map',
  'shot2_neglect_warning',
  'shot3_pr_detection',
  'shot4_routine_builder',
  'shot5_strength_map',
  'shot6_share_watch',
];

(async () => {
  // output ディレクトリ確保
  const outputDir = path.resolve(__dirname, 'output');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  for (const shot of shots) {
    const htmlPath = path.resolve(__dirname, `${shot}.html`);

    if (!fs.existsSync(htmlPath)) {
      console.log(`⏭️  ${shot}.html not found, skipping`);
      continue;
    }

    const page = await browser.newPage();
    await page.setViewport({
      width: 1284,
      height: 2778,
      deviceScaleFactor: 1,
    });

    await page.goto(`file://${htmlPath}`, { waitUntil: 'networkidle0' });

    // Google Fonts 読み込み待機
    await page.evaluateHandle('document.fonts.ready');
    await new Promise((r) => setTimeout(r, 1500));

    const outputPath = path.resolve(outputDir, `${shot}.png`);
    await page.screenshot({
      path: outputPath,
      type: 'png',
      fullPage: false,
    });

    console.log(`✅ ${shot}.png → ${outputPath}`);
    await page.close();
  }

  await browser.close();
  console.log('\n🎉 All screenshots captured!');
})();
