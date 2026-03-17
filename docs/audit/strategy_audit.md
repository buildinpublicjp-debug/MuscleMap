# 戦略監査レポート
日付: 2026-03-18
対象: MuscleMap v4.0 (iOS)
監査者: Claude Code (自動分析)

---

## エグゼクティブサマリー

| 項目 | 判定 | 備考 |
|:---|:---|:---|
| App Store審査 | **リスクあり** | 致命的2件（価格ハードコード、週間制限未実装）、中リスク3件 |
| 収益化戦略 | **要修正** | 無料→Pro転換のメカニズムが壊れている。価格は市場水準で適正 |
| 競合優位性 | **条件付き明確** | 回復マップ×ルーティンビルダーのコンボはユニーク。ただしデータ移行なし |
| リリース判断 | **条件付きGo** | 下記「3/22提出までのアクションアイテム」完了を前提に |

---

## A. ユーザージャーニー分析

### ペルソナ1: 初心者（トレ歴なし、目標「痩せたい」、自宅トレ）

**オンボーディング体験 (9ページ)**

フロー: Splash → 目標選択 → 頻度 → 場所(自宅) → トレ歴(初心者) → GoalMusclePreview → 体重入力 → RoutineBuilder → RoutineCompletion → 通知許可

- **良い点**: PR入力ページ(Page 4)は `trainingExperience == .beginner` でスキップされる（`OnboardingV2View.swift:11-13`, `shouldShowPRInput` による条件分岐確認済み）。初心者にBIG3のPRを聞かない設計は正しい。
- **良い点**: `RoutineBuilderPage.swift`でトレーニング場所が `"home"` の場合、バーベル・マシン・ケーブル種目が自動フィルタされ、自重・ダンベル・ケトルベルのみ提案される（`filterByLocation()` L310-322）。自宅トレ初心者に適切。
- **良い点**: ルーティンビルダーで種目が自動ピックされるため、「何をしたらいいかわからない」初心者が途方に暮れない。

**問題点:**

1. **オンボーディング長すぎ問題**: 9ページ + Splash + 通知許可 = 合計11画面。初心者は「筋トレアプリをちょっと試したい」だけなのに、完了まで3〜5分かかる。離脱率が高いポイント。
2. **ルーティンビルダーの認知負荷**: 初心者はPush/Pull/Legsの意味がわからない。`splitParts(for:)` のデフォルト3分割（`WorkoutRecommendationEngine.swift:208-213`）は "Push" / "Pull" / "Legs" と英語表記。初心者には不親切。
3. **RoutineCompletionPage(Page 8)のハードペイウォール**: `RoutineCompletionPage.swift:206` で `PaywallView(isHardPaywall: true)` を `.fullScreenCover` で表示。閉じるボタンなし、`interactiveDismissDisabled` 有効。ただし「無料ではじめる」ボタン（L159-166）があるため、完全なハードペイウォールではない。これはApple審査上問題ない。
4. **課金しなかった場合の体験**: `canRecordWorkout` は `isPremium || weeklyWorkoutCount < 1` で週1回制限のはず。しかし **`incrementWorkoutCount()` が一度も呼ばれていない**（後述「致命的バグ」参照）。結果として、無料ユーザーは無制限にワークアウトを記録でき、課金動機がゼロ。
5. **1ヶ月後に継続している理由**: 回復マップの色変化は視覚的に楽しいが、初心者は「痩せたい」のに体重変化を記録する機能がない。1ヶ月後に「痩せた実感」が得られないと離脱する。体組成トラッキングの欠如。

### ペルソナ2: 中級者（トレ歴1年+、目標「デカくなりたい」、ジム）

**オンボーディング体験:**

フロー: Splash → 目標(getBig) → 頻度 → 場所(gym) → トレ歴(oneYearPlus) → **PRInputPage** → GoalMusclePreview → 体重入力 → RoutineBuilder → RoutineCompletion → 通知許可

- **良い点**: PR入力ページ(Page 4)が表示され、BIG3（ベンチプレス・スクワット・デッドリフト）+ 最大3種目追加可能。入力するとリアルタイムでレベルバッジ（初心者/中級者/etc）が表示される（`PRInputPage.swift:132-149`）。これは「自分のレベルがわかる」という即座の価値提供。

**問題点:**

1. **Strength Mapに初回からデータが表示されるか**: `StrengthScoreCalculator.swift:234-239` で `initialPRs` をマージしている。オンボーディングでPR入力すれば、初回からStrength Mapにデータが表示される。**ただし、Strength MapはPro限定**（`HomeView.swift:125-128`）。無料ユーザーは自分のPRを入力したのに結果が見えない。フラストレーション。
2. **既にStrong/Hevyを使っている人が乗り換える理由**: データインポート機能がない。CSVインポートもAPI連携もない。既存ユーザーは過去の全記録を捨てる必要がある。これは致命的な乗り換え障壁。
3. **回復マップの価値を感じるまでの時間**: 最低でも2〜3回のワークアウトを記録する必要がある。初回は全部グレー。中級者は「で、これ何がいいの？」と思う。
4. **今日のおすすめメニュー**: `HomeView.swift:222-234` を見ると、ワークアウト履歴なし(`!hasWorkoutHistory`)の場合は `generateFirstTimeRecommendation` でフォールバック提案が出る。ただしPro限定の `MenuPreviewSheet` は回復データベースの提案のみ。初回ユーザーは簡易表示のみ。

### ペルソナ3: ベテラン（トレ歴3年+、目標「もっと強く」、ジム）

**問題点:**

1. **既存ルーティンの入力手間**: ルーティンビルダーは自動ピックで3〜4種目。ベテランは5〜6種目以上のルーティンを持っている。1日あたり最大8種目（`maxExercisesPerDay = 8`）なので追加は可能だが、全て手動で追加する必要がある。
2. **Strength Mapの筋力レベル判定の妥当性**: `StrengthScoreCalculator.swift` のカテゴリA（コンパウンド大筋群）の閾値を検証:
   - ratio 1.0（体重と同重量のベンチプレス）→ score 0.50 → レベル: Advanced（上級者）
   - ratio 1.25 → score 0.70 → レベル: Elite（エリート）
   - ratio 1.5以上 → score 0.85+ → レベル: Freak（怪物）
   - 体重70kgでベンチ1RM 105kg（ratio 1.5）→ Freak判定。実際には中上級者レベル。**判定が甘すぎる**。Strength Standards（https://symmetricstrength.com）基準では体重70kgのベンチ105kgは "Intermediate" 程度。
3. **92種目のカバレッジ**: ベテランがよく使うバリエーション種目（例: インクラインダンベルフライ、ケーブルクロスオーバー、レッグプレスのスタンスバリエーション等）が含まれているか要確認。92種目は競合と比較して少ない（Strong: 200+、JEFIT: 1400+）。

### ペルソナ4: 課金せずに無料で使い続けるユーザー

**致命的問題: 週1回制限が機能していない**

`PurchaseManager.swift:112` の `incrementWorkoutCount()` は定義されているが、アプリ全体で一度も呼び出されていない（Grepで確認済み）。`WorkoutCompletionView.swift` にも `WorkoutViewModel` にも呼び出しが存在しない。

**結果**: `weeklyWorkoutCount` は常に0のまま → `canRecordWorkout` は常に `true` → 無料ユーザーは無制限にワークアウトを記録可能。

**ビジネスインパクト**:
- 無料ユーザーが課金する動機がない
- 収益化モデル（フリーミアム）が完全に破綻
- 唯一のPro限定機能はStrength Mapだが、これだけでは月590円の価値を感じにくい

**アプリを削除する瞬間の予測:**
- 2〜3回ワークアウトを記録して「別にStrong/Hevyでよくない？」と思った時
- 回復マップだけでは「だからどうした」感があり、実際のトレーニングに影響しない場合
- 体の変化（写真、体重、サイズ）を記録できない場合

---

## B. App Store審査リスク分析

### 致命的リスク (P0: 修正必須)

#### B-1. 価格のハードコード（Guideline 3.1.2 違反リスク）

**場所**: `PaywallView.swift:252-258`

```swift
private var yearlyPriceText: String {
    "¥4,900/年（月¥408）"
}
private var monthlyPriceText: String {
    "¥590/月"
}
```

**問題**: 価格がハードコードされており、RevenueCatの `storeProduct.localizedPriceString` を使用していない。

- 日本以外のApp Storeでは表示価格と実際の請求額が異なる
- Apple審査員はUS Storeから審査するため、ドル建て価格が表示されるべき場所に円が表示される
- Guideline 3.1.2: "Subscriptions must show full pricing details before the user pays" — 地域によって間違った金額を表示するのは「full pricing details」の要件を満たさない

**リジェクトリスク**: **高** (2026年のAppleは価格表示に厳格)

#### B-2. 「7日間無料トライアル」表記の正確性

**場所**: `PaywallView.swift:212`
```swift
Text("7日間無料で始める")
```

**問題**: App Store Connect でProduct ID設定・審査が未完了（`CLAUDE.md:67` に「残作業: App Store Connect で Product ID 設定・審査」と明記）。つまりRevenueCatの `offering` が存在しない可能性がある。

- トライアル期間はApp Store Connect側の設定であり、アプリ側でハードコードすべきでない
- 実際にトライアルが設定されていない場合、即座に課金される → ユーザー苦情 + ガイドライン違反
- トライアルの有無は `storeProduct.introductoryDiscount` から動的に取得すべき

**リジェクトリスク**: **高**（虚偽広告と判定される可能性）

### 中リスク (P1: 修正推奨)

#### B-3. Paywall UIのローカライズ漏れ

**場所**: `PaywallView.swift` の複数箇所

以下の文字列が日本語ハードコードされており、`L10n` 経由になっていない:
- L133: `"あなた専用のプログラムを解放"` / `"あなた専用のメニューを毎日届ける"`
- L154: `"今日のメニュー例"`
- L184-186: `"種目・重量・セット数の自動提案"` / `"強さレベル & Strength Map"` / `"レベルアップまでの距離表示"`
- L291: `"購入によりApple IDに請求されます..."` (法的テキスト)
- L112: `"購入エラー"`
- L102: `"処理中..."`
- L281: `"購入を復元"`

7言語対応を謳うアプリで、最重要画面であるPaywallが日本語のみ。英語圏の審査員には意味不明。

**リジェクトリスク**: **中**（機能は動くが、UX品質の問題として指摘される可能性）

#### B-4. 「Coming Soon」機能の露出

**場所**: `SettingsView.swift:355`

設定画面の「ソーシャルフィード」に `"Coming Soon"` バッジが付いており、タップするとモックデータのフィードが表示される（`ActivityFeedView.swift`）。`feedComingSoon` メッセージ（`LocalizationManager.swift:1002`）で「現在モックデータで表示中」と表示。

**問題**: Guideline 2.1（App Completeness）— 未完成機能をリリースビルドに含めるのはリスク。ただし「Preview」表記があればグレーゾーン。

**リジェクトリスク**: **中**

#### B-5. フィードバックURLがGitHub Issues

**場所**: `SettingsView.swift:371`
```swift
URL(string: "https://github.com/buildinpublicjp-debug/MuscleMap/issues")
```

一般ユーザーがGitHub Issuesでフィードバックを送るのは非現実的。審査員が「サポート手段が不適切」と判断する可能性。

### 低リスク (P2: 改善推奨)

#### B-6. DEBUG コードの安全性

`PurchaseManager.swift:10-11`:
```swift
#if DEBUG
var debugOverridePremium: Bool? = true
#endif
```

`#if DEBUG` ブロック内のため、リリースビルドでは完全に除外される。**問題なし**。

全ての `#if DEBUG` ブロック（約70箇所）は `print()` 文または開発者メニュー（`SettingsView.swift:453-477`）のみ。リリースビルドへの影響はない。

#### B-7. 法的URL

4つのURL全てがHTTP 200を返すことを確認済み:
- `privacy-policy-ja.html` : 200 OK
- `privacy-policy-en.html` : 200 OK
- `terms-of-use-ja.html` : 200 OK
- `terms-of-use-en.html` : 200 OK

利用規約・プライバシーポリシーのリンクは `CallToActionPage.swift:134-148` と `RoutineCompletionPage.swift:170-184` に存在。**問題なし**。

#### B-8. 復元ボタン

`PaywallView.swift:263-286` に「購入を復元」ボタンが存在。`PurchaseManager.shared.restore()` を呼び出し、RevenueCatの `restorePurchases()` を実行。**Guideline 3.1.1 準拠**。

#### B-9. TODOコメント残留

`StrengthScoreCalculator.swift:219`:
```swift
// TODO: heightCmを使ったBMI表示、体格補正付きスコア
```

コメントのみでリリースに影響なし。**問題なし**。

---

## C. 収益化戦略分析

### C-1. 価格設定の競合比較

| アプリ | 月額 | 年額 | 年額月換算 | 無料トライアル | ライフタイム |
|:---|:---|:---|:---|:---|:---|
| **MuscleMap** | ¥590 (~$3.90) | ¥4,900 (~$32.50) | ¥408 (~$2.70) | 7日間（未設定） | なし |
| Strong | $4.99 (~¥750) | $29.99 (~¥4,500) | $2.50 (~¥375) | なし | $99.99 |
| Hevy | $8.99 (~¥1,350) | $59.99 (~¥9,000) | $5.00 (~¥750) | なし | $99 |
| JEFIT | $6.99-12.99 | $39.99-69.99 | - | なし | なし |
| Fitbod | $15.99 (~¥2,400) | $95.99 (~¥14,400) | $8.00 (~¥1,200) | 7日間 | プロモのみ |
| Nike TC | 無料 | 無料 | 無料 | - | - |

**分析**:
- MuscleMapの月額¥590は市場最安クラス。Strongの月額$4.99と比較して約30%安い。
- 年額¥4,900はStrongの$29.99（約¥4,500）とほぼ同水準。
- **問題**: 安すぎて「安かろう悪かろう」のイメージを持たれるリスク。一方で、日本のフィットネスアプリ市場では妥当な価格帯。
- 月額→年額の割引率: 月額¥590×12=¥7,080 → 年額¥4,900で31%オフ。業界標準は30-50%オフ。適正範囲内。

### C-2. ペイウォールの位置と設計

**現在の設計**:
1. オンボーディング最終ページ（RoutineCompletionPage）でソフトペイウォール
   - 「Pro版を解放」ボタン → `PaywallView(isHardPaywall: true)` をfullScreenCoverで表示
   - ただし「無料ではじめる」ボタンが常に表示されているため、実質ソフトペイウォール
2. ワークアウトタブ遷移時に週間制限チェック（`ContentView.swift:57`）→ ただし制限が機能していない（前述）
3. StrengthMap表示時にPro判定（`HomeView.swift:125-128`）
4. ワークアウト完了画面で非Pro向けバナー（`WorkoutCompletionView.swift:212-215`）
5. 設定画面にProアップグレード導線（`SettingsView.swift:27-29, 145-167`）

**評価**:
- ペイウォールの位置（オンボーディング最後）は適切。ユーザーは目標設定・ルーティン作成を通じてアプリに投資した後に課金提案を受ける。サンクコスト効果を活用。
- 問題は「無料ではじめる」で通過した後、再度課金を促す仕組みが弱い。Strength Mapのロックだけでは不十分。

### C-3. 無料→Pro転換率の予測

**現状の転換メカニズム（設計 vs 実装）:**

| 設計上のメカニズム | 実装状態 | 効果 |
|:---|:---|:---|
| 週1回制限に達する → Paywall | **未実装**（incrementWorkoutCount未呼出） | 無効 |
| StrengthMapを見たい → Paywall | 実装済み | 弱（存在を知らないと価値不明） |
| メニュー提案のフル表示 | 実装済み（Pro限定） | 中（無料でもフォールバック提案あり） |
| 完了画面のProバナー | 実装済み | 弱（バナー疲れ） |

**予測転換率**: 1-3%（業界平均5-10%に対して大幅に低い）

**チャーンリスクの高い瞬間**:
1. オンボーディング完了直後（「無料ではじめる」→ 何をしていいかわからない）
2. 3回目のワークアウト後（回復マップが見えてきたが「で、次は？」となる）
3. 2週間後（新鮮味が薄れ、Strong/Hevyとの機能差を感じる）

### C-4. 収益化改善提案

**優先度順:**

1. **[P0] `incrementWorkoutCount()` の呼び出しを実装**: `WorkoutCompletionView.swift` の `markFirstWorkoutCompleted()` 内またはワークアウト完了フローで呼び出す。これがないと収益化モデルが成立しない。

2. **[P0] PaywallView の価格をRevenueCat動的取得に変更**: `storeProduct.localizedPriceString` を使用。ハードコード価格を削除。

3. **[P1] 週1回制限の緩和を検討**: 週1回は厳しすぎる可能性。週2回にすると「もう1回やりたいのに...」のフラストレーションが適度に発生し、課金動機になる。週1回だと「もう今週は使えない」→ アプリ削除の可能性。

4. **[P1] 2回目のワークアウト完了後にPaywallリマインダー**: 回復マップのデータが溜まったタイミングで「Proなら最適なメニューが自動生成される」と訴求。

5. **[P2] ライフタイムプランの検討**: Strong ($99.99) とHevy ($99) が提供。日本市場では ¥9,800-¥14,800 程度。長期的にはARPU向上。

---

## D. 競合優位性分析

### D-1. 機能比較表

| 機能 | MuscleMap | Strong | Hevy | JEFIT | Fitbod | Nike TC |
|:---|:---|:---|:---|:---|:---|:---|
| 回復マップ（筋肉別色分け） | **独自（21筋肉SVG）** | なし | なし | テキストのみ | ヒートマップ（%表示） | なし |
| ルーティンビルダー | あり（オンボーディング統合） | あり（3ルーティン無料） | あり（4ルーティン無料） | あり | AIが自動生成 | プリセットのみ |
| メニュー自動提案 | あり（回復データベース） | なし | なし | AIあり（NSPI） | AIあり（主力機能） | プリセットのみ |
| PR追跡 | あり（Epley式1RM） | あり | あり | あり | あり | なし |
| SNSシェアカード | **あり（2種類、デザイン済み）** | なし | あり（基本的） | なし | なし | なし |
| Apple Watch | あり（watchOS 10+） | あり | あり | あり | あり | あり |
| 種目数 | 92 | 200+ | 300+ | 1,400+ | 1,000+ | 185+ |
| GIF/動画ガイド | あり（92種目GIF） | なし | なし | あり（アニメーション） | あり | あり（動画） |
| データインポート | **なし** | CSVあり | CSVあり | あり | あり | なし |
| 多言語 | 7言語 | 10言語+ | 17言語 | 多言語 | 多言語 | 多言語 |
| オフライン | あり（SwiftData） | あり | あり | あり | 制限あり | ダウンロード必要 |
| 月額価格 | ¥590 | $4.99 | $8.99 | $6.99+ | $15.99 | 無料 |

### D-2. MuscleMapにしかない機能（差別化ポイント）

1. **回復マップ + メニュー自動提案の連動**: Fitbodもヒートマップはあるが、MuscleMapの21筋肉SVGは視覚的インパクトが圧倒的に高い。「筋肉の状態が見える。だから、迷わない。」というコンセプトの具現化。
2. **Strength Map（筋力の太さ可視化）**: PRデータから筋肉の太さを変える表現は他にない。SNS映えの潜在力がある。
3. **ワークアウトシェアカード（2種類の高品質デザイン）**: 1080x1920px と 1080x1080px の2フォーマット。PR更新時のゴールド強調、ウォーターマーク付き。競合のシェア機能は簡素。
4. **ルーティンビルダーのオンボーディング統合**: 目標選択→場所→頻度→ルーティン自動生成が一気通貫。競合は別途手動設定。
5. **7日以上未刺激の紫点滅警告**: 「サボってる筋肉」が視覚的にわかる。罪悪感をUXで活用する独自アプローチ。

### D-3. 競合に負けている機能（弱点）

1. **種目数: 92 vs 200〜1,400+**: 圧倒的に少ない。中級者以上は自分の種目が見つからない可能性。
2. **データインポート: なし**: Strong/Hevyからの乗り換え障壁。過去の記録を全て捨てる必要がある。
3. **プログレッシブオーバーロードの自動追跡**: JEFITのNSPIやFitbodのAIのような高度な進捗分析がない。
4. **コミュニティ機能**: Hevyはフォロー/フォロワー、ワークアウト共有が充実。MuscleMapは「Coming Soon」。
5. **カスタム種目の追加**: ユーザーが独自種目を登録できる機能が見当たらない。92種目に含まれない種目を使う人は困る。
6. **ライフタイムプラン**: Strong/Hevyは提供。サブスク疲れの市場では重要な選択肢。

### D-4. ポジショニングマップ

```
                        高機能
                          |
                    Fitbod ($15.99)
                          |
              JEFIT ($6.99+)
                          |
                  Hevy ($8.99)
       低価格 ----+----MuscleMap (¥590)----+---- 高価格
                  |        Strong ($4.99)
                  |
            Nike TC (無料)
                  |
                        低機能
```

MuscleMapは「低〜中価格 × 中機能 + ユニークな可視化」のポジション。
最大の競合はStrong（似た価格帯で機能が豊富）とFitbod（回復追跡の先駆者だが高額）。

---

## 3/22提出までのアクションアイテム

### 必須 (これがないとリリース不可)

| # | タスク | 影響 | 工数見積 |
|:---|:---|:---|:---|
| 1 | **`incrementWorkoutCount()` の呼び出し実装** | 収益化モデル崩壊 | 0.5h |
| 2 | **PaywallView の価格をRevenueCat動的取得に変更** | 審査リジェクト + 海外ユーザーに不正確な価格表示 | 2-3h |
| 3 | **App Store Connectで Product ID 設定・審査提出** | 課金が一切機能しない | 1-2h (+ Apple側の審査待ち) |
| 4 | **「7日間無料トライアル」の表記を動的に取得** (`introductoryDiscount` 参照) | 審査リジェクト | 1h |

### 強く推奨 (リリース品質に直結)

| # | タスク | 影響 | 工数見積 |
|:---|:---|:---|:---|
| 5 | PaywallView のUI文字列をL10nに移行 | 英語圏の審査員にPaywallが理解不能 | 2h |
| 6 | PaywallView の法的テキストをローカライズ + 自動更新の解約方法を明記 | 2026年のAppleは解約情報の明記に厳格 | 1h |
| 7 | 「ソーシャルフィード」の「Coming Soon」をリリースビルドから除外、または設定画面から非表示に | Guideline 2.1リスク | 0.5h |
| 8 | フィードバックURLをGitHubからメールアドレスに変更 | 審査員の心証 | 0.5h |

### 推奨 (リリース後1週間以内)

| # | タスク | 影響 | 工数見積 |
|:---|:---|:---|:---|
| 9 | 初心者向け分割法の日本語表記（Push→「胸・肩」等） | 初心者離脱率 | 1h |
| 10 | Strength Mapの閾値テーブルを実際のStrength Standardsに合わせて再調整 | ベテランの信頼性 | 3h |
| 11 | CSVデータインポート機能（Strong/Hevy互換） | 乗り換えユーザー獲得 | 8-16h |
| 12 | カスタム種目の追加機能 | 92種目にない種目への対応 | 4-8h |

---

## 付録: コード根拠

本レポートで参照した主要ファイルの絶対パス:

- `/Users/og3939397/MuscleMap/CLAUDE.md` — プロジェクト全仕様
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Onboarding/OnboardingV2View.swift` — オンボーディングフロー制御
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Onboarding/TrainingHistoryPage.swift` — トレ歴選択
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Onboarding/PRInputPage.swift` — PR入力（経験者のみ）
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Onboarding/RoutineBuilderPage.swift` — ルーティンビルダー
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Onboarding/RoutineCompletionPage.swift` — ルーティン完了+ペイウォール
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Onboarding/CallToActionPage.swift` — CTA（旧最終ページ）
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Paywall/PaywallView.swift` — ペイウォール本体
- `/Users/og3939397/MuscleMap/MuscleMap/Utilities/PurchaseManager.swift` — 課金管理（incrementWorkoutCount未呼出の問題箇所）
- `/Users/og3939397/MuscleMap/MuscleMap/Utilities/StrengthScoreCalculator.swift` — 筋力スコア計算
- `/Users/og3939397/MuscleMap/MuscleMap/Utilities/WorkoutRecommendationEngine.swift` — メニュー提案エンジン
- `/Users/og3939397/MuscleMap/MuscleMap/Utilities/LegalURL.swift` — 法的URL定義
- `/Users/og3939397/MuscleMap/MuscleMap/App/ContentView.swift` — ルートビュー（週間制限チェック箇所）
- `/Users/og3939397/MuscleMap/MuscleMap/App/AppState.swift` — アプリ状態管理
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Home/HomeView.swift` — ホーム画面
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Home/StrengthMapView.swift` — Strength Map表示
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Workout/WorkoutCompletionView.swift` — ワークアウト完了画面
- `/Users/og3939397/MuscleMap/MuscleMap/Views/Settings/SettingsView.swift` — 設定画面
