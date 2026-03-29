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
4. 「Export All」→ 6枚の1320×2868 PNGがダウンロードされる
5. App Store Connect にアップロード

## Shot順序（v4）

| # | ヘッドライン | 画面 | アクセント |
|---|---|---|---|
| 1 | 筋肉が、見える。 | Recovery Map | #00E676 |
| 2 | 全部、ここに。 | Home Dashboard | #00E676 |
| 3 | 迷わない。 | Auto Plan | #00E676 |
| 4 | 92種目。全部動く。 | Exercise Library | #00D4FF |
| 5 | 記録する。あとは自動。 | Workout + PR | #FFD700 |
| 6 | 1部位ずつ、深く知る。 | Muscle Detail | #00D4FF |

## 技術メモ

- iPhoneフレーム: CSS only（チタングラデ + Dynamic Island + ボタン4個）
- エクスポート: `html-to-image` の `toPng()` を2回呼ぶ（既知バグ対策）
- 画像表示: `<img>` ではなく CSS `background-image` を使用（クローン時のデコード問題回避）
- 出力サイズ: 1320×2868px（6.9"のみ。他は App Store Connect が自動スケール）

## ファイル構成

- `src/copy.ts` — 6ショット×7言語のコピーテキスト
- `src/app/page.tsx` — レイアウト、フレーム、エクスポートロジック
- `src/app/globals.css` — 基本スタイル

## 既知の制約

- Safari非対応（html-to-imageの制限）
- エクスポートPNGのフォントはブラウザにインストール済みのフォントに依存
- Noto Sans JP が必要（macOSのヒラギノでもフォールバックする）
