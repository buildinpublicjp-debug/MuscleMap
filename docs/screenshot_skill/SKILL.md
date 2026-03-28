# MuscleMap App Store Screenshot Skill v1.0

> CC（Claude Code）に読ませて「スクショ作って」で起動するスキル。
> 高品質なApp Storeスクリーンショットをプログラマティックに生成する。

---

## トリガー

以下のいずれかで起動:
- 「App Storeのスクショを作って」
- 「スクリーンショットを更新して」
- 「ストア画像をリデザインして」

---

## 設計思想

### スクショは「広告」であり「UIデモ」ではない
- 1スライド = 1メッセージ（機能の羅列NG）
- ユーザーの「問題 → 解決 → 信頼」のストーリーで構成
- サムネイルサイズ（App Store検索結果）で読めるテキストサイズ

### 最初の3枚が全て
- 90%のユーザーは3枚目以降見ない
- 1枚目: Value（価値提案）
- 2枚目: Usage（使い方・差別化）
- 3枚目: Trust（信頼・実績）

### 余白管理の原則
- **死んだ余白は許さない**（DESIGN_SYSTEM.mdと同じ哲学）
- コピーエリアとデバイスエリアの比率: **25:75**（コピーは上部1/4、デバイスは下部3/4）
- デバイスは画面下端を突き抜ける（途切れるのが正解 — 没入感を出す）
- 背景は単色ではなく、微細なグラデーション+グリッド/ノイズで奥行きを出す
- コピーテキスト周りのパディング: 上80px, 左右80px（1320px基準）

### iPhoneモックアップ
- **実物のiPhone 16 Pro Maxフレーム画像（PNG, 透明背景）を使う**
- CSSで描画したフレームは使わない（安っぽくなる）
- フレームのスクリーン領域に実際のスクショをはめ込む
- フレームはチタン色（#1C1C1E〜#3A3A3C）で、ダークUIと調和する

---

## 技術スタック

```
Next.js 14+        — ローカルdevサーバーでレンダリング
TypeScript          — 型安全
Tailwind CSS        — スタイリング
html-to-image       — DOM → PNG書き出し（正確なピクセルサイズ）
React               — コンポーネント構成
```

---

## ディレクトリ構成

```
MuscleMap/
├── screenshots/
│   ├── skill/                    ← このスキルのコード
│   │   ├── package.json
│   │   ├── next.config.ts
│   │   ├── tailwind.config.ts
│   │   ├── tsconfig.json
│   │   ├── src/
│   │   │   └── app/
│   │   │       ├── layout.tsx    ← フォント設定
│   │   │       └── page.tsx      ← メインジェネレーター（単一ファイル）
│   │   └── public/
│   │       ├── mockup.png        ← iPhone 16 Pro Maxフレーム（透明PNG）
│   │       └── screens/          ← シミュレーターから撮ったスクショ
│   │           ├── en/
│   │           │   ├── home.png
│   │           │   ├── workout.png
│   │           │   └── ...
│   │           └── ja/
│   │               ├── home.png
│   │               └── ...
│   └── output/                   ← 書き出し先
│       ├── ja/
│       │   ├── shot1_6.9.png
│       │   ├── shot1_6.5.png
│       │   └── ...
│       └── en/
│           └── ...
```

---

## ワークフロー（4ステップ）

### Step 1: スクリーンキャプチャ
シミュレーターで各画面を表示し、スクショを撮る。

```bash
# 6.1インチシミュレーターを使う（ParthJadhav推奨 — リサイズ不要）
xcrun simctl io booted screenshot /tmp/shot_home.png
# screens/ にコピー
cp /tmp/shot_home.png screenshots/skill/public/screens/ja/home.png
```

**撮るべき画面（6枚構成）:**
1. ホーム画面（回復マップ前面、色が付いた状態）
2. 種目ライブラリ（2列グリッド、GIFカード）
3. セット入力（重量入力が大きく表示）
4. ワークアウト完了（PRゴールド祝福）
5. プログレスフォト（Before/After比較）
6. Strength Map（筋肉の太さ表示）

### Step 2: コピー作成
`COPY_DICT`（後述）を確認・調整。各スライドに:
- **ヘッドライン**: 最大2行、15文字/行以内（日本語）、5語/行以内（英語）
- **サブコピー**: 1行、補足説明
- **チップ**: 2-4個の数値/キーワードバッジ

### Step 3: レンダリング
```bash
cd screenshots/skill
npm install
npm run dev
# ブラウザで http://localhost:3000 を開く
# 各スクショをクリック → PNG書き出し
```

### Step 4: 書き出し＆アップロード
- 4サイズ自動生成: 6.9"(1320×2868), 6.5"(1284×2778), 6.3"(1206×2622), 6.1"(1125×2436)
- `screenshots/output/{lang}/` に保存
- App Store Connectにアップロード

---

## コピー辞書（COPY_DICT）

```typescript
const COPY_DICT = {
  shot1: {
    ja: {
      headline: "昨日の筋トレ、\n今どこに残ってる？",
      sub: "21部位の回復をリアルタイム表示",
      chips: ["21部位", "92種目", "EMGベース"],
      accent: "#00FFB3",  // MuscleMapグリーン
    },
    en: {
      headline: "Your muscles\nremember yesterday.",
      sub: "Real-time recovery map for 21 muscle groups",
      chips: ["21 muscles", "92 exercises", "EMG-based"],
      accent: "#00FFB3",
    },
  },
  shot2: {
    ja: {
      headline: "動きで覚える、\n92種目のGIF",
      sub: "種目名だけじゃわからない動作を一目で",
      chips: ["92種目", "GIF対応", "2列グリッド"],
      accent: "#00D4FF",  // アクセントブルー
    },
    en: {
      headline: "See the motion,\nnot just the name.",
      sub: "Animated GIFs for all 92 exercises",
      chips: ["92 exercises", "GIF-powered", "Grid view"],
      accent: "#00D4FF",
    },
  },
  shot3: {
    ja: {
      headline: "今日やるべき種目、\n自動で提案",
      sub: "目標×頻度×場所→あなた専用Day分割",
      chips: ["目標", "頻度", "場所", "経験値"],
      accent: "#00FFB3",
    },
    en: {
      headline: "Never wonder\nwhat to train.",
      sub: "Goals × frequency × location → your split",
      chips: ["Goals", "Frequency", "Location"],
      accent: "#00FFB3",
    },
  },
  shot4: {
    ja: {
      headline: "自己ベスト更新を\nリアルタイムで祝福",
      sub: "PR検出 → ゴールド演出 → シェア",
      chips: ["NEW PR!", "自動検出"],
      accent: "#FFD700",  // PRゴールド
    },
    en: {
      headline: "Every PR\ndeserves a crown.",
      sub: "Auto-detect personal records & celebrate",
      chips: ["NEW PR!", "Auto-detect"],
      accent: "#FFD700",
    },
  },
  shot5: {
    ja: {
      headline: "変化を写真で\n記録する",
      sub: "Before/Afterスライダーで比較",
      chips: ["カメラ撮影", "比較スライダー"],
      accent: "#00FFB3",
    },
    en: {
      headline: "See your\ntransformation.",
      sub: "Before/After slider comparison",
      chips: ["Camera", "Compare"],
      accent: "#00FFB3",
    },
  },
  shot6: {
    ja: {
      headline: "全身の強さを\n数値で可視化",
      sub: "S〜Dグレードで弱点が一目でわかる",
      chips: ["S", "A", "B", "C", "D"],
      accent: "#00D4FF",
    },
    en: {
      headline: "See your strength\nin full color.",
      sub: "S-to-D grading across your entire body",
      chips: ["S", "A", "B", "C", "D"],
      accent: "#00D4FF",
    },
  },
};
```

---

## テーマ設定

```typescript
const THEME = {
  bg: "#070A07",           // 背景（ほぼ黒、微妙に緑みを帯びる）
  bgCard: "#111411",       // カード背景
  text: "#FFFFFF",         // メインテキスト
  textSecondary: "#A0A0A0", // サブテキスト
  brand: "#00FFB3",        // MuscleMapプライマリ
  gold: "#FFD700",         // PRゴールド
  blue: "#00D4FF",         // アクセントブルー
  fontJa: "'Noto Sans JP', 'Hiragino Sans', sans-serif",
  fontEn: "'Inter', 'SF Pro Display', sans-serif",
};
```

---

## レイアウト仕様（1320×2868px基準）

### 全体構成
```
┌─────────────────────────────┐
│     コピーエリア (25%)         │  ← 717px
│  ┌───────────────────────┐  │
│  │ ヘッドライン（72-88px）  │  │
│  │ サブコピー（28-32px）   │  │
│  │ チップ行               │  │
│  └───────────────────────┘  │
│                             │
│     デバイスエリア (75%)       │  ← 2151px
│  ┌───────────────────────┐  │
│  │                       │  │
│  │   iPhone mockup.png   │  │
│  │   + スクショはめ込み    │  │
│  │                       │  │
│  │   ── 下端突き抜け ──    │  │
└──┴───────────────────────┴──┘
```

### タイポグラフィ
| 要素 | 日本語 | 英語 |
|:---|:---|:---|
| ヘッドライン | 80-88px, weight 900 | 84-92px, weight 900 |
| サブコピー | 28-32px, weight 500 | 28-32px, weight 500 |
| チップ | 20-24px, weight 600 | 20-24px, weight 600 |

### iPhone モックアップ配置
- フレーム幅: キャンバス幅の **72%**（≒ 950px）
- フレーム上端: コピーエリア下端から **40px** 下
- フレーム下端: キャンバス下端を **突き抜ける**（80-150px程度はみ出す）
- 水平位置: 中央揃え
- **スクリーン領域**: mockup.pngのスクリーン部分（透明領域）に正確にスクショを配置

### 背景レイヤー（奥から順）
1. ベースカラー `#070A07`
2. グローエフェクト: 上部中央に放射状グラデーション（アクセント色, opacity 5-8%）
3. グリッドパターン: 64×64pxの微細グリッド線（白, opacity 2%）
4. ボトムフェード: 下端400pxに背景色へのグラデーション（デバイスの突き抜け部分をフェードアウト）

---

## 書き出しサイズ

| ディスプレイ | 解像度 |
|:---|:---|
| 6.9" (iPhone 16 Pro Max) | 1320 × 2868 |
| 6.5" (iPhone 15 Plus等) | 1284 × 2778 |
| 6.3" | 1206 × 2622 |
| 6.1" | 1125 × 2436 |

デザインは1320×2868で作成し、他サイズはスケールダウンで生成。

---

## モックアップ画像の準備

### mockup.pngの要件
- iPhone 16 Pro Max の正面フレーム画像
- **透明背景**（PNG, RGBA）
- スクリーン部分も透明（スクショをz-indexで背面に配置する）
- 推奨解像度: 幅950-1000px程度（キャンバス内での表示サイズ）
- チタンフレーム色: ダーク系（MuscleMapのダークUIに合わせる）

### 取得方法（優先順）
1. **ParthJadhav/app-store-screenshots のmockup.png** を利用（MIT License）
2. Figma Community から iPhone 16 Pro mockup を書き出し
3. webmobilefirst.com から無料DL（個人利用OK）

---

## CCプロンプトテンプレート

CCに以下を渡して実行:

```
## タスク
MuscleMapのApp Storeスクリーンショットを生成する。

## 手順
1. `docs/screenshot_skill/SKILL.md` を読め
2. `screenshots/skill/` ディレクトリ構成を確認
3. シミュレーターでアプリを起動し、以下の画面をキャプチャ:
   - ホーム画面（回復マップ前面）
   - 種目ライブラリ（2列グリッド）
   - セット入力画面
   - ワークアウト完了画面（PR祝福）
   - プログレスフォトギャラリー
   - Strength Map
4. キャプチャした画像を `screenshots/skill/public/screens/{lang}/` に配置
5. `npm run dev` でローカルサーバーを起動
6. ブラウザで確認し、クリックしてPNG書き出し
7. `screenshots/output/` に全サイズを保存

## ⚠️ 画像の扱いルール（フリーズ防止）
シミュレーターのスクショは 1290×2796px あり、そのままAPIに送るとフリーズする。
確認用は必ず sips -Z 800 でリサイズしてから読め。
```

---

## セルフレビューチェックリスト

書き出し後、App Store Connectにアップロードする前に確認:

```
□ サムネイルサイズ（小さく表示）でヘッドラインが読めるか
□ 最初の3枚だけで「何のアプリか」「なぜ使うべきか」が伝わるか
□ デバイスフレームがプロフェッショナルに見えるか（CSS描画ではなく実画像か）
□ 背景に死んだ余白がないか
□ テキストがデバイスフレームと被っていないか
□ 全6枚で色調・スタイルが統一されているか
□ 日本語/英語の両方で不自然な改行がないか
□ 6.9"サイズで1320×2868pxであるか
□ PNG形式、RGB、アルファチャンネルなしであるか
```

---

## 既知の課題・TODO

- [ ] mockup.png の高品質版を取得して配置
- [ ] page.tsx のメインジェネレーターコードを作成
- [ ] package.json / next.config / tailwind.config を作成
- [ ] 7言語対応（現状 ja/en のみ。追加: zh, ko, fr, de, es）
- [ ] パノラミック連続背景の実験
- [ ] App Store Connect APIでの自動アップロード検討

---

*作成: 2026-03-28*
*参考: ParthJadhav/app-store-screenshots (MIT, 3.1k stars)*
