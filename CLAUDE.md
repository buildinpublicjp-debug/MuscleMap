# MuscleMap - Claude Code Rules

> **v9.0 | 2026-04-04**
> 筋肉の回復状態と筋力レベルを可視化し、最適なトレーニングを導くiOSアプリ
> **ステータス:** App Store提出準備完了（v1.0）

---

## プロジェクト概要

**MuscleMap**は、トレーニングで刺激した筋肉をリアルタイムに可視化し、回復状態を追跡するiOSアプリ。

**コンセプト:** 「筋肉の状態が見える。だから、迷わない。」

**核心機能:**
1. 2D SVG筋肉マップで21筋肉の回復状態をリアルタイム表示（ホーム画面、前面・背面同時表示）
2. ボリューム係数付き回復計算（セット数で回復時間が変動）
3. 7日以上未刺激の筋肉を紫で点滅警告
4. 今日のメニュー自動提案（回復データからルールベースで生成）
5. 92種目のEMGベース刺激度マッピング
6. 2D部位詳細表示（筋肉マップハイライト、同グループ薄表示）
7. Apple Watch companion app（watchOS 10.0+、WatchConnectivity同期）
8. **[Pro] Strength Map** — PRデータから筋肉の発達レベルを太さで可視化
9. **Strength Mapシェアカード** — 9:16（1080×1920px @3x）のPNG書き出し。グレードS〜D、Top3ランキング付き
10. **Workoutシェアカード** — 360×360pt @3x（1080×1080px正方形）。ダークグラデ背景 + グロー付き筋肉マップ + ボリューム大表示 + PR表示 + ウォーターマーク
11. **次回おすすめ日** — ワークアウト完了時に回復予測から次の推奨トレーニング日を表示
12. **初回コーチマーク** — 初回起動時にホーム画面で操作ガイドを表示（1回限り）
13. **オンボーディングv9（最大9ページ）** — SplashView → GoalSelectionPage（複数選択） → FrequencySelectionPage（超回復アニメ） → LocationSelectionPage（ジム/自宅/自重/両方、GIF付き） → ProfileInputPage（経験+体重+ニックネーム統合） → [PRInputPage] → MenuGeneratingPage（メニュー生成アニメ） → RoutineBuilderPage（自動ルーティン構築） → NotificationPermissionView（通知許可） → RoutineCompletionPage（ハードペイウォール付き完了画面）
14. **メニュープレビューシート** — ホームのおすすめメニューをGIF・筋肉マップ・重量付きで確認してから開始
15. 課金: PurchaseManager（RevenueCat SDK v5.61.0 接続済み、entitlement "premium" で判定、DEBUGビルドにisPremiumトグルあり）
16. **ルーティン管理** — オンボーディングで自動生成されたDay分割ルーティンを保存・編集（RoutineManager + UserRoutine）
17. **無料ユーザー週間制限** — 無料プランは週2回のワークアウト記録。PurchaseManager.canRecordWorkoutで判定、ContentViewでタブ遷移ゲート

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
| 課金 | RevenueCat SDK v5.61.0（PurchaseManager.swift、entitlement "premium" 判定） |

---

## 必読ドキュメント

1. `CLAUDE.md`（このファイル） — **最も重要。全ルールが入っている**
2. `docs/PRD/MuscleMap_PRD_v2.1.md` — 詳細仕様
3. `docs/DESIGN_SYSTEM.md` — UIデザイン原則v2.0（6原則+デフォルト値リファレンス）
4. `docs/CC_LESSONS.md` — CC自己改善ルール（蓄積された教訓）

---

## 課金状態（実装済み）

```
現在の状態:
- RevenueCat SDK: v5.61.0 導入済み（project.yml に依存設定済み）
- PurchaseManager.swift: RevenueCat entitlement "premium" で isPremium を判定
- Paywall UI: Views/Paywall/PaywallView.swift（実装済み、目標筋肉マップ+メニュープレビュー付き）
- PaywallView: isHardPaywall パラメータ対応（true: 閉じるボタン非表示、スワイプ閉じ無効）
- configure(): MuscleMapApp.init() で起動時に呼び出し済み
- PurchaseDelegate: entitlement変更をリアルタイム反映
- DEBUG: isPremiumトグル付き（#if DEBUG、設定画面の開発者メニューから切替可能）
- 無料ユーザー制限: weeklyWorkoutCount（週2回制限、月曜リセット）
- ContentView: ワークアウトタブ遷移時に canRecordWorkout チェック → アラート → PaywallView

残作業:
- App Store Connect で Product ID 設定・審査

プラン:
// 月額: ¥590/月
// 年額: ¥4,900/年（推奨、7日間無料トライアル）
// Entitlement名: "premium"
// API Key: appl_IzrrBdSVXMDZUylPnwcaJxvdlxb
```

---

## Pro機能（isPremium == true の場合のみ表示）

| 機能 | 実装状態 | ゲートポイント |
|:---|:---|:---|
| Strength Map（筋力可視化マップ） | 実装済み | HomeView の Strength Mapボタン |
| 今日のメニュー提案（パーソナライズ） | 実装済み | HomeView TodayRecommendationInline |
| メニュープレビューシート | 実装済み | HomeView → MenuPreviewSheet |
| ルーティン使用（Day分割メニュー） | 実装済み | RoutineManager + RoutineEditView |
| 無制限ワークアウト記録 | 実装済み | PurchaseManager.canRecordWorkout（無料: 週2回） |
| 分析メニュー（WeeklySummary等） | 将来対応 | AnalyticsMenuView入口 |

---

## 画面デザインインテント（なぜこの画面が存在するか）

> **⚠️ UI修正や新画面実装の前に、必ずその画面の「存在目的」を確認すること。**
> ピクセル単位の修正をする前に「この画面を開くユーザーは何を求めているか？」を考える。
> 技術的に正しくても、ユーザー目線で意味がなければ失敗。

### ホーム画面
- **ユーザーの期待**: 「今日どこ鍛えればいい？」が一目でわかること
- **焦点**: 筋肉マップ + 今日のおすすめ + ストリーク。**最低3つの情報セクション**
- **現在の構成（上→下）:**
  1. **TodayActionCard** — 「今日: 部位名」+ Day切替 + 種目GIF(140x120) + info + CTA
  2. **RecoveryStatusSection** — HStack（マップ前後 + ステータスミニチップ右寄せ）
  3. **WeeklyVolumeChart** — 週間ボリュームバーチャート
  4. **QuickAccessRow** — Strength Map / 履歴 等のショートカット
- **絶対条件**:
  - 人体図は頭から足先まで完全に表示。切れてはいけない
  - TodayActionCardが最も目立つ。CTAが画面上部にある
  - 画面を開いて3秒以内に「今日やること」が理解できる状態
  - 無料ユーザー: FreeWorkoutLimitBadge表示（残回数 or 使い切り状態）
- **NGパターン**:
  - 筋肉マップだけの画面（情報不足）
  - TodayActionCardがスクロールしないと見えない（優先度違反）

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
- **仕様**: 360×360pt → @3xで1080×1080px PNG（ImageRenderer scale=3.0、SNS正方形推奨）
- **カラースキーム**: 常にダーク（`.environment(\.colorScheme, .dark)`）。背景はグラデーション `#0A0A0A → #1A1A2E`
- **構成（上→下）:**
  1. ヘッダー: ロゴアイコン + 「MuscleMap」左 + 日付右（`yyyy.MM.dd`形式）
  2. タイトル: 「WORKOUT COMPLETE」mmAccentPrimaryで中央（tracking: 3）
  3. 筋肉図（140pt）: 前面・背面を並列 + グロー効果ON（`ShareMuscleMapView(mapHeight: 140, glowEnabled: true)`）
  4. メインスタット: ボリューム数値を42pt heavyで大きく中央 + 「kg」16pt + 「TOTAL VOLUME」ラベル
  5. PR更新セクション（条件付き）: NEW PR! ヘッダー + 最大2件表示。ゴールド(`#FFD700`)で目立たせる
  6. サブスタット: 種目数・セット数・トレーニング時間(分)を小さく横並び（divider付き）
  7. フッター: 「MuscleMap — Track Your Muscles」ウォーターマーク
- **データ型**: `SharePRItem { exerciseName, previousWeight, newWeight, increasePercent }`
- **共有テキスト**: 「MuscleMap で記録」+ App Store URL を含む
- **トリガー**: ワークアウト完了画面のシェアボタン

### ワークアウト完了 — 追加セクション
- **次回おすすめ日（NextRecommendedDaySection）**: RecoveryCalculator.adjustedRecoveryHoursで全刺激部位の回復時間を計算し、最も遅い回復日を推奨日として表示
- **Strength Mapシェア導線（StrengthMapShareSection）**: PR更新時のみ表示。「PR更新！Strength Mapをシェア」ボタンで直接シェアカード書き出し

### ホーム — コーチマーク（HomeCoachMarkView）
- **ファイル**: `Views/Home/HomeHelpers.swift`
- **表示条件**: WorkoutSet 0件 かつ `AppState.hasSeenHomeCoachMark == false` の場合のみ
- **内容**: 「まずワークアウトを記録しよう」+ 下矢印アニメーション（日英対応）
- **消去**: タップで閉じ、AppStateに記録（1回限り表示）

### ホーム — 無料ユーザー制限バッジ（FreeWorkoutLimitBadge）
- **ファイル**: `Views/Home/HomeHelpers.swift`
- **表示条件**: `!PurchaseManager.shared.isPremium` の場合のみ
- **内容**: 残回数表示 or 「今週の無料ワークアウト使い切り」（日英対応）

### オンボーディングv9（最大9ページ + SplashView）
- **ファイル**: `Views/Onboarding/`（13ファイル）
- **フロー:**
  ```
  SplashView（筋肉マップデモ + タグライン日英対応）
      ↓
  OnboardingV2View（最大9ページ横スワイプ TabView）:
    Page 0: GoalSelectionPage（目標選択、複数選択 + selectionOrder配列で順序保持）
    Page 1: FrequencySelectionPage（週間頻度 → UserProfile.weeklyFrequency、超回復アニメーション）
    Page 2: LocationSelectionPage（場所 → UserProfile.trainingLocation、GIF 130x130 + タップで詳細）
    Page 3: ProfileInputPage（トレ歴+体重+ニックネーム統合、ファイル名はTrainingHistoryPage.swift）
    Page 4: PRInputPage（PR入力、BIG3デフォルト表示、マップ220pt）
            ※ trainingExperience == .oneYearPlus || .veteran の場合のみ表示
    Page 5: MenuGeneratingPage（メニュー生成アニメーション、自動遷移）
    Page 6: RoutineBuilderPage（自動ルーティン構築 → RoutineManager に保存）
    Page 7: NotificationPermissionView（通知許可、筋肉マップ回復アニメーション付き）
    Page 8: RoutineCompletionPage（ルーティンサマリー + ハードペイウォール）
      ↓
  アプリ本体へ
  ```
- **SplashView**: ロゴ フェードイン → 筋肉マップデモ（前面+背面順次点灯） → タグライン（日英対応）→ 続行ボタン
- **GoalSelectionPage**: 「なぜ鍛える？」7目標エモーショナル版。**複数選択**、48ptコンパクトカード。selectionOrder配列で選択順序を保持し、最初の選択をprimaryOnboardingGoalに保存。goalPriorityMusclesも選択順序で合算保存
- **FrequencySelectionPage**: 週間トレーニング頻度（2-6回）。超回復アニメーション（回復完了筋肉→inactiveに戻る）。UserProfile.weeklyFrequencyに保存
- **LocationSelectionPage**: トレーニング場所（ジム/自宅/自重のみ/両方）。GIF 130x130カード表示、タップで種目詳細。TrainingLocation enumに.bodyweightケース追加済み。器具フィルタ日英両対応
- **ProfileInputPage**: TrainingHistoryPage + WeightInputPageを1ページに統合。横4択トレ歴 + 体重ステッパー（kg/lb切替） + ニックネーム。ファイル名は `TrainingHistoryPage.swift`（後方互換）
- **PRInputPage**: BIG3デフォルト表示（72x72 GIFカード）+ 追加種目のPR入力。筋肉マップ220pt。種目の追加・変更が可能。スキップ可能
- **MenuGeneratingPage**: メニュー生成中のアニメーション表示。完了後に自動で次ページへ遷移
- **GoalMusclePreviewPage**: 目標に対応する分割法をプレビュー。Dayタップ→GIF付き種目シート表示（※現在のフローでは未使用、ファイルは残存）
- **RoutineBuilderPage**: 目標・頻度・場所・トレ歴から自動でDay分割ルーティンを構築。Day別location対応、「提案」明示。RoutineManager.shared.routine に保存。種目の入替・追加可能
- **RoutineCompletionPage**: ルーティンサマリー表示（Day別カード + 筋肉マップ + 成長グラフ）。ハードペイウォール付き（「Pro版を解放」ボタン → PaywallView(isHardPaywall: true)）。「無料ではじめる」で完了。目標別キャッチコピー（日英対応）
- **NotificationPermissionView**: 筋肉マップ回復アニメーション（胸・肩の4段階回復サイクル）+ 通知許可。日英対応
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
| **ビジュアルファースト** | テキストより視覚表現を優先。筋肉マップ、GIF、色彩、チャートで直感的に伝える |
| **情報階層の明確化** | 全情報を同等に扱わない。最重要データを最も目立たせる |
| **達成感の演出** | PR更新やマイルストーンは祝福の体験としてデザインする |
| **iOSネイティブ準拠** | SwiftUI標準コンポーネントとHIGを最大限尊重。独自パターンは最終手段 |

### ビジュアルインパクト

- 部位詳細・種目詳細・ワークアウトサマリーなど、特定対象に焦点を当てる画面では、筋肉マップハイライトまたはGIF画像を**画面上部の最低1/3（33%）**で大きく表示する
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

NG: 「ロジックが違うから新規作成」
OK: 「ロジックは別でも、見た目の設定は既存からコピー」

### NGパターン（禁止事項）

- テキストだけのリスト画面（ビジュアル要素なし）
- 全要素が同サイズ・同ウェイトのフラットレイアウト
- アクセントカラーが画面の30%以上を占める
- 余白ゼロの詰め込みレイアウト
- iOS標準から逸脱したナビゲーション
- 純粋な黒（`#000000`）の背景使用
- 既存の類似コンポーネントを無視して新規作成する
- 彩度100%の蛍光色を使用（状態色は彩度70%以下）

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

### セマンティックカラー

| 用途 | コード | Hex |
|:---|:---|:---|
| 破壊的アクション | `.mmDestructive` | `#FF453A` |
| 警告 | `.mmWarning` | `#FF9F0A` |
| PR達成ゴールド | `.mmPRGold` | `#FFD700` |

### 筋肉状態カラー（回復マップ用）

**色の方向: レッド(疲労) → イエロー → グリーン(回復)。信号機と同じ。**

| 状態 | コード | Hex | 回復% |
|:---|:---|:---|:---|
| 疲労 | `.mmMuscleFatigued` | `#E57373` | 0-20% |
| 中間 | `.mmMuscleModerate` | `#FFD54F` | 20-80% |
| 回復済み | `.mmMuscleRecovered` | `#81C784` | 80-100% |
| 記録なし | `.mmMuscleInactive` | `#3D3D42` | — |
| 未刺激警告 | `.mmMuscleNeglected` | `#B388D4` | 7日+ |

### cornerRadius 正規化（4段階）

| サイズ | 用途 |
|:---|:---|
| `4pt` | 小バッジ、プログレスバー |
| `8pt` | タグ、小カード内要素 |
| `16pt` | カード、ボタン、シート内要素 |
| `24pt` | 大モーダル、フルカード |

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

### ルーティンモデル（UserDefaults保存）

```swift
// Models/UserRoutine.swift
struct UserRoutine: Codable {
    var days: [RoutineDay]
    var createdAt: Date
}
struct RoutineDay: Codable, Identifiable {
    var id: UUID
    var name: String           // "Day 1: 胸・三頭" 等
    var muscleGroups: [String] // ["chest", "triceps"] (Muscle.rawValue)
    var exercises: [RoutineExercise]
    var location: String       // "gym" / "home" / "both" / "bodyweight"（後方互換: decodeIfPresent）
}
struct RoutineExercise: Codable, Identifiable {
    var id: UUID
    var exerciseId: String     // exercises.json の id
    var suggestedSets: Int     // デフォルト 3
    var suggestedReps: Int     // デフォルト 10
}

// Data/RoutineManager.swift
// RoutineManager.shared.routine で読み書き
// オンボーディングのRoutineBuilderPageで自動生成、設定のRoutineEditViewで編集
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

### 無料ユーザー制限（PurchaseManager）

```swift
// PurchaseManager.swift — 週間ワークアウト回数制限
var weeklyWorkoutCount: Int     // UserDefaults、月曜リセット
var canRecordWorkout: Bool      // isPremium || weeklyWorkoutCount < 2
func incrementWorkoutCount()    // WorkoutViewModel.endSession() から呼出（canonical location）
private func resetIfNewWeek()   // Calendar.firstWeekday = 2（月曜始まり）
```

---

## 画面構成

```
TabBar（5タブ）
├── ホーム（筋肉マップ）         ← tag:0（実装済み）
├── 記録（ワークアウト）          ← tag:1（実装済み、無料ユーザーは週2回制限）
├── 種目辞典                    ← tag:2（実装済み、NavigationStack wrap）
├── 履歴（マップ/カレンダー切替） ← tag:3（実装済み）
└── 設定                        ← tag:4（実装済み）

※ ソーシャルフィードは設定画面内からプレビュー表示
※ ワークアウトタブ遷移時: canRecordWorkout == false → アラート → PaywallView

Onboarding（初回のみ）
├── SplashView                  ← 実装済み（筋肉マップデモ + 日英タグライン）
├── OnboardingV2View（最大9ページ）← 実装済み
│   ├── GoalSelectionPage       ← 実装済み（目標選択エモーショナル版・複数選択・selectionOrder）
│   ├── FrequencySelectionPage  ← 実装済み（週間頻度 + 超回復アニメーション）
│   ├── LocationSelectionPage   ← 実装済み（ジム/自宅/自重のみ/両方 + GIF 130x130）
│   ├── ProfileInputPage        ← 実装済み（経験+体重+ニックネーム統合、ファイル: TrainingHistoryPage.swift）
│   ├── PRInputPage             ← 実装済み（BIG3デフォルト表示、経験者のみ、マップ220pt）
│   ├── MenuGeneratingPage      ← 実装済み（メニュー生成アニメーション + 自動遷移）
│   ├── RoutineBuilderPage      ← 実装済み（自動ルーティン構築、Day別location）
│   ├── NotificationPermissionView ← 実装済み（通知許可 + 筋肉マップ回復アニメーション）
│   └── RoutineCompletionPage   ← 実装済み（ルーティンサマリー + ハードペイウォール）

Modal / Push
├── 今日のメニュー提案           ← P0（実装済み）
├── ワークアウト実行中           ← P0（実装済み）
├── 種目詳細                    ← P1（実装済み）
├── 部位詳細（2D）              ← P1（実装済み）
├── 分析メニュー（4画面）        ← P1（実装済み、将来Pro化予定）
├── Strength Map（Pro）         ← 実装済み
├── Strength Mapシェアカード     ← 実装済み（PR更新時にワークアウト完了から呼出）
├── Workoutシェアカード          ← 実装済み（PR前回比表示 + システムカラースキーム対応）
├── メニュープレビューシート     ← 実装済み（GIF+筋肉マップ+重量付き確認）
├── Paywall                     ← 実装済み（isHardPaywall対応）
├── ルーティン編集               ← 実装済み（Settings/RoutineEditView）
├── CSVインポート                ← 実装済み（Settings/CSVImportView）
└── Homeコーチマーク             ← 実装済み（初回のみオーバーレイ表示）
```

---

## ファイル構成（実際のディレクトリ）

```
MuscleMap/
├── App/
│   ├── MuscleMapApp.swift
│   ├── ContentView.swift          # ルートビュー + タブ制御 + 無料ユーザーワークアウト制限ゲート
│   └── AppState.swift
├── Connectivity/                  # Watch連携
│   ├── PhoneSessionManager.swift
│   └── WatchDataProcessor.swift
├── Data/                          # ローカルキャッシュ系
│   ├── ExerciseDescriptions.swift
│   ├── FavoritesManager.swift
│   ├── MockFriendData.swift       # ソーシャルフィード用モックデータ
│   ├── RecentExercisesManager.swift
│   └── RoutineManager.swift       # ルーティン管理（UserDefaults保存）
├── Models/
│   ├── WorkoutSession.swift
│   ├── WorkoutSet.swift
│   ├── MuscleStimulation.swift
│   ├── Muscle.swift
│   ├── ExerciseDefinition.swift
│   ├── FriendActivity.swift       # フレンドアクティビティ（非SwiftData）
│   ├── UserProfile.swift
│   └── UserRoutine.swift          # ルーティンデータ構造（RoutineDay, RoutineExercise）
├── Repositories/
│   ├── ExerciseStore.swift        # exercises.json の読み込み + 種目検索
│   ├── WorkoutRepository.swift
│   └── MuscleStateRepository.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── WorkoutViewModel.swift     # endSession() 内で incrementWorkoutCount() 呼出
│   ├── HistoryViewModel.swift
│   ├── ExerciseListViewModel.swift
│   ├── MuscleDetailViewModel.swift
│   ├── WeeklySummaryViewModel.swift
│   ├── MuscleBalanceDiagnosisViewModel.swift
│   ├── MuscleHeatmapViewModel.swift
│   ├── MuscleJourneyViewModel.swift
│   └── StreakViewModel.swift
├── Views/
│   ├── Components/                # 共通コンポーネント（4ファイル）
│   │   ├── MiniMuscleMapView.swift
│   │   ├── MicroBodyMapView.swift
│   │   ├── ExerciseGifView.swift      # ExerciseGifSize: .gridCard=アニメーション(グリッド用), .card=静止画。アニメ必要なら.gridCard
│   │   └── ShareCardTemplate.swift
│   ├── Home/                      # ホーム画面（16ファイル）
│   │   ├── HomeView.swift
│   │   ├── HomeHelpers.swift          # HomeCoachMarkView + FreeWorkoutLimitBadge + goalLinkedCopy含む
│   │   ├── HomeStreakComponents.swift
│   │   ├── HomeNeglectedComponents.swift
│   │   ├── MuscleMapView.swift
│   │   ├── MusclePathData.swift
│   │   ├── StrengthMapView.swift      # [Pro] 筋力可視化マップ
│   │   ├── StrengthShareCard.swift    # Strength Mapシェアカード（@3x PNG生成）
│   │   ├── MenuPreviewSheet.swift     # メニュープレビュー（GIF+筋肉マップ+重量付き）
│   │   ├── AnalyticsMenuView.swift
│   │   ├── WeeklySummaryView.swift
│   │   ├── MuscleBalanceDiagnosisView.swift
│   │   ├── MuscleHeatmapView.swift
│   │   ├── MuscleJourneyView.swift
│   │   ├── ChallengeProgressBanner.swift
│   │   ├── WeeklyVolumeChart.swift        # NEW: 週間ボリュームバーチャート
│   │   └── RecoveryDetailView.swift       # NEW: フルスクリーン回復マップ
│   ├── Workout/                   # ワークアウト記録（13ファイル）
│   │   ├── WorkoutStartView.swift
│   │   ├── WorkoutIdleComponents.swift
│   │   ├── ActiveWorkoutComponents.swift
│   │   ├── SetInputComponents.swift
│   │   ├── WorkoutInputHelpers.swift
│   │   ├── WorkoutTimerComponents.swift
│   │   ├── RecordedSetsComponents.swift
│   │   ├── ExercisePickerView.swift
│   │   ├── ExercisePreviewSheet.swift
│   │   ├── WorkoutCompletionView.swift        # 完了画面本体
│   │   ├── WorkoutCompletionComponents.swift  # WorkoutShareCard（PR前回比表示）, StatBox, ShareSheet
│   │   ├── WorkoutCompletionSections.swift    # NextRecommendedDaySection, StrengthMapShareSection含む
│   │   ├── ShareMuscleMapView.swift           # シェアカード用静的筋肉マップ（mapHeight可変）
│   │   └── FullBodyConquestView.swift
│   ├── Exercise/                  # 種目辞典（3ファイル）
│   │   ├── ExerciseLibraryView.swift
│   │   ├── ExerciseDetailView.swift
│   │   └── ExerciseMuscleMapView.swift
│   ├── History/                   # 履歴（8ファイル）
│   │   ├── HistoryView.swift
│   │   ├── HistoryMapComponents.swift
│   │   ├── HistoryCalendarComponents.swift
│   │   ├── HistorySessionComponents.swift
│   │   ├── HistoryStatsComponents.swift
│   │   ├── MonthlyCalendarView.swift
│   │   ├── MuscleHistoryDetailSheet.swift
│   │   └── DayWorkoutDetailView.swift
│   ├── MuscleDetail/              # 部位詳細（2ファイル、2Dマップハイライト方式）
│   │   ├── MuscleDetailView.swift
│   │   └── Muscle3DView.swift
│   ├── Onboarding/                # オンボーディング（13ファイル）
│   │   ├── OnboardingView.swift           # フェーズ管理（Splash→V2→通知）
│   │   ├── OnboardingV2View.swift         # 最大9ページ横スワイプ + 専用カラーパレット
│   │   ├── SplashView.swift               # スプラッシュ（筋肉マップデモ + 日英タグライン）
│   │   ├── GoalSelectionPage.swift        # 7目標エモーショナル複数選択 + selectionOrder + OnboardingGoal enum
│   │   ├── FrequencySelectionPage.swift   # 週間頻度 + 超回復アニメーション
│   │   ├── LocationSelectionPage.swift    # 場所選択（ジム/自宅/自重のみ/両方 + GIF + 種目詳細）
│   │   ├── TrainingHistoryPage.swift      # ProfileInputPage（経験+体重+ニックネーム統合）
│   │   ├── PRInputPage.swift              # BIG3デフォルト表示 + PR入力（経験者のみ、マップ220pt）
│   │   ├── GoalMusclePreviewPage.swift    # 分割法プレビュー（現フローでは未使用）
│   │   ├── MenuGeneratingPage.swift      # メニュー生成アニメーション（Page 5）
│   │   ├── RoutineBuilderPage.swift       # 自動ルーティン構築（Day別location、→RoutineManager）
│   │   ├── RoutineCompletionPage.swift    # ルーティンサマリー + 成長グラフ + ハードペイウォール
│   │   ├── FavoriteExercisesPage.swift    # お気に入り種目選択（オンボーディングフローでは未使用）
│   │   └── NotificationPermissionView.swift  # 通知許可 + 筋肉マップ回復アニメーション
│   ├── Social/                    # ソーシャルフィード（Phase 0）
│   │   ├── ActivityFeedView.swift
│   │   └── FriendActivityCard.swift
│   ├── Settings/                  # 設定（3ファイル）
│   │   ├── SettingsView.swift
│   │   ├── RoutineEditView.swift      # ルーティン編集画面
│   │   └── CSVImportView.swift        # CSVデータインポート
│   └── Paywall/                   # Paywall（実装済み）
│       └── PaywallView.swift      # isHardPaywall パラメータ対応
├── Utilities/
│   ├── RecoveryCalculator.swift
│   ├── PRManager.swift            # 推定1RM（Epley式）+ PR前回比取得 + PRUpdate構造体
│   ├── PurchaseManager.swift      # isPremium判定 + weeklyWorkoutCount + canRecordWorkout
│   ├── StrengthScoreCalculator.swift  # PRデータ→筋肉スコア変換
│   ├── MenuSuggestionService.swift
│   ├── ColorCalculator.swift
│   ├── ColorExtensions.swift
│   ├── DateExtensions.swift
│   ├── HapticManager.swift
│   ├── ThemeManager.swift
│   ├── LocalizationManager.swift
│   ├── NotificationManager.swift  # ローカル通知管理
│   ├── GoalMusclePriority.swift   # 目標→重点筋肉マッピング
│   ├── CSVParser.swift            # CSVファイル解析
│   ├── ImportDataConverter.swift  # インポートデータ変換
│   ├── WorkoutRecommendationEngine.swift  # おすすめメニューエンジン
│   ├── WidgetDataProvider.swift
│   ├── LegalURL.swift
│   ├── AppConstants.swift
│   ├── KeyManager.swift
│   └── KeychainHelper.swift
└── Resources/
    ├── exercises.json             # 92種目
    ├── Assets.xcassets
    └── exercises_gif/             # folder reference（GIFアニメーション）

MuscleMapWatch/                    # Apple Watch companion
MuscleMapWidget/                   # Widget extension
Shared/                            # iOS/Watch共有コード
scripts/
└── screenshots/                   # App Storeスクショ自動生成パイプライン（準備中）
.claude/
└── commands/                      # CC用カスタムコマンド（screenshot, design-check, build-verify）
docs/
├── PRD/                           # 製品要件ドキュメント
├── DESIGN_SYSTEM.md               # UIデザイン原則v2.0
├── CC_LESSONS.md                  # CC自己改善ルール（蓄積された教訓）
├── audit/                         # 監査レポート（17レポート）
└── appstore/                      # App Store説明文・キーワード
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
- isPremiumがfalseの場合は`PaywallView`を`.sheet`で表示（ソフト）または`.fullScreenCover`で表示（ハード）
- `PaywallView(isHardPaywall: true)`: 閉じるボタン非表示 + `.interactiveDismissDisabled(true)`
- Pro機能をゲートする場所: ゲートA: HomeViewのStrengthMapボタン、ゲートB: ContentViewのワークアウトタブ tag:1（週間制限）、ゲートC: RoutineCompletionPage（オンボーディング）

### 多言語対応
- `LocalizationManager.shared.currentLanguage == .japanese` で日英切替
- L10nキー使用を推奨。インラインの場合は `isJapanese ? "日本語" : "English"` パターン

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

---

## App Store メタデータ

| 項目 | 日本語 | 英語 |
|:---|:---|:---|
| タイトル | MuscleMap - 筋肉回復マップで筋トレ管理 | MuscleMap: Recovery Tracker |
| サブタイトル | 超回復を可視化・トレーニング記録&メニュー提案 | Muscle Recovery Map & Tracker |

**価格:**
- 月額: ¥590（$4.99）— 7日間無料トライアル
- 年額: ¥4,900（$39.99）— 31%お得
- 買切り: なし

**メタデータ詳細:** `docs/app_store_metadata_final.md` 参照

---

## v1.0 ステータス & v1.1 ロードマップ

### v1.0（App Store提出準備完了）

- 全機能実装済み（5タブ + オンボーディング8ページ + Paywall）
- 287コミット
- 監査レポート17本完了
- ウィジェット: Small / Medium / Large 3サイズ対応
- Apple Watch: watchOS 10.0+ 対応

### v1.1 ロードマップ（既知の改善項目）

| 項目 | 説明 | 優先度 |
|:---|:---|:---|
| 初回ワークアウトガイド | 最初のワークアウト記録時のステップガイド追加 | P1 |
| コーチマーク強化 | ホーム画面以外（履歴・種目辞典）にもコーチマーク追加 | P2 |
| レビュー促進 | WorkoutSession 3回目以降で SKStoreReviewController 表示 | P1 |
| ソーシャル機能 Phase 1 | モックからリアルデータへの移行（Hevy対抗） | P3 |

---

## 兄弟リポジトリ運用

**MuscleMapをホームリポジトリとし、常にここからClaude Codeを起動する。**

| リポジトリ | パス | 用途 |
|:---|:---|:---|
| MuscleMap（本体） | `~/MuscleMap` | iOSアプリ開発。CC起動はここから |
| ShotFlow | `~/Developer/ShotFlow` | iOS撮影アプリ（Swift / SwiftUI） |
| MuscleMapContent | `~/Developer/MuscleMapContent` | Remotion動画生成（TypeScript） |

- `.claude/commands/shotflow.md` — ShotFlow操作用スキル（設定済み）
- `.claude/commands/remotion.md` — Remotion操作用スキル（設定済み）
- 各スキルから兄弟リポジトリのコードを直接読み書きする運用

---

## コンテンツパイプライン

### フロー

```
ShotFlow（iPhone撮影）
  → AirDrop で Mac へ
    → MuscleMapContent（Remotion レンダリング）
      → 3PF投稿（YouTube / TikTok / Instagram Reels）
```

### VO（ナレーション）対応

- VOなしで先にレンダリング → iPhoneで英語VO録音 → AirDrop → 再レンダリング
- VO音声は `current_day/dayXXX_vo.m4a` に配置。meta.jsonの `shots.vo.taken: true` で有効化
- VOあり時はBGMを自動ducking（音量上限0.15）。VOなし時は従来通り

### クリップカテゴリ

| カテゴリ | 説明 | 特殊効果 |
|:---|:---|:---|
| `food` | 食事・買い物 | — |
| `transit` | 移動シーン | アグレッシブスピードランプ（1.6x→0.4x→1.2x） |
| `gym` | トレーニング | スピードランプ（1.3x→0.5x→1.0x） |
| `weight` | 体重計測 | — |
| `app` | アプリ操作画面 | — |
| `other` | その他 | — |

- meta.jsonの各shotに `"category": "transit"` 等を付与
- デフォルトは時系列ソート。`"sort_by": "category"` でカテゴリ順（food→transit→gym→app→weight→other）

---

## 動画戦略（参考情報）

| 項目 | 値 |
|:---|:---|
| チャンネル名 | OGfromJapan |
| コンセプト | "Tokyo salaryman \| 85→75kg in 90 days \| Every yen documented" |
| ベスト実績 | Day 005: 970再生 |
| タイトルの勝ちパターン | 金額 + 食事 + 感情ワード（例: "I spent $26 eating Tokyo ramen & hit the gym"） |

- 1日1本のデイリーvlog（9:16縦動画、60秒以内）
- 支出・カロリー・トレーニングを全記録 → MuscleMap連携の差別化要素

---

## ShotFlow 最新機能

- **クイック撮影がメイン運用** — テンプレート（ShotDefinition）は現在未使用。クイック撮影 → 即AirDrop が主フロー
- **ファイル名任意化済み** — タイムスタンプベース自動命名。ShotFlowが `dayXXX_quick_NNN.mov` 形式で出力
- **買い物モード実装中** — 仕入れ（ビジネス経費）と日常支出の分離。cost_jpy のカテゴリ分け対応予定
