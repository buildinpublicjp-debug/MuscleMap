const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1290, height: 2796, deviceScaleFactor: 1 });

  const imgData = require('fs').readFileSync('/tmp/raw_slide4.png').toString('base64');

  await page.setContent(`
<!DOCTYPE html>
<html>
<head>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Syne:wght@800&display=swap');
  @import url('https://fonts.googleapis.com/css2?family=Space+Mono&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    width: 1290px; height: 2796px;
    background: #0A0A0A;
    background-image:
      linear-gradient(rgba(0,255,179,0.03) 1px, transparent 1px),
      linear-gradient(90deg, rgba(0,255,179,0.03) 1px, transparent 1px);
    background-size: 80px 80px;
    position: relative;
    overflow: hidden;
    font-family: 'Syne', sans-serif;
  }
  .copy {
    position: absolute;
    top: 160px;
    left: 100px;
    z-index: 10;
  }
  .eyebrow {
    font-family: 'Space Mono', monospace;
    font-size: 28px;
    color: #00FFB3;
    letter-spacing: 0.2em;
    margin-bottom: 40px;
  }
  .copy .line1 {
    font-size: 148px;
    font-weight: 800;
    color: white;
    letter-spacing: -0.02em;
    line-height: 1.1;
  }
  .copy .line2 {
    font-size: 148px;
    font-weight: 800;
    background: linear-gradient(135deg, #00FFB3, #00D4FF);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    letter-spacing: -0.02em;
    line-height: 1.1;
  }
  .copy .sub {
    margin-top: 40px;
    font-size: 46px;
    color: rgba(255,255,255,0.4);
    font-weight: 800;
  }
  .phone-container {
    position: absolute;
    top: 900px;
    left: 50%;
    transform: translateX(-50%);
    perspective: 3000px;
  }
  .phone {
    width: 560px;
    height: 1100px;
    border-radius: 88px;
    background: #1A1A1A;
    border: 2px solid rgba(255,255,255,0.12);
    overflow: hidden;
    transform: rotateY(-16deg) rotateX(8deg) rotateZ(4deg);
    filter: drop-shadow(-55px 75px 115px rgba(0,0,0,0.88))
            drop-shadow(-12px 22px 32px rgba(0,255,179,0.10));
  }
  .phone img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  .bottom {
    position: absolute;
    bottom: 140px;
    left: 0; right: 0;
    text-align: center;
    z-index: 10;
  }
  .bottom .brand {
    font-size: 56px;
    font-weight: 800;
    color: white;
    letter-spacing: 0.1em;
  }
  .bottom .cta {
    margin-top: 16px;
    font-size: 32px;
    color: rgba(255,255,255,0.35);
    font-weight: 800;
  }
</style>
</head>
<body>
  <div class="copy">
    <div class="eyebrow">はじめての筋トレアプリ</div>
    <div class="line1">目標を決めて、</div>
    <div class="line2">記録をはじめよう。</div>
    <div class="sub">21の筋肉をリアルタイムで追跡</div>
  </div>
  <div class="phone-container">
    <div class="phone">
      <img src="data:image/png;base64,${imgData}" />
    </div>
  </div>
  <div class="bottom">
    <div class="brand">MUSCLEMAP</div>
    <div class="cta">無料ではじめる — 登録不要</div>
  </div>
</body>
</html>
  `, { waitUntil: 'networkidle0', timeout: 30000 });

  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: path.join('/Users/og3939397/MuscleMap/scripts/screenshots', 'slide4.png'),
    type: 'png'
  });
  console.log('slide4.png saved');
  await browser.close();
})();
