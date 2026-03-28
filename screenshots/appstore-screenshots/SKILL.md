# App Store Screenshot Generator Skill

> MuscleMap専用。CCに読ませてスクショを自動生成する。

---

## 概要

Next.js + html-to-image ベースで、App Store用スクリーンショットをプログラム的に生成する。
iPhone 16 Pro Maxの実物モックアップPNG（透明背景）にシミュレーターのスクショをはめ込み、
コピーテキスト+背景デザインと合成して、全Apple必須サイズでPNG書き出しする。

## トリガー

以下のいずれかでこのスキルを使う：
- 「App Storeのスクショを作って」
- 「ストアのスクリーンショットを更新して」
- 「マーケティング用のスクショを生成して」

## ワークフロー

### Step 1: スクショ素材の準備
```bash
# シミュレーターで各画面を表示してキャプチャ
xcrun simctl io booted screenshot /tmp/shot_raw.png
# 必要に応じてリサイズ（確認用のみ。素材は元サイズを使う）
sips -Z 800 /tmp/shot_raw.png --out /tmp/shot_check.png
```

キャプチャした素材を `screenshots/appstore-screenshots/public/screenshots/` に配置。

### Step 2: コピーの確認
`src/app/copy.ts` にスライドごとのコピー（見出し・サブコピー・チップ）が定義されている。
7言語対応済み（ja, en, de, fr, es, pt, ko）。変更があれば編集。

### Step 3: 生成
```bash
cd screenshots/appstore-screenshots
npm install
npm run dev
# ブラウザで http://localhost:3000 を開く
# 各スクショをクリック → PNG自動ダウンロード
```

### Step 4: 書き出しサイズ
| ディスプレイ | 解像度 |
|:---|:---|
| 6.9" (必須ベース) | 1320 × 2868 |
| 6.7" | 1290 × 2796 |
| 6.5" | 1284 × 2778 |
| 6.1" | 1179 × 2556 |

デザインは1320×2868で作成し、他サイズはスケールダウンで書き出し。

---

## デザイン原則（絶対ルール）

### 1. スクショは「広告」であり「UIデモ」ではない
各スライドは1つのメッセージだけを伝える。機能羅列禁止。

### 2. 最初の3枚で勝負が決まる
90%のユーザーは3枚目以降スクロールしない。
構造: **Value（価値）→ Usage（使い方）→ Trust（信頼）**

### 3. サムネイルで読めるテキスト
App Store検索結果ではスクショは小さく表示される。
- 見出し: 最大2行、太字、大きく
- サブコピー: 1行、控えめ
- テキストが読めないなら大きくする

### 4. デバイスフレームは必須
iPhone 16 Pro Maxの実物モックアップPNG（透明背景）を使用。
ユーザーが「自分の手の中にあるアプリ」を想像できるように。

### 5. 余白管理は命
- コピーエリア: 全体の20-25%（上部）
- デバイスエリア: 全体の75-80%（下部、画面下端に突き出してOK）
- コピーとデバイスの間: 最小限（密着感）
- 左右マージン: 均等、デバイスが中央
- **デバイスが画面の60%以下 → デカくしろ**
- **コピーエリアが30%以上 → テキストがデカすぎるか余白が多すぎ**

### 6. 統一感のある背景
- ベース: #070A07（ほぼ黒）
- アクセントグロー: 上部にradial-gradient（アクセント色の微光）
- グリッドパターン: 極薄の線（0.02 opacity）
- 下部フェード: デバイスが背景に溶け込むgradient

---

## MuscleMap固有の設定

### カラーパレット
- Background: #070A07
- Primary Accent: #00FFB3（グリーン）
- Secondary Accent: #00D4FF（ブルー）
- PR/Achievement: #FFD700（ゴールド）
- Text Primary: #FFFFFF
- Text Secondary: rgba(255, 255, 255, 0.6)

### スライド構成（6枚）
1. **回復マップ** — 「昨日の筋トレ、今どこに残ってる？」 accent: green
2. **種目GIF** — 「見て覚える、92種目」 accent: blue
3. **ルーティン自動生成** — 「今日やるべき種目、自動で」 accent: green
4. **PR祝福** — 「自己ベスト、見逃さない」 accent: gold
5. **Strength Map** — 「どこに効くか、数値で見る」 accent: blue
6. **完了体験** — 「今日、ここを鍛えた」 accent: green

### フォント
- 日本語: Noto Sans JP (900 for headline, 500 for body)
- 英語: Inter (900 for headline, 500 for body)

---

## ファイル構成

```
screenshots/appstore-screenshots/
├── SKILL.md                    # このファイル
├── package.json
├── next.config.js
├── tsconfig.json
├── tailwind.config.ts
├── public/
│   ├── mockup.png             # iPhone 16 Pro Max フレーム（透明）
│   └── screenshots/           # シミュレーターからのスクショ素材
│       ├── shot1_screen.png
│       ├── shot2_screen.png
│       └── ...
└── src/app/
    ├── layout.tsx
    ├── copy.ts                # 7言語コピー辞書
    └── page.tsx               # メイン生成コンポーネント
```

---

## CCへの指示テンプレート

```
screenshots/appstore-screenshots/SKILL.md を読んでから作業開始。

タスク: MuscleMapのApp Storeスクリーンショットを生成。
1. シミュレーターで以下の画面をキャプチャ:
   - ホーム画面（回復マップ前面）
   - 種目ライブラリ（GIFグリッド表示）
   - [他の画面...]
2. public/screenshots/ に配置
3. npm run dev でサーバー起動
4. ブラウザで確認、必要に応じてcopy.tsのテキスト調整
5. 全スライドをPNG書き出し
```

---

## 注意事項

- mockup.pngは高解像度の透明PNG。商用利用可能なものを使うこと。
- スクショ素材はシミュレーターの6.1"（1179×2556）で撮影するのが最も安全（スケールアップで品質劣化しにくい）。
- html-to-imageの書き出しは重い。1枚ずつクリックで書き出す設計。
- フォントはGoogle Fontsからロードするため、初回表示時に読み込み待ちが必要。

*作成: 2026-03-28*
