#!/usr/bin/env node
/**
 * MuscleMap v1.1 App Store Screenshot Generator
 *
 * 完全自動: HTMLテンプレート生成 → Puppeteerでキャプチャ → 1284×2778px PNG出力
 *
 * Usage:
 *   cd MuscleMap/screenshots
 *   npm install puppeteer
 *   npx puppeteer browsers install chrome
 *
 *   # Step 1: シミュレーターで各画面を表示してスクショを撮る
 *   #   xcrun simctl io booted screenshot screens/shot1_screen.png
 *   #   (画面遷移) → xcrun simctl io booted screenshot screens/shot2_screen.png
 *   #   ... 6画面分
 *
 *   # Step 2: 生成実行
 *   node generate_all.js
 *
 *   # Step 2b: 対話的にシミュレーターからキャプチャしながら生成
 *   node generate_all.js --interactive
 *
 * Output: screenshots/output_v11/shot{N}_{lang}.png
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');
const readline = require('readline');
const { execSync } = require('child_process');

// ── Shot definitions ──────────────────────────────────────────
const SHOTS = [
  {
    id: 1,
    file: 'shot1_screen.png',
    ja: {
      headline: '昨日の筋トレ、\n今どこに残ってる？',
      sub: '21部位 × リアルタイム回復マップ',
      accent: '#00FFB3',
      chips: [
        { label: '21', desc: '筋肉' },
        { label: '92', desc: '種目' },
        { label: 'EMG', desc: 'ベース' },
      ],
    },
    en: {
      headline: 'Your muscles\nlight up.',
      sub: '21 muscles × real-time recovery map',
      accent: '#00FFB3',
      chips: [
        { label: '21', desc: 'muscles' },
        { label: '92', desc: 'exercises' },
        { label: 'EMG', desc: 'based' },
      ],
    },
    nav: 'ホーム画面（回復マップ前面、色が付いた状態）',
  },
  {
    id: 2,
    file: 'shot2_screen.png',
    ja: {
      headline: '放置した筋肉、教えます',
      sub: '92種目すべてにアニメーションGIF',
      accent: '#00D4FF',
      chips: [
        { label: '92', desc: '種目' },
        { label: 'GIF', desc: '対応' },
      ],
    },
    en: {
      headline: 'See the motion,\nnot just the name.',
      sub: 'Animated GIFs for all 92 exercises',
      accent: '#00D4FF',
      chips: [
        { label: '92', desc: 'exercises' },
        { label: 'GIF', desc: 'powered' },
      ],
    },
    nav: 'ワークアウト画面 → 種目ピッカー（GIFサムネイル表示）',
  },
  {
    id: 3,
    file: 'shot3_screen.png',
    ja: {
      headline: '今日やるべき種目、自動で',
      sub: '目標×頻度×場所 → あなた専用Day分割',
      accent: '#00FFB3',
      chips: [
        { label: '目標', desc: '' },
        { label: '頻度', desc: '' },
        { label: '場所', desc: '' },
        { label: '経験', desc: '' },
      ],
    },
    en: {
      headline: 'Never wonder\nwhat to train.',
      sub: 'Goals × frequency × location → your split',
      accent: '#00FFB3',
      chips: [
        { label: 'Goals', desc: '' },
        { label: 'Frequency', desc: '' },
        { label: 'Location', desc: '' },
      ],
    },
    nav: 'ホーム画面 →「今日のルーティン」セクション（Day切替タブ表示）',
  },
  {
    id: 4,
    file: 'shot4_screen.png',
    ja: {
      headline: '前回を超えるなら、\n今回を超えろ',
      sub: 'PR更新をリアルタイムで祝福',
      accent: '#FFD700',
      chips: [{ label: 'NEW PR!', desc: '' }],
    },
    en: {
      headline: 'Auto PR detection\n& celebration.',
      sub: 'Real-time PR celebration + share card',
      accent: '#FFD700',
      chips: [{ label: 'NEW PR!', desc: '' }],
    },
    nav: 'ワークアウト完了画面（PR祝福 + 筋肉マップハイライト）',
  },
  {
    id: 5,
    file: 'shot5_screen.png',
    ja: {
      headline: 'どこに効くか、数値で見る',
      sub: 'S〜Dグレードで全身を評価',
      accent: '#00D4FF',
      chips: [
        { label: 'S', desc: '' },
        { label: 'A', desc: '' },
        { label: 'B', desc: '' },
        { label: 'C', desc: '' },
        { label: 'D', desc: '' },
      ],
    },
    en: {
      headline: 'See your strength\nin thickness.',
      sub: 'S-to-D grading across your body',
      accent: '#00D4FF',
      chips: [
        { label: 'S', desc: '' },
        { label: 'A', desc: '' },
        { label: 'B', desc: '' },
        { label: 'C', desc: '' },
        { label: 'D', desc: '' },
      ],
    },
    nav: 'Strength Mapタブ（筋肉の太さ表示、前面+背面）',
  },
  {
    id: 6,
    file: 'shot6_screen.png',
    ja: {
      headline: '週間バランス、一目で',
      sub: 'カレンダー × シェア × Apple Watch',
      accent: '#00FFB3',
      chips: [
        { label: 'Calendar', desc: '' },
        { label: 'Share', desc: '' },
        { label: 'Watch', desc: '' },
      ],
    },
    en: {
      headline: 'Your records\nbecome habits.',
      sub: 'Calendar × Share × Apple Watch',
      accent: '#00FFB3',
      chips: [
        { label: 'Calendar', desc: '' },
        { label: 'Share', desc: '' },
        { label: 'Watch', desc: '' },
      ],
    },
    nav: '履歴タブ → カレンダー表示',
  },
];

// ── HTML Template Generator ───────────────────────────────────
function generateHTML(shot, lang) {
  const d = shot[lang];
  const headlineHTML = d.headline
    .split('\n')
    .map((line) => `<div>${line}</div>`)
    .join('\n      ');

  const chipsHTML = d.chips
    .map((c) => {
      if (c.desc) {
        return `<span class="stat-chip"><strong>${c.label}</strong> ${c.desc}</span>`;
      }
      return `<span class="stat-chip solo">${c.label}</span>`;
    })
    .join('\n        ');

  const fontFamily =
    lang === 'ja'
      ? "'Noto Sans JP', 'Hiragino Sans', sans-serif"
      : "'Inter', 'SF Pro Display', sans-serif";

  const headlineFontSize = lang === 'ja' ? '78px' : '82px';

  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
<meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@500;900&family=Inter:wght@500;700;900&display=swap');

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    width: 1284px;
    height: 2778px;
    background: linear-gradient(170deg, #0C1810 0%, #0A0E0A 30%, #080C08 100%);
    font-family: ${fontFamily};
    display: flex;
    flex-direction: column;
    align-items: center;
    overflow: hidden;
    position: relative;
  }

  body::before {
    content: '';
    position: absolute;
    top: -250px;
    left: 50%;
    transform: translateX(-50%);
    width: 900px;
    height: 900px;
    background: radial-gradient(circle, ${d.accent}12 0%, transparent 70%);
    pointer-events: none;
  }

  body::after {
    content: '';
    position: absolute;
    inset: 0;
    background-image:
      linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px);
    background-size: 80px 80px;
    pointer-events: none;
  }

  .copy-area {
    padding: 160px 90px 0;
    text-align: center;
    width: 100%;
    position: relative;
    z-index: 1;
  }

  .headline {
    font-size: ${headlineFontSize};
    font-weight: 900;
    color: #FFFFFF;
    line-height: 1.22;
    letter-spacing: ${lang === 'ja' ? '3px' : '0'};
  }

  .sub-copy {
    font-size: 34px;
    font-weight: 500;
    color: ${d.accent}AA;
    margin-top: 24px;
    letter-spacing: 1px;
  }

  .stat-row {
    display: flex;
    gap: 20px;
    justify-content: center;
    margin-top: 40px;
    flex-wrap: wrap;
  }

  .stat-chip {
    padding: 10px 28px;
    background: ${d.accent}0A;
    border: 1.5px solid ${d.accent}30;
    border-radius: 40px;
    color: rgba(255, 255, 255, 0.7);
    font-size: 24px;
    font-weight: 500;
    letter-spacing: 1px;
  }

  .stat-chip.solo {
    color: ${d.accent};
    font-weight: 700;
    padding: 10px 24px;
  }

  .stat-chip strong {
    color: ${d.accent};
    font-weight: 900;
  }

  .screen-area {
    flex: 1;
    display: flex;
    align-items: flex-start;
    justify-content: center;
    padding: 60px 60px 0;
    width: 100%;
    position: relative;
    z-index: 1;
  }

  .device-frame {
    width: 640px;
    border-radius: 56px;
    overflow: hidden;
    border: 4px solid rgba(255, 255, 255, 0.06);
    box-shadow:
      0 40px 100px ${d.accent}15,
      0 0 0 1px rgba(255, 255, 255, 0.03),
      inset 0 0 0 1px rgba(255, 255, 255, 0.02);
    background: #000;
    position: relative;
  }

  .device-frame::before {
    content: '';
    position: absolute;
    top: 14px;
    left: 50%;
    transform: translateX(-50%);
    width: 140px;
    height: 34px;
    background: #000;
    border-radius: 17px;
    z-index: 10;
  }

  .device-frame::after {
    content: '';
    position: absolute;
    top: 250px;
    right: -5px;
    width: 5px;
    height: 80px;
    background: #2C2C2E;
    border-radius: 0 3px 3px 0;
  }

  .device-frame img {
    width: 100%;
    display: block;
  }

  .placeholder {
    width: 100%;
    aspect-ratio: 1179 / 2556;
    background: linear-gradient(180deg, #1a1a1a 0%, #0d0d0d 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    color: rgba(255, 255, 255, 0.15);
    font-size: 28px;
    font-weight: 500;
  }

  .screen-area::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 300px;
    background: linear-gradient(transparent, #080C08);
    pointer-events: none;
    z-index: 2;
  }
</style>
</head>
<body>
  <div class="copy-area">
    <div class="headline">
      ${headlineHTML}
    </div>
    <div class="sub-copy">${d.sub}</div>
    <div class="stat-row">
        ${chipsHTML}
    </div>
  </div>
  <div class="screen-area">
    <div class="device-frame">
      <img src="screens/${shot.file}"
           alt="Shot ${shot.id}"
           onerror="this.outerHTML='<div class=placeholder>${shot.file}</div>'">
    </div>
  </div>
</body>
</html>`;
}

// ── Interactive capture helper ────────────────────────────────
async function interactiveCapture() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const ask = (q) => new Promise((resolve) => rl.question(q, resolve));
  const screensDir = path.resolve(__dirname, 'screens');
  if (!fs.existsSync(screensDir)) fs.mkdirSync(screensDir, { recursive: true });

  console.log('\n🎯 MuscleMap v1.1 Screenshot Capture');
  console.log('━'.repeat(50));
  console.log('シミュレーターで画面を表示して、Enterを押してください。\n');

  for (const shot of SHOTS) {
    console.log(`📸 Shot ${shot.id}: ${shot.nav}`);
    await ask('   → 準備できたらEnter: ');

    const outPath = path.resolve(screensDir, shot.file);
    try {
      execSync(`xcrun simctl io booted screenshot "${outPath}"`, {
        stdio: 'pipe',
      });
      console.log(`   ✅ ${shot.file} saved\n`);
    } catch (e) {
      console.log(`   ⚠️  キャプチャ失敗: ${e.message}`);
      console.log('   シミュレーターが起動しているか確認してください\n');
    }
  }

  rl.close();
  console.log('━'.repeat(50));
  console.log('📸 キャプチャ完了。HTMLテンプレート生成に進みます...\n');
}

// ── Main ──────────────────────────────────────────────────────
(async () => {
  const isInteractive = process.argv.includes('--interactive');
  const langFilter = process.argv.includes('--en')
    ? ['en']
    : process.argv.includes('--ja')
      ? ['ja']
      : ['ja', 'en'];

  if (isInteractive) {
    await interactiveCapture();
  }

  const templateDir = path.resolve(__dirname, 'templates_v11');
  if (!fs.existsSync(templateDir)) fs.mkdirSync(templateDir, { recursive: true });

  for (const shot of SHOTS) {
    for (const lang of langFilter) {
      const html = generateHTML(shot, lang);
      const filename = `shot${shot.id}_${lang}.html`;
      fs.writeFileSync(path.resolve(templateDir, filename), html);
    }
  }
  console.log(`✅ ${SHOTS.length * langFilter.length} HTML templates generated → templates_v11/`);

  const outputDir = path.resolve(__dirname, 'output_v11');
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

  let browser;
  try {
    browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
  } catch (e) {
    console.log('⚠️  Puppeteer launch failed. Install with:');
    console.log('   npm install puppeteer && npx puppeteer browsers install chrome');
    process.exit(1);
  }

  for (const shot of SHOTS) {
    for (const lang of langFilter) {
      const htmlPath = path.resolve(templateDir, `shot${shot.id}_${lang}.html`);
      const page = await browser.newPage();
      await page.setViewport({ width: 1284, height: 2778, deviceScaleFactor: 1 });
      await page.goto(`file://${htmlPath}`, { waitUntil: 'networkidle0' });

      await page.evaluateHandle('document.fonts.ready');
      await new Promise((r) => setTimeout(r, 2000));

      const outputPath = path.resolve(outputDir, `shot${shot.id}_${lang}.png`);
      await page.screenshot({ path: outputPath, type: 'png', fullPage: false });
      console.log(`✅ shot${shot.id}_${lang}.png → output_v11/`);
      await page.close();
    }
  }

  await browser.close();
  console.log(`\n🎉 Done! ${SHOTS.length * langFilter.length} screenshots in output_v11/`);
  console.log('   App Store Connect にアップロードしてください。');
})();
