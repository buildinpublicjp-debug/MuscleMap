---
name: app-store-screenshots
description: >
  App Storeのスクリーンショットを生成する。スクショ、ストア画像、App Store screenshots、
  ストアの画像を更新、スクショを作って、screenshot generate、marketing screenshots、
  ストア用の画像、ASO screenshots と言われたら必ずこのスキルを使え。
---

# App Store Screenshot Generator v4

> MuscleMap専用。プロ品質のApp Storeスクショを生成する。

---

## ⚠️ 絶対ルール

### 画像の扱い（フリーズ防止 — 最重要）
**スクショを読むときは必ず sips -Z 600 でリサイズしてから読め。**
```bash
xcrun simctl io $UDID screenshot /tmp/check.png
sips -Z 600 /tmp/check.png --out /tmp/check_small.png
```

### 触るなファイル
- MuscleMap本体のSwiftファイルすべて
- docs/DESIGN_SYSTEM.md, CLAUDE.md
- このタスクでは `skills/app-store-screenshots/` 配下と `/tmp/` のみ触る

---

## 出力仕様

### サイズ
**6.9インチ（1320×2868px）のみ出力。** App Store Connectが他サイズに自動スケールする。

### 対応言語
ja, en, zh, ko, es, de, fr（7言語）

---

## ショット定義（v4 — 2025/03/29確定）

ストーリーアーク: Hook → Overview → Benefit → Depth → Core Action → Insight
最初の3枚が最重要（90%のユーザーはスクロールしない）

| # | JA見出し | 画面 | アクセント |
|:--|:---|:--|:--|
| 1 | 筋肉が、見える。 | Recovery Map | #00E676 |
| 2 | 全部、ここに。 | Home Dashboard | #00E676 |
| 3 | 迷わない。 | Auto Plan (闘う体の準備完了) | #00E676 |
| 4 | 92種目。全部動く。 | Exercise Library (種目詳細) | #00D4FF |
| 5 | 記録する。あとは自動。 | Workout Recording + PR | #FFD700 |
| 6 | 1部位ずつ、深く知る。 | Recovery Detail (ハムストリングス等) | #00D4FF |

---

## 使い方（手動フロー）

### Step 1: 起動
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator
npm install
npm run dev
```

### Step 2: Chromeで開く
⚠ **Safari不可。Chromeで http://localhost:3000 を開く。**
html-to-imageはSafari非対応（foreignObject制限）。

### Step 3: スクショをドラッグ＆ドロップ
各ショットのカードにシミュレーターのスクショをドロップ。

### Step 4: 言語切替 & 確認
ツールバーの言語ボタンでコピーを切替。UIスクショは手動で差し替え。

### Step 5: エクスポート
「Export All」ボタンで6枚のPNG（1320×2868）がダウンロードされる。

---

## 技術詳細

### iPhoneフレーム
CSS only（外部PNG不要）:
- チタングラデ: 8段階 linear-gradient
- Dynamic Island: 190×40px pill + フロントカメラ + 近接センサー
- ボタン: Action, Vol Up, Vol Down, Power（実機比率）
- ガラス効果: 斜めシーン + 上部ハイライト
- ドロップシャドウ: 5層

### エクスポート（既知バグ対策）

**問題:** `html-to-image` が `<img>` のdata URLをクローン時にデコードできない
**解決:** `<img>` ではなく CSS `background-image` で画像を表示
- background-image はstyle属性としてクローンにコピーされる
- 別途ロード不要 → 確実にキャプチャされる
- 追加安全策として toPng() を2回呼ぶ（1回目は捨てる）

### コピーエリア
- 40px〜428px（388px高）のflexboxでvertical center
- 1行・2行ヘッドライン両方が同じ高さで揃う
- JA: fontSize 100px, letterSpacing 8px
- EN: fontSize 104px, letterSpacing -3px

---

## ファイル構成

```
skills/app-store-screenshots/generator/
├── src/
│   ├── app/
│   │   ├── page.tsx    # レイアウト、フレーム、エクスポート
│   │   ├── layout.tsx
│   │   └── globals.css
│   └── copy.ts         # 6ショット×7言語のコピー
├── public/
├── package.json
└── README.md
```

---

## 既知の制約

- Safari非対応（html-to-image README に明記: "Safari is not supported"）
- エクスポートPNGのフォントはブラウザにインストール済みのものに依存
- App Store Connectのスクショは審査中は編集不可。新バージョン提出が必要。
