# App Store Screenshot Generator Skill

> MuscleMap専用。CC（Claude Code）でプロ品質のApp Storeスクショを生成する。

## トリガー

以下のいずれかで発動:
- 「App Storeのスクショを作って」
- 「スクリーンショットを生成」
- 「ストア画像を更新」

## 前提条件

- Node.js 18+
- iOSシミュレーター起動済み（スクショキャプチャ時）
- MuscleMapプロジェクトのルートにいること

## ワークフロー概要

**4ステップに分割して実行する。一括でやるな。**

### Step 1: セットアップ
```bash
cd skills/app-store-screenshots/generator
npm install
```

### Step 2: シミュレーターからスクショをキャプチャ
```bash
# シミュレーターで対象画面を表示してから:
xcrun simctl io booted screenshot ./public/screenshots/shot1_screen.png
# 6.1インチシミュレーター推奨（スケーリングが最もクリーン）
```

### Step 3: コピーを確認・編集
`src/copy.ts` の各言語の見出し・サブコピーを確認。

### Step 4: 生成＆書き出し
```bash
npm run dev
# ブラウザで http://localhost:3000 を開く
# 各スクショをクリック → PNG書き出し（全4サイズ自動）
```

## 出力サイズ

| ディスプレイ | 解像度 |
|:---|:---|
| 6.9" (必須ベース) | 1320 x 2868 |
| 6.5" | 1284 x 2778 |
| 6.3" | 1206 x 2622 |
| 6.1" | 1125 x 2436 |

## デザイン原則

### 全体
- **スクショは「広告」であり「UIデモ」ではない。** 1スライド1メッセージ。
- サムネイルサイズ（検索結果）で読めるテキストサイズにする。
- 最初の3枚で「Value → Usage → Trust」のストーリーを語る。

### レイアウト構造
```
┌─────────────────────────┐
│                         │
│  見出し（2行以内）       │  ← 上部22%: コピーエリア
│  サブコピー（1行）       │
│  [チップ] [チップ]      │
│                         │
│   ┌───────────────┐     │
│   │               │     │
│   │  iPhone枠     │     │  ← 下部78%: デバイスエリア
│   │  + スクショ   │     │
│   │               │     │
│   │               │     │
│   └───────┘             │
│                         │
│  ▓▓▓ ボトムフェード ▓▓▓  │
└─────────────────────────┘
```

### 余白管理（最重要）
- **コピーエリア**: padding-top 120px, padding-x 80px
- **デバイスは下に突き抜ける**: 完全に画面内に収めない。下部がフェードアウトで切れるのが正解
- **iPhoneフレームの幅**: キャンバス幅の約71%（940/1320）
- **コピーとデバイス間**: 40px
- **デバイスフレームの角丸**: 68px（外側）、54px（スクリーン）
- **ボトムフェード**: 高さ400px、transparent → 背景色

### iPhoneモックアップ
- 外枠: チタン風グラデーション `linear-gradient(145deg, #3A3A3C, #1C1C1E, #2C2C2E)`
- パディング: 14px（枠とスクリーンの間）
- Dynamic Island: 幅160px、高さ38px、top 18px
- サイドボタン: 電源（右）、音量上下（左）
- ドロップシャドウ: `0 60px 120px rgba(0,0,0,0.8)` + アクセント色のグロー
- ガラスリフレクション: 上部200pxにrgba(255,255,255,0.03)のグラデーション

### MuscleMapブランド
- 背景: `#070A07`（ほぼ真っ黒、わずかに緑）
- プライマリアクセント: `#00FFB3`（グリーン）
- セカンダリアクセント: `#00D4FF`（ブルー）
- PRアクセント: `#FFD700`（ゴールド）
- テキスト: `#FFFFFF`
- 背景グロー: アクセント色の`0D`不透明度、radial-gradient
- 背景グリッド: rgba(255,255,255,0.02)の64pxグリッド

### タイポグラフィ
- 日本語: 'Noto Sans JP', weight 900（見出し）/ 500（サブ）
- 英語: 'Inter', weight 900 / 500
- 見出しサイズ: 日本語88px / 英語90px
- サブコピー: 32px
- letter-spacing: 日本語2px / 英語-1px

## ショット定義（v1.1）

| # | 見出し（JA） | アクセント | 画面 |
|:--|:---|:--|:---|
| 1 | 昨日の筋トレ、今どこに残ってる？ | #00FFB3 | ホーム（回復マップ） |
| 2 | 今日、ここを鍛えた | #00FFB3 | ワークアウト完了 |
| 3 | 今日やるべき種目、自動で | #00FFB3 | ホーム（Day切替タブ） |
| 4 | 92種目、全部動く | #00D4FF | 種目ライブラリ |
| 5 | 前回を超えろ | #FFD700 | PR祝福 |
| 6 | どこに効くか、数値で見る | #00D4FF | Strength Map |

## ファイル構造

```
skills/app-store-screenshots/
├── SKILL.md              ← このファイル
└── generator/
    ├── package.json
    ├── next.config.ts
    ├── tsconfig.json
    ├── tailwind.config.ts
    ├── public/
    │   ├── mockup.png    ← iPhoneフレーム（透明PNG）
    │   └── screenshots/  ← シミュレーターからキャプチャしたスクショ
    ├── src/
    │   ├── app/
    │   │   ├── layout.tsx
    │   │   ├── page.tsx      ← メイン生成コンポーネント
    │   │   └── globals.css
    │   └── copy.ts           ← 7言語コピー辞書
    └── output/               ← 書き出し先
```

## CC開発時の注意

- page.tsxは大きいファイルになる。一括で書こうとするとコンテキスト溢れでエラーになる。
- **必ずファイルごとに分割してpushすること。**
- mockup.pngは別途取得が必要（Figma CommunityかParthJadhavのリポジトリから）。

## 参考

- [ParthJadhav/app-store-screenshots](https://github.com/ParthJadhav/app-store-screenshots) — 3.1k stars、Next.js + html-to-imageベース
- Apple必須サイズ: 1320×2868px（6.9"）がベース
- 2026年トレンド: パノラミック背景、Value-Flow-Trustフレームワーク、サムネイル最適化
