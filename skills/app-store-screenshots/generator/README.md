# MuscleMap App Store Screenshot Generator

## Quick Start

```bash
cd skills/app-store-screenshots/generator
npm install
npm run dev
```

⚠ **Chrome で開くこと** → http://localhost:3000
Safariではエクスポートに問題が出る（html-to-imageがSafari非対応）。

## How to use

1. ブラウザで localhost:3000 を開く
2. 各ショットにシミュレーターのスクショをドラッグ＆ドロップ
3. 言語を切り替えてプレビュー確認（JA/EN/ZH/KO/ES/DE/FR）
4. 「Export All」→ 9枚の1242×2688 PNGがダウンロードされる
5. App Store Connect にアップロード

## Shot順序

| # | ヘッドライン | 画面 | アクセント |
|---|---|---|---|
| 1 | 今日の狙いが一目でわかる。 | Recovery Map | #00C77B |
| 2 | 記録は一瞬。回復まで自動。 | Workout Logging | #00B86B |
| 3 | 開けばすぐ、やることが決まる。 | Home Dashboard | #00C77B |
| 4 | 迷わず選んで、すぐ開始。 | Recommended Menu | #00AEEF |
| 5 | 92種目。フォームも確認。 | Exercise Library | #00AEEF |
| 6 | 部位ごとの変化を深く追える。 | Muscle Detail | #00B86B |
| 7 | 迷ったフォームは、すぐ動画。 | YouTube Form | #00AEEF |
| 8 | 成果を一枚で、きれいに共有。 | Share Card | #00C77B |
| 9 | 鍛えた部位が、ひと目で残る。 | Body Conquest | #00B86B |

## 技術メモ

- iPhoneフレーム: CSS only（チタングラデ + Dynamic Island + ボタン4個）
- エクスポート: `html-to-image` の `toPng()` を2回呼ぶ（既知バグ対策）
- 画像表示: `<img>` ではなく CSS `background-image` を使用（クローン時のデコード問題回避）
- 出力サイズ: 1242×2688px（6.5" alt）

## ファイル構成

- `src/copy.ts` — 9ショット×7言語のコピーテキスト
- `src/app/page.tsx` — レイアウト、フレーム、エクスポートロジック
- `src/app/globals.css` — 基本スタイル

## 既知の制約

- Safari非対応（html-to-imageの制限）
- エクスポートPNGのフォントはブラウザにインストール済みのフォントに依存
- Noto Sans JP が必要（macOSのヒラギノでもフォールバックする）
