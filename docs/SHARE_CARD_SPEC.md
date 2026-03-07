# Strength Map シェアカード — デザイン仕様書

> **目的:** Strength Mapのシェアカードを「0.2秒でこいつやばい」と思わせるビジュアルとして実装するための仕様。
> 実装担当: Claude Code / `Views/Home/StrengthMapView.swift` 内のシェアカード生成処理

---

## コンセプト

**「筋力アイデンティティカード」**

- スポーツ選手のトレーディングカードをイメージ
- 見た瞬間に「どこが強くてどこが弱いか」がわかる
- Xに投げると「ベンチ強すぎ」「脚細い笑」のリアクションが生まれる設計
- アプリをダウンロードしていない人でも「これ何のアプリ?」と思う情報密度

---

## カードサイズ・フォーマット

```
出力サイズ: 1080 × 1920 px（9:16、Instagram Stories / X縦長に最適）
代替サイズ: 1080 × 1080 px（1:1、X正方形投稿）
ファイル形式: PNG（透過なし）
生成方法: SwiftUI View → UIGraphicsImageRenderer でラスタライズ
```

**SwiftUI実装のキャンバスサイズ:**
```swift
// 9:16バージョン
.frame(width: 390, height: 693)  // @3x で 1170×2079px → 中心に1080×1920をクロップ
// または
.frame(width: 360, height: 640)  // @3x で 1080×1920px ちょうど
```

---

## レイアウト構造

```
┌─────────────────────────────┐  ← カード全体 (360×640pt)
│  ████ MuscleMap  [日付]     │  ← ヘッダー (高さ 56pt)
│─────────────────────────────│
│                             │
│   ┌─────────┐  ┌─────────┐  │
│   │  前面   │  │  背面   │  │  ← 人体図エリア (高さ 340pt)
│   │ 筋肉マップ│  │ 筋肉マップ│  │
│   └─────────┘  └─────────┘  │
│                             │
│─────────────────────────────│
│  TOP 3  強い筋肉            │  ← ランキングエリア (高さ 140pt)
│  🥇 大胸筋    ████ 87%     │
│  🥈 広背筋    ███░ 74%     │
│  🥉 大腿四頭筋 ██░░ 61%    │
│─────────────────────────────│
│  ユーザー名  @handle        │  ← フッター (高さ 64pt)
│  筋力スコア総合: B+          │
└─────────────────────────────┘
```

---

## 各エリアの仕様

### 1. ヘッダー (高さ 56pt)

```
背景色: #121212（mmBgPrimary ダーク固定）
パディング: 水平 20pt

[左] ロゴ
  - "M" アイコン + "MuscleMap" テキスト
  - フォント: .system(size: 13, weight: .heavy)
  - 色: #00FFB3（mmAccentPrimary）

[右] 日付
  - 表示形式: "2026.03.07"
  - フォント: .system(size: 11, weight: .medium)
  - 色: #B0B0B0（mmTextSecondary）

区切り線: 幅100%、高さ 0.5pt、色 #808080（mmBorder）
```

---

### 2. 人体図エリア (高さ 340pt)

```
背景色: #121212
パディング: 水平 16pt、上下 12pt

前面図 / 背面図 を左右に並べて表示:
  - 各図サイズ: (全体幅 - 16*2 - 8) / 2 = 約156pt × 高さ 316pt
  - 間隔: 8pt

筋肉の描画（Strength Mapモード）:
  strokeWidth:
    score 0.0（未記録）: 1.0pt
    score 0.0-0.2:       1.5pt
    score 0.2-0.4:       2.5pt
    score 0.4-0.6:       3.5pt
    score 0.6-0.8:       5.0pt
    score 0.8-1.0:       7.0pt

  opacity:
    score 0.0（未記録）: 0.20
    score 0.0-0.2:       0.35
    score 0.2-0.4:       0.50
    score 0.4-0.6:       0.65
    score 0.6-0.8:       0.80
    score 0.8-1.0:       1.00

  fill color:
    score 0.0（未記録）: #3D3D42（mmMuscleInactive）
    score 0.0-0.6:       #00FFB3（mmAccentPrimary）グラデーション
    score 0.6-1.0:       #00FFB3 → #FFFFFF ハイライト

⚠️ シェアカードは常にダークモード固定で描画する（UITraitCollection を無視）
```

---

### 3. ランキングエリア (高さ 140pt)

**「TOP 3 強い筋肉」**

```
背景色: #1E1E1E（mmBgSecondary）
パディング: 水平 20pt、上下 12pt
コーナーなし（エリア全幅）

セクションタイトル:
  テキスト: "STRENGTH RANKING"
  フォント: .system(size: 10, weight: .heavy)
  色: #B0B0B0
  letter-spacing: 0.1em（SwiftUI: .tracking(1.5)）

各ランク行（3行）:
  高さ: 36pt
  レイアウト: [メダル絵文字] [筋肉名] [スコアバー] [%]

  メダル: 🥇🥈🥉（1位〜3位）
  筋肉名:
    フォント: .system(size: 14, weight: .semibold)
    色: #FFFFFF
  スコアバー:
    幅: 80pt（全体比でスコアに応じて塗り潰し）
    高さ: 6pt
    背景色: #3D3D42
    塗り色: #00FFB3
    cornerRadius: 3pt
  %表示:
    フォント: .system(size: 13, weight: .bold)
    色: #00FFB3
    幅: 40pt（右揃え）

筋肉名の日本語表示:
  chest_upper     → 大胸筋（上部）
  chest_lower     → 大胸筋（下部）
  lats            → 広背筋
  traps_upper     → 僧帽筋（上部）
  traps_middle_lower → 僧帽筋（中下部）
  erector_spinae  → 脊柱起立筋
  deltoid_anterior  → 三角筋（前部）
  deltoid_lateral   → 三角筋（側部）
  deltoid_posterior → 三角筋（後部）
  biceps          → 上腕二頭筋
  triceps         → 上腕三頭筋
  forearms        → 前腕
  rectus_abdominis → 腹直筋
  obliques        → 腹斜筋
  glutes          → 大臀筋
  quadriceps      → 大腿四頭筋
  hamstrings      → ハムストリングス
  adductors       → 内転筋
  hip_flexors     → 腸腰筋
  gastrocnemius   → 腓腹筋
  soleus          → ヒラメ筋
```

---

### 4. フッター (高さ 64pt)

```
背景色: #121212
パディング: 水平 20pt

[左]
  ユーザー名 or "MuscleMap User"
    フォント: .system(size: 14, weight: .bold)
    色: #FFFFFF
  総合グレード
    フォント: .system(size: 11, weight: .regular)
    色: #B0B0B0

[右]
  総合グレードバッジ（大きく）
    テキスト: "S" / "A+" / "A" / "B+" / "B" / "C" / "D"
    フォント: .system(size: 36, weight: .heavy)
    色: グレードに応じて変化（下記参照）
    背景: 円形、diameter 52pt

グレードと色:
  S:  平均スコア 0.85+  → #00FFB3（mmAccentPrimary）
  A+: 平均スコア 0.70+  → #00FFB3（やや暗め）
  A:  平均スコア 0.55+  → #00D4FF（mmAccentSecondary）
  B+: 平均スコア 0.40+  → #81C784（mmMuscleRecovered）
  B:  平均スコア 0.30+  → #FFD54F（mmMuscleModerate）
  C:  平均スコア 0.20+  → #B0B0B0
  D:  平均スコア 0.20未満→ #808080

総合グレードの計算:
  全21筋肉のstrengthScoreの平均値でグレード判定
  記録なし（score=0）の筋肉はスコア0として計算に含める
```

---

## 背景デザイン

```
ベース: #121212 単色

装飾要素（控えめに）:
  グリッド線:
    色: #1E1E1E（ベースより少し明るいだけ）
    間隔: 24pt
    線幅: 0.5pt
    人体図エリアにのみ表示

NG:
  - グロウエフェクト（重くなる）
  - グラデーション背景（トーンが崩れる）
  - 装飾的な図形や模様
```

---

## グレードバッジ 詳細

```swift
// 総合グレードの計算
func overallGrade(scores: [Double]) -> String {
    let average = scores.reduce(0, +) / Double(scores.count)
    switch average {
    case 0.85...: return "S"
    case 0.70...: return "A+"
    case 0.55...: return "A"
    case 0.40...: return "B+"
    case 0.30...: return "B"
    case 0.20...: return "C"
    default:      return "D"
    }
}

// グレードカラー
func gradeColor(_ grade: String) -> Color {
    switch grade {
    case "S":  return .mmAccentPrimary
    case "A+": return Color(hex: "#00CC8F")
    case "A":  return .mmAccentSecondary
    case "B+": return .mmMuscleRecovered
    case "B":  return .mmMuscleModerate
    case "C":  return .mmTextSecondary
    default:   return Color(hex: "#808080")
    }
}
```

---

## シェアカード生成の実装方針

```swift
// StrengthMapView.swift 内に実装

struct StrengthShareCard: View {
    let scores: [String: Double]          // muscle.rawValue → 0.0-1.0
    let userName: String
    let date: Date

    var body: some View {
        // 上記仕様に従って実装
        // 常にダークモード固定
        // .environment(\.colorScheme, .dark) を付与
    }
}

// 書き出し処理
func generateShareImage(view: some View, size: CGSize) -> UIImage {
    let renderer = ImageRenderer(content:
        view.frame(width: size.width, height: size.height)
    )
    renderer.scale = 3.0  // @3x で書き出し
    return renderer.uiImage ?? UIImage()
}
```

---

## シェア発動タイミング

| トリガー | 表示方法 | 備考 |
|:--|:--|:--|
| Strength Map画面で長押し | プレビュー → シェアシート | メイン導線 |
| Strength Map画面のシェアボタン | シェアシート直接 | サブ導線 |
| ワークアウト完了画面（PR更新時） | 「Strength Mapをシェア」ボタン | 感情ピーク時の誘導 |

---

## シェアシートの設定

```swift
ShareLink(
    item: Image(uiImage: shareImage),
    preview: SharePreview(
        "私の筋力マップ",
        image: Image(uiImage: shareImage)
    )
)

// または UIActivityViewController
let text = "MuscleMapで筋力を可視化中 💪 #MuscleMap #筋トレ"
let items: [Any] = [shareImage, text]
```

---

## バリエーション（将来対応）

| バリエーション | 概要 | 優先度 |
|:--|:--|:--|
| 9:16（縦長） | Instagram Stories / X縦長 | **今回実装** |
| 1:1（正方形） | X標準投稿 | 次フェーズ |
| Before/After | 1ヶ月前との比較 | 将来 |
| 部位別クローズアップ | 特定筋肉だけ大きく | 将来 |

---

## 実装チェックリスト

- [ ] `StrengthShareCard` View の作成
- [ ] 常にダークモード固定（`.environment(\.colorScheme, .dark)`）
- [ ] `ImageRenderer` で @3x PNG 書き出し
- [ ] `ShareLink` または `UIActivityViewController` で共有
- [ ] Strength Map画面にシェアボタン追加
- [ ] ハプティクス: シェアボタンタップ時 `.light`
- [ ] ユーザー名: `UserProfile.nickname` から取得（未設定時は "MuscleMap User"）
- [ ] グレードバッジの色が正しく出ているかシミュレーター確認
- [ ] 人体図が切れていないかスクショ確認（前面・背面両方）

---

*最終更新: 2026-03-07*
