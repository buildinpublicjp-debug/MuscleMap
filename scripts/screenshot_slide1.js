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

  const screenshotPath = '/tmp/raw_slide1.png';
  const imgData = require('fs').readFileSync(screenshotPath).toString('base64');

  await page.setContent(`
<!DOCTYPE html>
<html>
<head>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Syne:wght@800&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    width: 1290px; height: 2796px;
    background: #0A0A0A;
    background-image:
      linear-gradient(rgba(0,255,179,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(0,255,179,0.04) 1px, transparent 1px);
    background-size: 80px 80px;
    position: relative;
    overflow: hidden;
    font-family: 'Syne', sans-serif;
  }
  body::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    background: radial-gradient(ellipse at 50% 35%, rgba(0,255,179,0.07) 0%, transparent 60%);
    pointer-events: none;
  }
  .copy {
    position: absolute;
    top: 160px;
    left: 100px;
    z-index: 10;
  }
  .copy .line1 {
    font-size: 160px;
    font-weight: 800;
    color: white;
    letter-spacing: -0.02em;
    line-height: 1.1;
  }
  .copy .line2 {
    font-size: 160px;
    font-weight: 800;
    background: linear-gradient(135deg, #00FFB3, #00D4FF);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    letter-spacing: -0.02em;
    line-height: 1.1;
  }
  .copy .sub {
    margin-top: 40px;
    font-size: 50px;
    color: rgba(255,255,255,0.4);
    font-weight: 800;
  }
  .phone-container {
    position: absolute;
    top: 820px;
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
    transform: rotateY(-18deg) rotateX(8deg) rotateZ(4deg);
    filter: drop-shadow(-60px 80px 120px rgba(0,0,0,0.85))
            drop-shadow(-15px 25px 35px rgba(0,255,179,0.12));
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
    <div class="line1">筋肉の回復を、</div>
    <div class="line2">可視化する。</div>
    <div class="sub">21筋肉 × リアルタイム回復トラッキング</div>
  </div>
  <div class="phone-container">
    <div class="phone">
      <img src="data:image/png;base64,${imgData}" />
    </div>
  </div>
  <div class="bottom">
    <div class="brand">MUSCLEMAP</div>
    <div class="cta">無料ではじめる</div>
  </div>
</body>
</html>
  `, { waitUntil: 'networkidle0', timeout: 30000 });

  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: path.join('/Users/og3939397/MuscleMap/scripts/screenshots', 'slide1.png'),
    type: 'png'
  });
  console.log('slide1.png saved');
  await browser.close();
})();
