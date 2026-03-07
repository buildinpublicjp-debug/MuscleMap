# MuscleMap - Claude Code Rules

> **v3.2 | 2026-03-07**
> 筋肉の回復状態と筋力レベルを可視化し、最適なトレーニングを導くiOSアプリ

---

## プロジェクト概要

**MuscleMap**は、トレーニングで刺激した筋肉をリアルタイムに可視化し、回復状態を追跡するiOSアプリ。

**コンセプト:** 「筋肉の状態が見える。だから、迷わない。」

**核心機能:**
1. 2D SVG筋肉マップで21筋肉の回復状態をリアルタイム表示（ホーム画面）
2. ボリューム係数付き回復計算（セット数で回復時間が変動）
3. 7日以上未刺激の筋肉を紫で点滅警告
4. 今日のメニュー自動提案（回復データからルールベースで生成）
5. 92種目のEMGベース刺激度マッピング
6. 3D部位詳細表示（RealityKit、フォールバックあり）
7. Apple Watch companion app（watchOS 10.0+、WatchConnectivity同期）
8. **[Pro] Strength Map** — PRデータから筋肉の発達レベルを太さで可視化
9. **Strength Mapシェアカード** — 9:16（1080×1920px @3x）のPNG書き出し。グレードS〜D、Top3ランキング付き
10. **Workoutシェアカード** — 390×693pt @3x。ボリューム大表示 + PR更新種目の前回比表示（最大2件）。システムカラースキーム準拠
11. **次回おすすめ日** — ワークアウト完了時に回復予測から次の推奨トレーニング日を表示
12. **初回コーチマーク** — 初回起動時にホーム画面で操作ガイドを表示（1回限り）
13. **オンボーディング4ページ化** — SplashView → InteractiveDemo → PersonalizationPage（目標選択→UserProfile連携） → WeightInputPage（体重・ニックネーム） → CallToActionPage → 通知許可
14. 課金: PurchaseManager（RevenueCat接続は未実装、isPremium=trueでハードコード中）

**デザイントーン:** 「バイオモニター × G-SHOCK」 — ダーク基調、データが浮かび上がる

---

## 技術スタック

| 項目 | 選定 |
|:---|:---|
| Platform | iOS 17.0+ / watchOS 10.0+ |
| Language | Swift 5.9+ |
| UI | SwiftUI |
| DB | SwiftData |
| Architecture | MVVM + Repository Pattern |
| 2D人体図 | SVG（カスタムSwiftUI Path） |
| 3D表示 | RealityKit |
| 課金 | PurchaseManager.swift（RevenueCat接続予定、現在isPremium=trueで固定） |
| 3Dモデル | TurboSquid（USDZ） |

---

## 必読ドキュメント

1. `CLAUDE.md`（このファイル） — **最も重要。全ルールが入っている**
2. `docs/PRD/MuscleMap_PRD_v2.1.md` — 詳細仕様

---

## 課金状態（重要）

```
現在の状態:
- PurchaseManager.swift: isPremium = true にハードコード（開発用）
- RevenueCat SDK: 未導入（project.ymlに依存なし）
- Paywall UI: Views/Paywall/PaywallView.swift（実装予定 or 実装中）

本番リリース時に必要な作業:
1. RevenueCat SDK を project.yml に追加（purchases-ios v5系）
2. PurchaseManager.swift の isPremium をRevenueCatのentitlement判定に差し替え
3. App Store ConnectでProduct ID設定

プラン:
// 月額: ¥590/月
// 年額: ¥4,900/年（推奨）
// Entitlement名: "premium"
```

---

## Pro機能（isPremium == true の場合のみ表示）

| 機能 | 実装状態 | ゲートポイント |
|:---|:---|:---|
| Strength Map（筋力可視化マップ） | 実装中 | HomeView の Strength Mapボタン |
| 分析メニュー（WeeklySummary等） | 将来対応 | AnalyticsMenuView入口 |
| 履歴タブ | 将来対応 | ContentView Tab 3 |

---

## 画面デザインインテント（なぜこの画面が存在するか）

> **⚠️ UI修正や新画面実装の前に、必ずその画面の「存在目的」を確認すること。**
> ピクセル単位の修正をする前に「この画面を開くユーザーは何を求めているか？」を考える。
> 技術的に正しくても、ユーザー目線で意味がなければ失敗。

### ホーム画面
- **ユーザーの期待**: 「今日どこ鍛えればいい？」が一目でわかること
- **焦点**: 筋肉マップ + 今日のおすすめ + ストリーク。**最低3つの情報セクション**
- **絶対条件**:
  - 人体図は頭から足先まで完全に表示。切れてはいけない
  - 「今日のおすすめ」は筋肉マップと同等以上の視覚的存在感を持たせる
  - 画面を開いて3秒以内に「今日やること」が理解できる状態
- **NGパターン**:
  - 筋肉マップだけの画面（情報不足）
  - 「今日のおすすめ」がスクロールしないと見えない（優先度違反）

### Strength Map画面（Pro）
- **ユーザーの期待**: 「自分の筋力レベルが一目でわかる。自慢したい」
- **焦点**: 各筋肉の太さ = 筋力の強さ。PRが高いほど太く表示される
- **絶対条件**:
  - 未記録の筋肉は細く薄く表示（「まだ未開拓」として表現、ネガティブではない）
  - シェアカードとして書き出せること（Xへの投稿で「0.2秒でこいつやばい」とわかる）
  - PRが更新されるとリアルタイムで太さが変わること

### Strength Mapシェアカード
- **ファイル**: `Views/Home/StrengthShareCard.swift`
- **仕様**: 360×640pt → @3xで1080×1920px PNG（ImageRenderer）
- **構成**: ヘッダー(56pt) → 人体図(340pt) → ランキング(140pt) → フッター(64pt)
- **グレード体系**: S(0.85+) / A+(0.70+) / A(0.55+) / B+(0.40+) / B(0.30+) / C(0.20+) / D
- **ランキング**: 全21筋肉のスコア上位3をメダル付きで表示
- **トリガー**: ワークアウト完了画面でPR更新時にシェアボタン表示

### Workoutシェアカード
- **ファイル**: `Views/Workout/WorkoutCompletionComponents.swift`（`WorkoutShareCard`）
- **仕様**: 390×693pt → @3xで1170×2079px PNG（ImageRenderer scale=3.0）
- **カラースキーム**: システム設定準拠（`.environment(\.colorScheme, .dark)` は使わない）
- **構成（上→下）:**
  1. ヘッダー: 「MuscleMap」左 + 日付右
  2. タイトル: 「WORKOUT COMPLETE」mmAccentPrimaryで中央（tracking: 2）
  3. 筋肉図（210pt）: 前面・背面を並列（`ShareMuscleMapView(mapHeight: 210)`）
  4. メインスタット: ボリューム数値を48pt heavyで大きく中央 + 「kg」18pt + 「TOTAL VOLUME」ラベル
  5. PR更新セクション（条件付き）: PR更新があれば最大2件表示。「種目名  90kg → 100kg  ↑11%」形式。`PRManager.getSessionPRUpdates()` でデータ取得。PR無しなら非表示
  6. サブスタット: 種目数・セット数を小さく横並び（divider付き）
  7. フッター: 「MuscleMap」ロゴのみ
- **データ型**: `SharePRItem { exerciseName, previousWeight, newWeight, increasePercent }`
- **トリガー**: ワークアウト完了画面のシェアボタン

### ワークアウト完了 — 追加セクション
- **次回おすすめ日（NextRecommendedDaySection）**: RecoveryCalculator.adjustedRecoveryHoursで全刺激部位の回復時間を計算し、最も遅い回復日を推奨日として表示
- **Strength Mapシェア導線（StrengthMapShareSection）**: PR更新時のみ表示。「PR更新！Strength Mapをシェア」ボタンで直接シェアカード書き出し

### ホーム — コーチマーク（HomeCoachMarkView）
- **ファイル**: `Views/Home/HomeHelpers.swift`
- **表示条件**: WorkoutSet 0件 かつ `AppState.hasSeenHomeCoachMark == false` の場合のみ
- **内容**: 「まずワークアウトを記録しよう」+ 下矢印アニメーション
- **消去**: タップで閉じ、AppStateに記録（1回限り表示）

### オンボーディング（4ページ + SplashView + 通知許可）
- **ファイル**: `Views/Onboarding/`（9ファイル）
- **フロー:**
  ```
  SplashView（2.5秒アニメーション付き）
      ↓
  OnboardingV2View（4ページ横スワイプ TabView）:
    Page 1: InteractiveDemoPage（筋肉をタップして体験）
    Page 2: PersonalizationPage（目標選択 → UserProfile.trainingGoal に保存）
    Page 3: WeightInputPage（体重 40-160kg + ニックネーム → UserProfile に保存）
    Page 4: CallToActionPage（3機能紹介 + Strength Map予告 + CTA「無料ではじめる」）
      ↓
  NotificationPermissionView（通知許可）
      ↓
  アプリ本体へ
  ```
- **SplashView**: ロゴ/アイコン フェードイン → サブコピー → 筋肉マップデモ（順次点灯） → タグライン → 続行ボタン。グローアニメーション付き
- **PersonalizationPage**: 4目標（筋肥大/筋力/回復/健康）、OnboardingGoal → TrainingGoal マッピング。スプリングアニメーション + staggered fade-in
- **WeightInputPage**: ニックネームTextField + ドラムロールPicker（kg/lb切替）。AppState.shared.userProfile にリアルタイム保存
- **CallToActionPage**: 3つの機能カード + Strength Map予告バッジ + グロー付きCTAボタン + 利用規約/プライバシーポリシーリンク
- **カラーパレット（オンボーディング専用）:**
  - `.mmOnboardingAccent` = `#00E676`, `.mmOnboardingAccentDark` = `#00B35F`
  - `.mmOnboardingBg` = `#1A1A1E`, `.mmOnboardingCard` = `#2C2C2E`
  - `.mmOnboardingTextMain` = white @ 90%, `.mmOnboardingTextSub` = `#8E8E93`

### 履歴画面（マップ表示）
- **ユーザーの期待**: 「最近どこを鍛えた？バランスは？」がわかること
- **焦点**: 鍛えた部位のハイライト。期間内のトレーニング分布が視覚的にわかること
- **絶対条件**: 人体図は頭から足先まで完全に表示

### 履歴画面（カレンダー表示）
- **ユーザーの期待**: 「いつトレーニングした？頻度は？」がわかること
- **焦点**: カレンダー上のトレーニング日が視覚的に目立つこと

### ワークアウト画面
- **ユーザーの期待**: 「今のセットを素早く記録したい」
- **焦点**: 重量・レップ数の入力。前回の記録が見えること
- **絶対条件**: 入力の邪魔になるUI要素を置かない。最小タップで記録完了

### 種目辞典
- **ユーザーの期待**: 「この種目はどこに効く？」「この部位を鍛える種目は？」
- **焦点**: 種目と部位の関係が視覚的にわかること

### 全画面共通の確認チェックリスト

UI実装・修正が完了したら、以下を必ず確認する：

1. **画面の存在目的を満たしているか？**
2. **ビジュアル要素が切れていないか？**
3. **同じデータを表示する他画面と品質が同等か？**
4. **ユーザーになりきって操作してみたか？**
5. **フォント階層が適用されているか？**
6. **競合と並べて恥ずかしくないか？**

---

## UIデザイン原則

> **全UI実装の判断基準。新画面・新コンポーネント作成時に必ず参照すること。**

### 基本思想

| 思想 | 意味 |
|:---|:---|
| **ビジュアルファースト** | テキストより視覚表現を優先。3Dモデル、色彩、チャートで直感的に伝える |
| **情報階層の明確化** | 全情報を同等に扱わない。最重要データを最も目立たせる |
| **達成感の演出** | PR更新やマイルストーンは祝福の体験としてデザインする |
| **iOSネイティブ準拠** | SwiftUI標準コンポーネントとHIGを最大限尊重。独自パターンは最終手段 |

### ビジュアルインパクト

- 部位詳細・種目詳細・ワークアウトサマリーなど、特定対象に焦点を当てる画面では、3Dビジュアルまたは画像を**画面上部の最低1/3（33%）**で大きく表示する
- リスト形式の画面でも、各行にサムネイル/アイコンを必ず配置。**テキストのみの行は禁止**
- ハーフモーダルでも同じルールを適用。テキストリストだけのモーダルは作らない

### 情報ヒエラルキー（フォント）

PR・重量・セット数などの重要数値は、周囲ラベルの**2.0倍以上**のフォントサイズ + `Heavy`/`Black`ウェイト。

```swift
// 例: PR数値の強調
VStack(alignment: .leading) {
    Text("自己ベスト")
        .font(.body)
        .foregroundColor(.mmTextSecondary)
    Text("120 kg")
        .font(.system(size: 48, weight: .heavy))
        .foregroundColor(.mmAccentPrimary)
}
```

**フォント階層（4段階）:**

| レベル | 用途 | SwiftUI | ウェイト |
|:---|:---|:---|:---|
| L1 | 画面タイトル | `.largeTitle` | `Heavy` |
| L2 | セクションタイトル | `.title2` | `Bold` |
| L3 | 主要数値・項目名 | `.title3` | `Bold` |
| L4 | 本文・補足 | `.body` / `.caption` | `Regular` |

### スペーシング（8ptグリッド）

- セクション間: `32pt`
- 要素間: `16pt`
- コンテナ内パディング: `16pt`
- リスト行の最小高さ: `44pt`（タップ領域確保）

### モーダル / シート

- ハーフモーダルを積極使用（`.presentationDetents([.medium, .large])`）
- モーダル内に**必ずビジュアル要素**を含める
- モーダル背景は`.mmBgSecondary`
- 上部に太字タイトル必須

### コンポーネント再利用（検索義務）

新画面・新コンポーネント作成前に**必ず**:

1. `Grep`で表示するデータ型や類似View名を検索
2. 流用可能なら流用。不可なら理由を明記して新規作成
3. 新規作成でも、既存コンポーネントの`aspectRatio`, `frame`, `cornerRadius`, カラーをコピー

❌ NG: 「ロジックが違うから新規作成」
✅ OK: 「ロジックは別でも、見た目の設定は既存からコピー」

### NGパターン（禁止事項）

- ❌ テキストだけのリスト画面（ビジュアル要素なし）
- ❌ 全要素が同サイズ・同ウェイトのフラットレイアウト
- ❌ アクセントカラーが画面の30%以上を占める
- ❌ 余白ゼロの詰め込みレイアウト
- ❌ iOS標準から逸脱したナビゲーション
- ❌ 純粋な黒（`#000000`）の背景使用
- ❌ 既存の類似コンポーネントを無視して新規作成する
- ❌ 彩度100%の蛍光色を使用（状態色は彩度70%以下）

---

## カラーシステム（実装済み — ColorExtensions.swift に定義）

### 背景

| 用途 | コード | Hex |
|:---|:---|:---|
| 最背面 | `.mmBgPrimary` | `#121212` |
| カード・モーダル | `.mmBgSecondary` | `#1E1E1E` |
| 浮き上がるカード | `.mmBgCard` | `#2A2A2A` |

### テキスト

| 用途 | コード | 備考 |
|:---|:---|:---|
| 主要テキスト | `.mmTextPrimary` | `Color.white` |
| 補足テキスト | `.mmTextSecondary` | `#B0B0B0` |

### アクセント

| 用途 | コード | Hex |
|:---|:---|:---|
| メインアクセント | `.mmAccentPrimary` | `#00FFB3`（バイオグリーン） |
| サブアクセント | `.mmAccentSecondary` | `#00D4FF`（電光ブルー） |
| ブランドパープル | `.mmBrandPurple` | `#A020F0` |

### 筋肉状態カラー（回復マップ用）

⚠️ **色の方向: レッド(疲労) → イエロー → グリーン(回復)。信号機と同じ。**

| 状態 | コード | Hex | 回復% |
|:---|:---|:---|:---|
| 疲労 | `.mmMuscleFatigued` | `#E57373` | 0-20% |
| 中間 | `.mmMuscleModerate` | `#FFD54F` | 20-80% |
| 回復済み | `.mmMuscleRecovered` | `#81C784` | 80-100% |
| 記録なし | `.mmMuscleInactive` | `#3D3D42` | — |
| 未刺激警告 | `.mmMuscleNeglected` | `#B388D4` | 7日+ |

---

## データモデル

### 筋肉定義（21筋肉）

```swift
enum Muscle: String, CaseIterable, Codable {
    // 胸（2）
    case chestUpper = "chest_upper"
    case chestLower = "chest_lower"
    // 背中（4）
    case lats = "lats"
    case trapsUpper = "traps_upper"
    case trapsMiddleLower = "traps_middle_lower"
    case erectorSpinae = "erector_spinae"
    // 肩（3）
    case deltoidAnterior = "deltoid_anterior"
    case deltoidLateral = "deltoid_lateral"
    case deltoidPosterior = "deltoid_posterior"
    // 腕（3）
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"
    // 体幹（2）
    case rectusAbdominis = "rectus_abdominis"
    case obliques = "obliques"
    // 下半身（7）
    case glutes = "glutes"
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case adductors = "adductors"
    case hipFlexors = "hip_flexors"
    case gastrocnemius = "gastrocnemius"
    case soleus = "soleus"
}
```

### SwiftData モデル（変更禁止）

```swift
@Model class WorkoutSession {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var note: String?
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]
    var isActive: Bool { endDate == nil }
}

@Model class WorkoutSet {
    var id: UUID
    var session: WorkoutSession?
    var exerciseId: String   // exercises.json の id
    var setNumber: Int
    var weight: Double       // kg
    var reps: Int
    var completedAt: Date
}

@Model class MuscleStimulation {
    var muscle: String       // Muscle.rawValue
    var stimulationDate: Date
    var maxIntensity: Double // 0.0-1.0
    var totalSets: Int
    var sessionId: UUID      // 手動FK（SwiftDataリレーションではない）
}
```

### 回復計算

```swift
// RecoveryCalculator.swift
static func volumeCoefficient(sets: Int) -> Double
static func recoveryProgress(stimulationDate: Date, muscle: Muscle, totalSets: Int) -> Double
```

### PR計算（PRManager.swift）

```swift
// 推定1RM（Epley式）— Strength Mapの計算に使用
func estimated1RM(weight: Double, reps: Int) -> Double {
    guard reps > 1 else { return weight }
    return weight * (1 + Double(reps) / 30.0)
}

// 指定セッション以外の過去最大重量を取得（前回比用）
func getPreviousWeightPR(exerciseId: String, excludingSessionId: UUID, context: ModelContext) -> Double?

// 今回セッションでPR更新した種目一覧を取得（増加率順ソート）
func getSessionPRUpdates(session: WorkoutSession, context: ModelContext) -> [PRUpdate]

// PRUpdate: exerciseId, previousWeight, newWeight, increasePercent(%)
```

### Strength Score計算（StrengthScoreCalculator.swift）

```swift
// 各筋肉のスコア算出フロー:
// 1. 全WorkoutSetから種目ごとの最大推定1RM（Epley式）を取得
// 2. strengthRatio = 推定1RM / userBodyweightKg
// 3. 種目カテゴリ別の閾値テーブルで 0.0〜1.0 にスコア化
// 4. 筋肉に複数種目が関連する場合は最高スコアを採用
// 5. スコア→strokeWidth/opacity/colorに変換

// カテゴリA（コンパウンド大筋群）: chest_upper/lower, lats, traps_middle_lower, quadriceps, hamstrings, glutes, erector_spinae
// カテゴリB（コンパウンド中筋群）: deltoid_*, traps_upper, biceps, triceps
// カテゴリC（アイソレーション）: forearms, gastrocnemius, soleus, obliques, rectus_abdominis, adductors
```

### 種目データ（exercises.json）

`Resources/exercises.json` にバンドル同梱。起動時にExerciseStoreに読み込む。
**92種目、EMG論文ベースで刺激度%を設定済み。7言語対応（日英中韓西仏独）。**

---

## 画面構成

```
TabBar
├── ホーム（筋肉マップ）         ← P0（実装済み）
├── ワークアウト（記録）          ← P0（実装済み）
├── 種目辞典                    ← P1（実装済み）
├── 履歴（マップ/カレンダー切替） ← P1（実装済み）
└── 設定                        ← P2（実装済み）

Onboarding（初回のみ）
├── SplashView                  ← 実装済み（アニメーション付きスプラッシュ）
├── OnboardingV2View（4ページ）  ← 実装済み
│   ├── InteractiveDemoPage     ← 実装済み（筋肉タップ体験）
│   ├── PersonalizationPage     ← 実装済み（目標選択 → UserProfile連携）
│   ├── WeightInputPage         ← 実装済み（体重・ニックネーム入力）
│   └── CallToActionPage        ← 実装済み（機能紹介 + CTA）
└── NotificationPermissionView  ← 実装済み（通知許可）

Modal / Push
├── 今日のメニュー提案           ← P0（実装済み）
├── ワークアウト実行中           ← P0（実装済み）
├── 種目詳細                    ← P1（実装済み）
├── 部位詳細（3D）              ← P1（実装済み）
├── 分析メニュー（4画面）        ← P1（実装済み、将来Pro化予定）
├── Strength Map（Pro）         ← 実装中
├── Strength Mapシェアカード     ← 実装済み（PR更新時にワークアウト完了から呼出）
├── Workoutシェアカード          ← 実装済み（PR前回比表示 + システムカラースキーム対応）
├── Paywall                     ← 実装中
└── Homeコーチマーク             ← 実装済み（初回のみオーバーレイ表示）
```

---

## ファイル構成（実際のディレクトリ）

```
MuscleMap/
├── App/
│   ├── MuscleMapApp.swift
│   ├── ContentView.swift
│   └── AppState.swift
├── Connectivity/               # Watch連携
│   ├── PhoneSessionManager.swift
│   └── WatchDataProcessor.swift
├── Data/                       # ローカルキャッシュ系
│   ├── ExerciseDescriptions.swift
│   ├── FavoritesManager.swift
│   └── RecentExercisesManager.swift
├── Models/
│   ├── WorkoutSession.swift
│   ├── WorkoutSet.swift
│   ├── MuscleStimulation.swift
│   ├── Muscle.swift
│   ├── ExerciseDefinition.swift
│   └── UserProfile.swift
├── Repositories/
│   ├── WorkoutRepository.swift
│   └── MuscleStateRepository.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── WorkoutViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── ExerciseListViewModel.swift
│   ├── MuscleDetailViewModel.swift
│   ├── WeeklySummaryViewModel.swift
│   ├── MuscleBalanceDiagnosisViewModel.swift
│   ├── MuscleHeatmapViewModel.swift
│   ├── MuscleJourneyViewModel.swift
│   └── StreakViewModel.swift
├── Views/
│   ├── Components/             # 共通コンポーネント
│   │   ├── MiniMuscleMapView.swift
│   │   ├── MicroBodyMapView.swift
│   │   ├── ExerciseGifView.swift
│   │   └── ShareCardTemplate.swift
│   ├── Home/                   # ホーム画面（14ファイル）
│   │   ├── StrengthMapView.swift     # [Pro] 筋力可視化マップ
│   │   ├── StrengthShareCard.swift   # Strength Mapシェアカード（@3x PNG生成）
│   │   └── HomeHelpers.swift         # HomeCoachMarkView含む
│   ├── Workout/                # ワークアウト記録（14ファイル）
│   │   ├── WorkoutCompletionView.swift       # 完了画面本体
│   │   ├── WorkoutCompletionComponents.swift # WorkoutShareCard（PR前回比表示）, StatBox, ShareSheet
│   │   ├── WorkoutCompletionSections.swift   # NextRecommendedDaySection, StrengthMapShareSection含む
│   │   └── ShareMuscleMapView.swift          # シェアカード用静的筋肉マップ（mapHeight可変）
│   ├── Exercise/               # 種目辞典（3ファイル）
│   ├── History/                # 履歴（7ファイル）
│   ├── MuscleDetail/           # 部位詳細（2ファイル）
│   ├── Onboarding/             # オンボーディング（9ファイル）
│   │   ├── OnboardingView.swift          # フェーズ管理（Splash→V2→通知）
│   │   ├── OnboardingV2View.swift        # 4ページ横スワイプ + 専用カラーパレット
│   │   ├── SplashView.swift              # プレミアムスプラッシュ（アニメーション付き）
│   │   ├── InteractiveDemoPage.swift     # 筋肉タップ体験
│   │   ├── PersonalizationPage.swift     # 目標選択（→UserProfile.trainingGoal）
│   │   ├── WeightInputPage.swift         # 体重・ニックネーム入力（→UserProfile）
│   │   ├── CallToActionPage.swift        # 機能紹介 + CTA
│   │   ├── NotificationPermissionView.swift  # 通知許可
│   │   └── ValuePropositionPage.swift    # （旧ページ、参考保持）
│   ├── Settings/               # 設定（2ファイル）
│   └── Paywall/                # Paywall（実装中）
│       └── PaywallView.swift
├── Utilities/
│   ├── RecoveryCalculator.swift
│   ├── PRManager.swift         # 推定1RM（Epley式）+ PR前回比取得 + PRUpdate構造体
│   ├── PurchaseManager.swift   # isPremium判定（RevenueCat接続予定）
│   ├── StrengthScoreCalculator.swift  # PRデータ→筋肉スコア変換
│   ├── MenuSuggestionService.swift
│   ├── ColorCalculator.swift
│   ├── ColorExtensions.swift
│   ├── DateExtensions.swift
│   ├── HapticManager.swift
│   ├── ThemeManager.swift
│   ├── LocalizationManager.swift
│   ├── ModelLoader.swift
│   ├── WidgetDataProvider.swift
│   ├── LegalURL.swift
│   ├── AppConstants.swift
│   ├── KeyManager.swift
│   └── KeychainHelper.swift
└── Resources/
    ├── exercises.json          # 92種目
    ├── Assets.xcassets
    ├── exercises_gif/          # folder reference
    └── 3DModels/               # 現在は空

MuscleMapWatch/                 # Apple Watch companion
MuscleMapWidget/                # Widget extension
Shared/                         # iOS/Watch共有コード
scripts/
└── screenshots/                # App Storeスクショ自動生成パイプライン（準備中）
```

---

## コーディング規約

### MUST（必須）
- SwiftUI Only
- SwiftData でデータ永続化
- MVVM + Repository Pattern
- `@Observable` マクロ使用（iOS 17+）
- `async/await` 使用
- 日本語コメント
- 実装前に必ずCLAUDE.mdを読む

### MUST NOT（禁止）
- UIKit使用（SwiftUIで代替可能な場合）
- ハードコード文字列（Localizable対応準備）
- 200行超のView（分割する）
- Force Unwrap (`!`) の乱用
- muscleMapping数値をコードにハードコード（JSONから読む）
- SwiftDataの`@Model`クラスを無断で変更・追加する
- `WorkoutSet`に直接`@Query`をViewから書く（ViewModel/Repository経由）

### SHOULD（推奨）
- Preview Provider を全Viewに用意
- 8の倍数でスペーシング
- Haptic Feedback（セット完了、ワークアウト終了時）

### Pro機能実装時のルール
- `PurchaseManager.shared.isPremium` で判定
- isPremiumがfalseの場合は`PaywallView`を`.sheet`で表示
- Pro機能をゲートする場所は最小限に（ゲートA: HomeViewのStrengthMapボタン、ゲートB: ContentViewのHistoryTab）

---

## マイクロインタラクション（MUST）

| アクション | 必須フィードバック |
|:---|:---|
| セット完了 | Haptic (medium) + チェックアニメーション |
| ワークアウト終了 | Haptic (heavy) + サマリー画面遷移 |
| PR達成 | Haptic (heavy) + 祝福モーダル + 紙吹雪アニメーション |
| 種目追加 | Haptic (light) + リストにスライドイン |
| ボタンタップ | Haptic (light) + スケールアニメーション |

---

## テスト

- **MUST:** RecoveryCalculator の全メソッドにUnit Test
- **MUST:** Repository のデータ操作にテスト
- **MUST:** ExerciseStore のJSON読み込みテスト
- **SHOULD:** 主要フローのUIテスト
