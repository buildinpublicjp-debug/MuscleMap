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

  const imgData = require('fs').readFileSync('/tmp/raw_slide2.png').toString('base64');

  await page.setContent(`
<!DOCTYPE html>
<html>
<head>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Syne:wght@800&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    width: 1290px; height: 2796px;
    background: #0C0C10;
    position: relative;
    overflow: hidden;
    font-family: 'Syne', sans-serif;
  }
  body::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    background: radial-gradient(ellipse at 50% 60%, rgba(0,255,179,0.06) 0%, transparent 60%);
    pointer-events: none;
  }
  .copy {
    position: absolute;
    top: 160px;
    left: 100px;
    z-index: 10;
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
  .phones-container {
    position: absolute;
    top: 820px;
    left: 50%;
    transform: translateX(-50%);
    width: 900px;
    height: 1400px;
    perspective: 3000px;
  }
  .light-streak {
    position: absolute;
    top: 200px;
    left: 50%;
    transform: translateX(-50%) rotate(-15deg);
    width: 600px;
    height: 1000px;
    background: linear-gradient(135deg, rgba(0,255,179,0.08) 0%, transparent 60%);
    pointer-events: none;
    z-index: 1;
  }
  .phone {
    width: 480px;
    height: 940px;
    border-radius: 76px;
    background: #1A1A1A;
    border: 2px solid rgba(255,255,255,0.12);
    overflow: hidden;
    position: absolute;
  }
  .phone img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  .phone-left {
    left: -30px;
    top: 0;
    transform: rotateY(-12deg) rotateX(5deg) rotateZ(3deg);
    filter: drop-shadow(-50px 70px 100px rgba(0,0,0,0.85))
            drop-shadow(-12px 20px 30px rgba(0,255,179,0.10));
    z-index: 3;
  }
  .phone-right {
    right: -30px;
    top: 200px;
    transform: rotateY(10deg) rotateX(6deg) rotateZ(-3deg);
    filter: drop-shadow(50px 70px 100px rgba(0,0,0,0.85))
            drop-shadow(12px 20px 30px rgba(0,255,179,0.08));
    z-index: 2;
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
    <div class="line1">トレーニング後の</div>
    <div class="line2">達成感をシェア。</div>
    <div class="sub">PR更新を自動検出 — 前回比較を一枚に</div>
  </div>
  <div class="phones-container">
    <div class="light-streak"></div>
    <div class="phone phone-left">
      <img src="data:image/png;base64,${imgData}" />
    </div>
    <div class="phone phone-right">
      <img src="data:image/png;base64,${imgData}" />
    </div>
  </div>
  <div class="bottom">
    <div class="brand">MUSCLEMAP</div>
    <div class="cta">毎回の成長を記録する</div>
  </div>
</body>
</html>
  `, { waitUntil: 'networkidle0', timeout: 30000 });

  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: path.join('/Users/og3939397/MuscleMap/scripts/screenshots', 'slide2.png'),
    type: 'png'
  });
  console.log('slide2.png saved');
  await browser.close();
})();
