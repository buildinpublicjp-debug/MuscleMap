# MuscleMap Design System v1.0

> このファイルはCLAUDE.mdの補助ドキュメント。全てのUI実装・修正時に必ず参照すること。
> 具体的なピクセル値・比率・パターンを定義。曖昧な「いい感じに」は禁止。

---

## 1. GIFカードの統一ルール（最重要）

GIFはMuscleMapの最大差別化要素。全画面で統一された見せ方をすること。

### GIFカードの2パターン

**A. グリッドカード（種目辞典・ピッカーのグリッド表示）**
```
幅: 画面幅の47%（2列グリッド、gap: 12pt）
GIF高さ: カード幅の75%（アスペクト比 4:3）
角丸: 12pt
背景: .mmBgCard (#2A2A2A)
GIF部分: 角丸の上側のみ（.clipShape(UnevenRoundedRectangle)）
テキスト部分: GIFの下、パディング 8pt
  - 種目名: .caption.bold(), .mmTextPrimary, .lineLimit(1)
  - 筋肉バッジ: .caption2, アクセントカラー背景ピル
  - 器具: .caption2, .mmTextSecondary
お気に入り: 右上にハートアイコン（24pt）
```

**B. コンパクトカード（ホームのTodayActionCard・ワークアウトの最近使った種目）**
```
幅: 110pt（横スクロール、showsIndicators: false）
GIF高さ: 80pt
角丸: 10pt
背景: .mmBgCard (#2A2A2A)
テキスト部分: パディング 6pt
  - 種目名: .system(size: 10, weight: .semibold), .lineLimit(1)
  - セット×レップ: .system(size: 9), .mmTextSecondary
スクロール: 最後のカードが画面端で途切れてスクロール示唆
```

### GIFの表示ルール
- GIFの背景は白。ダークUIで浮かないよう、GIFカード全体を.mmBgCard背景で包む
- GIFコンテナ自体にborderは付けない（カード全体の角丸で処理）
- GIFのロード中: .mmBgCard背景 + 中央にスピナー（ProgressView）
- GIF未対応の種目: ダンベルアイコン（SF Symbol: "dumbbell.fill"）を.mmTextSecondary色で中央配置

---

## 2. 筋肉マップの表示サイズガイド

マップは画面の目的によってサイズを変える。

| 画面 | マップ高さ | 用途 |
|:---|:---|:---|
| ワークアウトタブ（待機中） | 280pt | 筋肉タップで種目フィルター |
| ホーム RecoveryStatusSection | 160pt | 回復状態の確認（コンパクト） |
| ワークアウト完了 StimulatedMusclesSection | 200pt | 刺激した部位のハイライト |
| 履歴 ワークアウト詳細シート | 160pt | その日に鍛えた部位 |
| カレンダー ミニアイコン | 28pt | 日ごとの部位サマリー |
| シェアカード | 140pt | SNS共有用 |

### マップ周りの余白
- マップの上下: 各 8pt
- マップとテキストセクション間: 12pt
- 前面・背面の間隔: 16pt（HStack spacing）

---

## 3. カードのデザインパターン

### 情報カード（StatsRow等）
```swift
背景: .mmBgSecondary (#1E1E1E)
角丸: 12pt
パディング: 12pt
数値: .system(size: 22, weight: .heavy), .mmTextPrimary
ラベル: .caption, .mmTextSecondary
テキスト配置: center
```

### アクションカード（TodayActionCard等）
```swift
背景: LinearGradient(
    colors: [Color(red: 0.05, green: 0.16, blue: 0.09), .mmBgSecondary],
    startPoint: .topLeading, endPoint: .bottomTrailing
)
ボーダー: .mmAccentPrimary.opacity(0.15), 1pt
角丸: 16pt
パディング: 16pt
```

### ステータスチップ（回復ステータス等）
```swift
背景: ステータス色.opacity(0.12)
角丸: 10pt
パディング: 8pt horizontal, 10pt vertical
部位名: .system(size: 12, weight: .bold), ステータス色
詳細: .system(size: 10), ステータス色.opacity(0.6)
```

### ショートカットカード（QuickAccessRow等）
```swift
背景: .mmBgSecondary (#1E1E1E)
角丸: 12pt
パディング: 12pt
タイトル: .system(size: 14, weight: .bold), .mmTextPrimary
サブ: .system(size: 11), .mmTextSecondary
アイコン: 20pt, SF Symbol
```

---

## 4. CTAボタンのデザイン

### プライマリCTA（「ワークアウトを開始」「種目を追加して始める」等）
```swift
高さ: 52pt
角丸: 14pt
背景: .mmAccentPrimary (#00FFB3)
テキスト: .system(size: 17, weight: .heavy), Color.black
フルwidth（パディング horizontal: 16pt で制御）
```

### セカンダリCTA（「トレーニングをシェア」「体の記録を撮る」等）
```swift
高さ: 48pt
角丸: 12pt
背景: .mmBgSecondary (#1E1E1E)
ボーダー: .mmAccentPrimary.opacity(0.2), 1pt（シェア系のみ）
テキスト: .system(size: 15, weight: .bold), .mmTextPrimary
```

### テキストボタン（「詳細 →」「閉じる」等）
```swift
テキスト: .caption or .body, .mmAccentSecondary or .mmTextSecondary
パディング: 8pt
```

---

## 5. セット入力画面のルール

### 重量表示
```swift
数値: .system(size: 56, weight: .heavy, design: .rounded), .mmTextPrimary
単位(kg): .system(size: 16), .mmTextSecondary
+/-ボタン: 48pt四角, .mmBgCard背景, SF Symbol "minus"/"plus"
```

### クイック重量ボタン
```swift
高さ: 36pt
角丸: 18pt（ピル型）
背景（非選択）: .mmBgCard
背景（選択）: .mmAccentPrimary.opacity(0.2)
テキスト: .system(size: 14, weight: .semibold)
ボーダー（選択）: .mmAccentPrimary, 1pt
最大3個、HStack(spacing: 8)
```

### レップピル
```swift
高さ: 32pt
幅: 44pt
角丸: 16pt（ピル型）
背景（非選択）: .mmBgCard
背景（選択）: .mmAccentPrimary
テキスト色（選択）: Color.black
テキスト: .system(size: 14, weight: .bold)
HStack(spacing: 6), 表示する値: [5, 8, 10, 12, 15]
```

### 前回の記録参照
```swift
ヘッダー: "前回の記録" .caption.bold(), .mmTextSecondary
各セット: "セット1: 80.0kg × 10" .caption, .mmTextSecondary.opacity(0.6)
背景: なし（セパレータ line 0.5pt .mmBgCard で区切り）
位置: 入力エリアの上
```

### セット記録ボタン
```swift
高さ: 52pt
角丸: 14pt
背景: .mmAccentPrimary
テキスト: .system(size: 17, weight: .heavy), Color.black
タップ時: scale(0.95) → 1.0 spring animation + haptic medium
```

---

## 6. ワークアウト完了画面のルール

### ヒーローセクション
```swift
チェックマーク: 80pt, .mmAccentPrimary, spring scale animation
タイトル "ワークアウト完了！": .title.bold(), .mmTextPrimary
サブテキスト（モチベーション）: .body, .mmTextSecondary
```

### ボリューム表示
```swift
数値: .system(size: 48, weight: .heavy), .mmAccentPrimary
単位 "kg": .system(size: 18), .mmTextSecondary
フォーマット: カンマ区切り（NumberFormatter.decimal）
```

### スタッツカード（種目数 / セット数 / 時間）
```swift
HStack(spacing: 8), 各カード均等幅
背景: .mmBgCard
角丸: 12pt
数値: .system(size: 24, weight: .heavy)
ラベル: .caption, .mmTextSecondary
アイコン: 16pt, .mmAccentPrimary
```

### PR祝福セクション
```swift
ヘッダー背景: LinearGradient(colors: [#FFD700, #FFA500])
角丸: 12pt
テキスト "NEW PR!": .system(size: 14, weight: .heavy), Color.black
各PRアイテム:
  種目名: .body.bold(), .mmTextPrimary
  "前回 → 今回": .caption, .mmTextSecondary
  増加率バッジ: 背景 .green.opacity(0.15), テキスト .green, 角丸 8pt
```

---

## 7. ペイウォールのルール

### ヘッダー
```swift
タイトル: .title2.bold(), .mmTextPrimary
サブタイトル: .body, .mmAccentPrimary
目標テキスト: .caption, .mmTextSecondary
目標の表示: "あなたの目標に最適化" — オンボーディング目標をそのまま表示するのはNG
```

### GIFカルーセル
```swift
1段のみ（2段にしない — 情報過多になる）
カード幅: 160pt
GIF高さ: 120pt
角丸: 12pt
横スクロール、showsIndicators: false
```

### 比較テーブル
```swift
背景: .mmBgCard
角丸: 16pt
パディング: 16pt
ヘッダー行: "機能" / "無料" / "Pro"
Pro列: .mmAccentPrimary色
チェック: SF Symbol "checkmark" .mmAccentPrimary
クロス: SF Symbol "xmark" .mmTextSecondary.opacity(0.3)
制限値: .mmWarning色 ("週2回" 等)
```

### 価格ボタン
```swift
プライマリ（月額）:
  高さ: 56pt, 角丸: 16pt
  背景: .mmAccentPrimary
  テキスト: .system(size: 18, weight: .heavy), Color.black

セカンダリ（年額）:
  高さ: 52pt, 角丸: 16pt
  背景: .mmBgCard
  ボーダー: .mmAccentPrimary.opacity(0.3), 1pt
  テキスト: .system(size: 16, weight: .bold), .mmTextPrimary
  割引バッジ: 背景 .mmAccentPrimary, テキスト Color.black, 角丸 8pt
```

---

## 8. 情報密度のルール

### 画面の情報量制限
- ファーストビュー（スクロールなしで見える範囲）に**最大3つのセクション**
- 各セクションのコントラスト: 背景色を変える or 明確なセパレータを入れる
- テキストだけのセクションは禁止。必ずビジュアル要素（マップ、GIF、アイコン、バッジ）を含める

### 余白のルール
- セクション間: 12pt（コンパクト）or 16pt（標準）
- カード内パディング: 12-16pt
- 画面端からのパディング: 16pt（.padding(.horizontal)）
- **余白が目立つ場合**: コンテンツを大きくするか、セクションを追加する。余白で埋めない

### テキストの切れ対策
- 種目名は必ず .lineLimit(1) + テキストが長い場合は括弧以降を省略
- 種目名の表示優先: メイン名称 > 括弧内の補足
- 例: "バーベルベンチプレス" ○ / "バーベルベンチプレス（インクライン）" → "バーベルベンチプレス（イン…" ×
  → 代わりに "インクラインベンチプレス" と表示名自体を短くする

---

## 9. アニメーションのルール

### 許可するアニメーション
```swift
// 画面遷移
.transition(.opacity.combined(with: .scale(scale: 0.95)))

// ボタンタップ
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

// カードの出現（リストアイテム）
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .opacity
))

// 数値変化
.contentTransition(.numericText())

// PR祝福のconfetti
// 30粒、2秒、ランダムカラー（mmAccentPrimary, mmPRGold, mmAccentSecondary）
```

### 禁止するアニメーション
- 3秒以上のアニメーション（confetti除く）
- 常時ループするアニメーション（ユーザーの注意を散らす）
- バウンスが3回以上のspring
- 回転アニメーション

---

## 10. セルフレビューチェックリスト

CCが実装完了後、pushする前に必ず確認すること:

```
□ GIFカードはパターンA or Bに従っているか
□ 筋肉マップのサイズは上記テーブルに従っているか
□ CTAボタンは52pt高 + 14pt角丸 + mmAccentPrimary背景か
□ 数値の強調（2倍以上のフォントサイズ）が適用されているか
□ セクション間の余白は12-16ptか
□ テキストが切れていないか（.lineLimit + 短縮表示）
□ ダークモードで全テキストが読めるか（白背景GIFの上に白テキストを置いていないか）
□ ファーストビューに3つ以上のセクションが詰まっていないか
□ 200行を超えるViewはないか
□ L10n（isJapanese パターン）が全テキストに適用されているか
```
