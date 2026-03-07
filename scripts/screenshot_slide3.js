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

  const imgData = require('fs').readFileSync('/tmp/raw_slide3.png').toString('base64');

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
    background: #06060E;
    position: relative;
    overflow: hidden;
    font-family: 'Syne', sans-serif;
  }
  body::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    background:
      radial-gradient(ellipse at 50% 40%, rgba(160,32,240,0.08) 0%, transparent 50%),
      radial-gradient(ellipse at 20% 80%, rgba(0,212,255,0.06) 0%, transparent 50%);
    pointer-events: none;
  }
  .copy {
    position: absolute;
    top: 160px;
    left: 100px;
    z-index: 10;
  }
  .badge {
    display: inline-block;
    background: rgba(160,32,240,0.12);
    border: 1px solid rgba(160,32,240,0.3);
    border-radius: 100px;
    padding: 14px 44px;
    margin-bottom: 40px;
  }
  .badge span {
    font-family: 'Space Mono', monospace;
    font-size: 28px;
    color: #A020F0;
  }
  .copy .line1 {
    font-size: 140px;
    font-weight: 800;
    color: white;
    letter-spacing: -0.02em;
    line-height: 1.1;
  }
  .copy .line2 {
    font-size: 140px;
    font-weight: 800;
    background: linear-gradient(135deg, #A020F0, #00D4FF);
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
    transform: rotateY(-14deg) rotateX(6deg) rotateZ(3deg);
    filter: drop-shadow(-50px 70px 110px rgba(0,0,0,0.9))
            drop-shadow(-10px 20px 30px rgba(160,32,240,0.2));
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
    background: linear-gradient(135deg, #A020F0, #00D4FF);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
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
    <div class="badge"><span>★ Pro Feature</span></div>
    <div class="line1">あなたの筋力を</div>
    <div class="line2">証明する。</div>
    <div class="sub">Strength Map — 全身の筋力スコアを可視化</div>
  </div>
  <div class="phone-container">
    <div class="phone">
      <img src="data:image/png;base64,${imgData}" />
    </div>
  </div>
  <div class="bottom">
    <div class="brand">MUSCLEMAP PRO</div>
    <div class="cta">月額 ¥590 / 年額 ¥4,900</div>
  </div>
</body>
</html>
  `, { waitUntil: 'networkidle0', timeout: 30000 });

  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: path.join('/Users/og3939397/MuscleMap/scripts/screenshots', 'slide3.png'),
    type: 'png'
  });
  console.log('slide3.png saved');
  await browser.close();
})();
