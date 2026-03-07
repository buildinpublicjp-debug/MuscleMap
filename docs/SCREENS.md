# MuscleMap — 画面設計ドキュメント

> **目的:** 各画面が「なぜ存在するか」「ユーザーがその画面を開いた時の感情・文脈」を言語化する。
> 新画面の実装・既存画面の修正時に必ず参照すること。
> UI実装の判断基準はCLAUDE.mdのUIデザイン原則を参照。
> 画面遷移の条件・トリガー詳細は `SCREEN_FLOWS.md` を参照。

---

## 画面一覧

| 画面 | ファイル | 種別 | Pro? |
|:--|:--|:--|:--|
| オンボーディング（Splash + 4ページ + 通知） | Views/Onboarding/ | fullScreen | - |
| ホーム（回復マップ） | Views/Home/HomeView.swift | Tab 0 | 無料 |
| ホーム（Strength Map） | Views/Home/StrengthMapView.swift | Tab 0内 | **Pro** |
| Strength Mapシェアカード | Views/Home/StrengthShareCard.swift | sheet | **Pro** |
| 分析メニュー | Views/Home/AnalyticsMenuView.swift | sheet | 将来Pro |
| 週次サマリー | Views/Home/WeeklySummaryView.swift | sheet | 将来Pro |
| バランス診断 | Views/Home/MuscleBalanceDiagnosis... | sheet | 将来Pro |
| 筋肉ジャーニー | Views/Home/MuscleJourneyView.swift | sheet | 将来Pro |
| ヒートマップ | Views/Home/MuscleHeatmapView.swift | sheet | 将来Pro |
| ワークアウト開始 | Views/Workout/WorkoutStartView.swift | Tab 1 | 無料 |
| ワークアウト実行中 | Views/Workout/ | fullScreenCover | 無料 |
| PR祝福モーダル | （Workout内） | overlay | 無料 |
| ワークアウト完了 | Views/Workout/WorkoutCompletionView.swift | 画面内 | 無料 |
| Workoutシェアカード | Views/Workout/WorkoutCompletionComponents.swift | ImageRenderer | 無料 |
| 種目辞典 | Views/Exercise/ | Tab 2 | 無料 |
| 種目詳細 | Views/Exercise/ | sheet | 無料 |
| 履歴（マップ） | Views/History/ | Tab 3 | 無料 |
| 履歴（カレンダー） | Views/History/ | Tab 3内 | 無料 |
| 部位詳細（halfModal） | Views/History/ + MuscleDetail/ | halfModal | 無料 |
| 3D部位詳細 | Views/MuscleDetail/ | push | 無料 |
| 設定 | Views/Settings/ | Tab 4 | 無料 |
| ホーム（コーチマーク） | Views/Home/HomeHelpers.swift | overlay | 無料 |
| Paywall | Views/Paywall/PaywallView.swift | sheet | - |

---

## 各画面の詳細

---

### オンボーディング（Splash + 4ページ + 通知許可）

**ファイル:** `Views/Onboarding/`（9ファイル）

**存在理由:**
アプリを初めて開いた人に「これは普通のトレーニングアプリではない」と気づかせる30秒。
ここで離脱させると二度と戻らない。

**ユーザーの感情推移:**
1. 「おっ、かっこいい」（SplashViewのアニメーションで第一印象を掴む）
2. 「筋肉マップ？見たことない」（InteractiveDemoPageで興味）
3. 「自分の目標に合わせてくれるのか」（PersonalizationPageで参加意識）
4. 「体重とニックネームを入れる…パーソナライズされてる感」（WeightInputPage）
5. 「機能が充実してる。使ってみよう」（CallToActionPageで完了）

**フロー（OnboardingView がフェーズ管理）:**
```
OnboardingPhase.splash → SplashView
    ↓ (onComplete)
OnboardingPhase.mainFlow → OnboardingV2View（4ページ TabView）
  Page 0: InteractiveDemoPage    — 筋肉をタップして光らせる体験
  Page 1: PersonalizationPage    — 4つの目標から選択 → UserProfile.trainingGoal
  Page 2: WeightInputPage        — 体重（40-160kg, kg/lb切替）+ ニックネーム → UserProfile
  Page 3: CallToActionPage       — 3機能紹介 + Strength Map予告 + CTA「無料ではじめる」
    ↓ (onComplete)
OnboardingPhase.notification → NotificationPermissionView
    ↓ (onComplete)
アプリ本体へ（ContentView）
```

**SplashView:**
- アニメーションタイムライン: ロゴ(0-0.8s) → サブコピー(0.6s) → 筋肉マップデモ(0.5s) → グロー(1.0s) → タグライン(1.5s) → 続行ボタン(2.5s)
- `SplashMuscleMapDemo`: 前面6筋肉→背面4筋肉を順次点灯（0.3s間隔）

**PersonalizationPage:**
- 4目標: 筋肥大(muscleGrowth) / 筋力(strength) / 回復(recovery) / 健康(health)
- OnboardingGoal → TrainingGoal マッピング: muscleGrowth→hypertrophy, strength→strength, recovery→diet, health→health
- 選択時: スプリングアニメーション + `AppState.shared.userProfile.trainingGoal` に保存

**WeightInputPage:**
- ニックネームTextField + ドラムロールPicker（40-160kg, kg/lb切替）
- `AppState.shared.userProfile.weightKg` / `.nickname` にリアルタイム保存
- 次へボタンは常に有効（スキップ可能な設計）

**CallToActionPage:**
- 3機能カード（staggered fade-in, 0.15s間隔）+ Strength Map予告バッジ
- CTA「無料ではじめる」: グラデーション背景 + グローアニメーション
- 利用規約 / プライバシーポリシーリンク付き

**カラーパレット（オンボーディング専用、OnboardingV2View.swift で定義）:**
| 用途 | コード | Hex |
|:--|:--|:--|
| アクセント | `.mmOnboardingAccent` | `#00E676` |
| アクセント暗 | `.mmOnboardingAccentDark` | `#00B35F` |
| 背景 | `.mmOnboardingBg` | `#1A1A1E` |
| カード | `.mmOnboardingCard` | `#2C2C2E` |
| テキスト主 | `.mmOnboardingTextMain` | white @ 90% |
| テキスト副 | `.mmOnboardingTextSub` | `#8E8E93` |

**絶対条件:**
- インタラクティブデモ（筋肉をタップして光る）を必ず含める
- プログレスインジケーター（4つのカプセル、現在ページ=幅20pt、他=8pt）
- 最後の「始める」タップ後はアニメーションで本体へ移行
- 体重・ニックネーム入力はスキップ可能（次へボタン常に有効）

**NGパターン:**
- テキストだけのスライドが3枚以上続く（見飽きる）
- 全項目を入力必須にする（離脱の原因）

---

### ホーム（Tab 0）— 回復マップモード（無料）

**ファイル:** `Views/Home/HomeView.swift` とその配下

**存在理由:**
ジムに着いた瞬間に開く画面。「今日どこ鍛えればいい？」への即答が唯一の使命。

**ユーザーの感情・文脈:**
- ロッカーでウェアに着替えながらスマホを開く（時間的プレッシャーあり）
- 「腕昨日やったっけ？まだ痛い？」という記憶の曖昧さを解消したい
- 「よし今日は背中で行こう」という決断を3秒以内にしたい

**画面構成（上から順に）:**
1. ストリーク（連続記録日数）— モチベーション維持
2. 回復マップ / Strength Map 切替ボタン
3. 筋肉マップ（全身）— 色で回復状態を即判断
4. 今日のおすすめメニュー — スクロールなしで見える
5. 分析ボタン（シート表示）

**色の読み方:**
- 緑 = 回復済み（鍛えどき）
- 黄 = 回復中
- 赤 = 疲労中（まだ早い）
- 紫点滅 = 7日以上放置（警告）
- グレー = 記録なし

**絶対条件:**
- 人体図は頭から足先まで完全表示（切れ禁止）
- 「今日のおすすめ」はスクロールなしで見える
- 3秒以内に「今日やること」が理解できる

---

### ホーム（Tab 0）— Strength Mapモード（Pro）

**ファイル:** `Views/Home/StrengthMapView.swift`

**存在理由:**
「今日どこ鍛えるか」の判断ツールではなく、「自分の筋力アイデンティティ」の可視化。
PRデータが蓄積するほど価値が高まる。

**ユーザーの感情・文脈:**
- トレーニング後にPRを更新した → 「Strength Map見たい」
- 「自分のフィジカルカードをXに貼りたい」
- 「脚弱いのが数字で見えてきた。次は脚の日増やそう」

**表示ロジック:**
- 太さ = PRの強さ（推定1RM ÷ 体重でスコア化）
- 初期は全部細い → 「育てたい」欲求を生む設計
- PRを更新するたびリアルタイムで太さが変わる

**シェアカード:**
- 長押し or シェアボタンで書き出せる
- 「自分の筋力アイデンティティカード」としてXで使えるビジュアル
- 0.2秒で「こいつベンチ強い」「脚細い」がわかるデザイン

**絶対条件:**
- 未記録の筋肉は細く薄く（ネガティブではなく「未開拓」の表現）
- スコア0の筋肉にも「記録すると発達が見える」のヒントを添える
- Pro未加入時はロックオーバーレイ + PaywallへのCTA

---

### ワークアウト開始（Tab 1）

**ファイル:** `Views/Workout/WorkoutStartView.swift`

**存在理由:**
「今日のメニューが決まった。記録を始めたい」という状態で来る画面。
最小タップでセッションを開始させる。

**ユーザーの感情・文脈:**
- すでにトレーニングを始めようとしている（行動意欲MAXの状態）
- 「前回のメニューをそのまま再現したい」か「種目を変えたい」かを素早く選びたい
- 前回の記録が見えると「前回75kgだった。今日は77.5kgで行こう」と判断できる

**絶対条件:**
- 「前回のメニューを続ける」が最も目立つCTA
- 種目選択まで3タップ以内
- ローディングや余計なアニメーションで行動を止めない

---

### ワークアウト実行中（fullScreenCover）

**ファイル:** `Views/Workout/` 配下の実行系ファイル

**存在理由:**
セットを1つ1つ記録する。数字を入力することだけに集中させる画面。

**ユーザーの感情・文脈:**
- 筋肉が張っている。汗をかいている。
- 「早く次のセットに行きたい」—— 余計なUIは全て邪魔
- レストタイマー中は「次のセットの重量を考えている」
- PR更新が起きた瞬間は高揚感MAX

**インタラクションフロー:**
```
重量入力 → レップ数入力 → セット完了ボタン
  ↓
Haptic (medium) + チェックアニメーション
  ↓
[PR更新時] 紙吹雪 + Haptic (heavy) + 祝福モーダル
  ↓
レストタイマー開始（カウントダウン）
  ↓
次のセットへ
```

**絶対条件:**
- セット完了は1タップ
- 前回の重量・レップ数が常に見える
- タイマーはカウントダウン形式（残り時間が見える）
- ワークアウト終了ボタンは誤タップしにくい位置

---

### PR祝福モーダル（overlay）

**ファイル:** ワークアウト実行中View内

**存在理由:**
PR更新という「特別な瞬間」に感情的なピークを作る。
この体験がアプリへの愛着と継続のカギ。

**ユーザーの感情・文脈:**
- 「え、PR出た？」という驚き
- 「やった、記録した」という達成感
- 「これXに投げたい」という衝動

**絶対条件:**
- 紙吹雪アニメーション + Haptic (heavy) は必須（省略禁止）
- 新旧PRの数値を並べて「◯kg → ◯kg」で差分を見せる
- シェアボタンを目立つ位置に
- 「次のセットへ」で素早く閉じられる

---

### ワークアウト完了

**ファイル:** `Views/Workout/WorkoutCompletionView.swift`

**存在理由:**
「お疲れ様」の体験。今日の成果をビジュアルで伝え、達成感の記憶を作る。
次回のモチベーションに直結する最後の画面。

**ユーザーの感情・文脈:**
- 達成感と疲労感が混在（疲れているが満足している）
- 「今日どんなセッションだったか」を数字で確認したい
- 「シェアしよう」という衝動が一番高まっている瞬間

**表示内容:**
- 刺激した筋肉をミニ人体図でハイライト（前面・背面）
- 合計ボリューム・種目数・セット数・所要時間（CompletionStatsCard）
- 次回おすすめ日（NextRecommendedDaySection）
- PR更新時: Strength Mapシェア導線（StrengthMapShareSection）
- 完了種目リスト（CompletionExerciseList）
- シェアボタン（Instagram Stories / その他）

**サブセクション詳細:**

#### 次回おすすめ日（NextRecommendedDaySection）
- **ファイル:** `Views/Workout/WorkoutCompletionSections.swift`
- **ロジック:** 今回刺激した全筋肉に対して `RecoveryCalculator.adjustedRecoveryHours` を計算し、最も回復が遅い部位の完全回復日を推奨日として表示
- **表示:** 日付を大きく表示 + 「回復予測に基づく」の補足テキスト
- **日付フォーマット:** 当日→「今日」、翌日→「明日」、それ以降→「3月10日（月）」形式

#### Strength Mapシェア導線（StrengthMapShareSection）
- **ファイル:** `Views/Workout/WorkoutCompletionSections.swift`
- **表示条件:** `hasPRUpdate == true`（今回のセッションでPR更新があった場合のみ）
- **動作:** タップで `StrengthShareCard` を @3x PNG（1080×1920px）としてレンダリングし、ShareSheetを表示
- **デザイン:** アイコン + 「PR更新！」バッジ + 「Strength Mapをシェア」テキスト + シェアアイコン

**絶対条件:**
- 筋肉マップで「今日鍛えたところ」が視覚的に伝わる
- ホームに戻るボタンが明確

---

### Workoutシェアカード（ImageRenderer）

**ファイル:** `Views/Workout/WorkoutCompletionComponents.swift`（`WorkoutShareCard`）

**存在理由:**
ワークアウト完了直後の「今日これだけやった」を1枚の画像にして、InstagramやXに投稿できるカード。
PR更新があれば前回比を表示し、達成感を最大化する。

**ユーザーの感情・文脈:**
- ワークアウト直後の達成感（「今日のトレ報告したい」）
- PR更新時は「記録更新を見せたい」欲求が高い
- シンプルかつインパクトのある画像が欲しい

**カード構成（390×693pt → @3x 1170×2079px PNG）:**
1. **上部グラデーションライン（4pt）:** mmAccentPrimary → mmAccentSecondary
2. **ヘッダー:** 「MuscleMap」左 + 日付（yyyy/MM/dd）右
3. **タイトル:** 「WORKOUT COMPLETE」（13pt heavy, tracking: 2, mmAccentPrimary）
4. **筋肉図（210pt）:** 前面・背面を並列（`ShareMuscleMapView(mapHeight: 210)`）。今回刺激した部位を3段階色分け
5. **メインスタット:** ボリューム数値（48pt heavy, mmAccentPrimary） + 「kg」（18pt） + 「TOTAL VOLUME」ラベル
6. **PR更新セクション（条件付き）:**
   - PR更新があれば最大2件表示
   - 「種目名  90kg → 100kg  ↑11%」形式
   - `PRManager.getSessionPRUpdates()` でデータ取得
   - PR無しの場合はセクション非表示
   - 背景: mmAccentPrimary @ 6% opacity、角丸12pt
7. **サブスタット:** 種目数・セット数を横並び（divider付き、22pt bold）
8. **フッター:** 「MuscleMap」ロゴのみ（12pt, secondary @ 50%）

**カラースキーム:** システム設定準拠（`.environment(\.colorScheme, .dark)` は使わない）

**データ型:**
```swift
struct SharePRItem {
    let exerciseName: String     // ローカライズ済み種目名
    let previousWeight: Double   // 前回PR重量
    let newWeight: Double        // 今回の新PR重量
    let increasePercent: Int     // 増加率%
}
```

**トリガー:** ワークアウト完了画面のシェアボタン → `prepareShareImage()` → Instagram Stories or ShareSheet

---

### Strength Mapシェアカード（sheet）

**ファイル:** `Views/Home/StrengthShareCard.swift`

**存在理由:**
「自分の筋力アイデンティティカード」をSNSでシェアするための画像生成View。
Xへの投稿で「0.2秒でこいつやばい」とわかるデザイン。

**ユーザーの感情・文脈:**
- PR更新直後の高揚感（「これ見せたい」）
- 筋力の偏りや強みを可視化して自慢したい

**カード構成（360×640pt → @3x 1080×1920px）:**
- **ヘッダー（56pt）:** MuscleMapロゴ + 日付
- **人体図エリア（340pt）:** 前面・背面の筋肉マップ（スコアに応じたstrokeWidth/opacity/color）+ グリッド装飾
- **ランキング（140pt）:** STRENGTH RANKING — スコア上位3筋肉をメダル(🥇🥈🥉)+バー+%表示
- **フッター（64pt）:** ユーザー名 + Overall Gradeバッジ

**グレード体系:**
| グレード | 平均スコア | カラー |
|:--|:--|:--|
| S | 0.85+ | mmAccentPrimary |
| A+ | 0.70+ | #00CC8F |
| A | 0.55+ | mmAccentSecondary |
| B+ | 0.40+ | mmMuscleRecovered |
| B | 0.30+ | mmMuscleModerate |
| C | 0.20+ | mmTextSecondary |
| D | 0.20未満 | #808080 |

**トリガー:**
- ワークアウト完了画面でPR更新時に表示されるStrengthMapShareSectionからの呼び出し
- StrengthMapView内のシェアボタンからの呼び出し

---

### ホーム — コーチマーク（HomeCoachMarkView）

**ファイル:** `Views/Home/HomeHelpers.swift`

**存在理由:**
初めてアプリを起動したユーザーに「まずワークアウトを記録しよう」と次のアクションを導く。
何もデータがない状態で筋肉マップを見ても意味がわからないため。

**ユーザーの感情・文脈:**
- オンボーディング直後の「で、何すればいい？」状態
- 空のマップを見て戸惑っている

**表示条件:**
- `AppState.hasSeenHomeCoachMark == false`（初回のみ）
- WorkoutSetが0件

**デザイン:**
- アクセントカラーのカプセルバッジ「まずワークアウトを記録しよう 👆」
- 下矢印アイコンが上下にアニメーション（repeatForever）
- タップで閉じ、`AppState.hasSeenHomeCoachMark = true` に設定

---

### 種目辞典（Tab 2）

**ファイル:** `Views/Exercise/`

**存在理由:**
「この種目どこに効く？」「肩を鍛える種目は？」に答える辞典。
緊急性は低く、マンネリ解消・フォーム確認の用途。

**ユーザーの感情・文脈:**
- 「最近同じ種目ばかりで飽きてきた」（マンネリ打破）
- 「この種目、フォームが合ってるか不安」（フォーム確認）
- 「肩の日に何を入れるか考えたい」（メニュー設計）

**画面構成:**
- 部位フィルター（上部タブ or チップ）
- 種目一覧（GIFサムネ + 名称 + 主要筋肉）
- 種目詳細（sheet）→ フルGIF + ミニ人体図 + 説明

**絶対条件:**
- 各種目にGIFアニメーション（正しいフォームが直感的にわかる）
- 刺激する筋肉をミニ人体図でハイライト
- テキストのみの行は禁止

---

### 種目詳細（sheet）

**ファイル:** `Views/Exercise/` 配下

**存在理由:**
種目辞典から「この種目をもっと詳しく知りたい」で来る画面。

**ユーザーの感情・文脈:**
- 「フォームを確認したい」
- 「どの筋肉に効くか地図で見たい」
- 「自分のPRはどのくらいか見たい」（将来機能）

**表示内容:**
- フルサイズGIF（画面上部1/3以上）
- ミニ人体図（刺激筋肉ハイライト）
- 動作説明（日本語）
- 関連種目

---

### 履歴（Tab 3）— マップ表示

**ファイル:** `Views/History/`

**存在理由:**
「最近バランスよく鍛えられてるか？」の視覚的確認。週単位の振り返り。

**ユーザーの感情・文脈:**
- トレーニング後または就寝前
- 「胸ばっかりで背中サボってたな」という気づきを得たい
- 「この部位、先週何の種目でやったっけ？」の記憶補完

**インタラクション:**
- 期間フィルター（1週間 / 1ヶ月 / 3ヶ月）
- 筋肉をタップ → 部位詳細ハーフモーダル

**絶対条件:**
- 人体図はホーム画面と同じ品質（切れ禁止）
- 刺激回数に応じて筋肉の色が変わる（多=濃い、少=薄い）

---

### 履歴（Tab 3）— カレンダー表示

**ファイル:** `Views/History/`

**存在理由:**
「いつ行った？」「今週何回行けた？」の確認。継続実感を与える。

**ユーザーの感情・文脈:**
- 「今月何回行けたか見たい」（習慣の確認）
- 「先週のトレーニングを振り返りたい」

**絶対条件:**
- トレーニングした日が色付きで目立つ
- ストリーク（連続日数）が見える
- 日付タップでその日の記録サマリーが見える（将来対応可）

---

### 部位詳細（halfModal）

**ファイル:** `Views/History/` + `Views/MuscleDetail/`

**存在理由:**
履歴マップで筋肉をタップした時の「この部位、最近どれくらい鍛えた？」に答える。

**ユーザーの感情・文脈:**
- 「大胸筋、今週何回やった？」
- 「何の種目でどのくらいの重量だったっけ？」

**表示内容:**
- 3Dビジュアル（該当部位にズーム）
- 期間内のセット数・合計重量
- 種目別内訳リスト
- 「詳細を見る」→ 3D詳細画面へ push

**絶対条件:**
- `.medium`状態でスクロールなしに最重要情報が見える
- 3Dは全身表示ではなく該当部位にズーム

---

### 3D部位詳細（push）

**ファイル:** `Views/MuscleDetail/`

**存在理由:**
部位の構造を3Dで深く理解したい人向け。緊急性は低い。

**ユーザーの感情・文脈:**
- 「この筋肉の構造を詳しく見たい」
- 「どんな種目が効くか確認したい」

**表示内容:**
- 3Dモデル（回転可能）
- 筋肉の解説
- 関連する推奨種目リスト

---

### 分析メニュー（sheet）

**ファイル:** `Views/Home/AnalyticsMenuView.swift`

**存在理由:**
ホームの「今日の判断」とは別に、「自分のトレーニングのパターンや傾向を把握したい」用途。
将来的にPro機能としてゲート化予定。

**4つのサブ画面:**

| 画面 | ファイル | ユーザーの問い | 将来Pro? |
|:--|:--|:--|:--|
| 週次サマリー | WeeklySummaryView.swift | 「今週ちゃんとできた？」 | ✅ |
| バランス診断 | MuscleBalanceDiagnosis... | 「どこが弱点？偏りは？」 | ✅ |
| 筋肉ジャーニー | MuscleJourneyView.swift | 「半年でどう変わった？」 | ✅ |
| ヒートマップ | MuscleHeatmapView.swift | 「自分のトレのパターンは？」 | ✅ |

---

### Paywall（sheet）

**ファイル:** `Views/Paywall/PaywallView.swift`

**存在理由:**
無料で価値を感じた後、Pro機能への欲求が最大になった瞬間に差し出す画面。

**ユーザーの感情・文脈:**
- Strength Mapを見て「自分のも見たい」という状態で来る
- 「これ月いくら？」と判断モードに入っている
- 迷っている時間は短い。即決か離脱か

**表示内容:**
- 無料 vs Pro の機能対比（視覚的に）
- 年額プランを推奨表示（¥4,900/年 = 月換算¥408を強調）
- 月額プラン（¥590/月）をサブ選択肢として
- 「何が変わるか」ではなく「どう感じるか」のコピー

**表示トリガー（ゲートポイント）:**
- HomeViewでStrength Mapボタンをタップ（Pro未加入時）
- SettingsViewのサブスクリプション管理

**絶対条件:**
- 3秒以内に「¥590でこれが使える」が伝わる
- 「復元する」リンクを必ず設置（App Store規約）
- 閉じるボタンは見つけやすい位置に（強制感はNG）

---

### 設定（Tab 4）

**ファイル:** `Views/Settings/`

**存在理由:**
プロフィール・課金・言語・法的文書の管理。積極的に使う画面ではなく必要な時だけ開く。

**ユーザーの感情・文脈:**
- 体重が変わった → Strength Mapの計算を更新したい
- 「課金してるか確認したい」
- 「言語を英語にしたい」

**含まれる設定項目:**
- ユーザープロフィール（体重・トレーニング頻度）
- サブスクリプション管理 → Paywall
- 言語設定
- 通知設定
- プライバシーポリシー / 利用規約 / サポート

---

### Apple Watch companion

**ファイル:** `MuscleMapWatch/`

**存在理由:**
ジムでスマホを出しにくい場面（マシン使用中など）でもセットを記録できる。
手首だけで完結するサブ入力デバイス。

**ユーザーの感情・文脈:**
- 「スマホをロッカーに置いてきた」
- 「バーベル持ちながらセット数を覚えてるのがきつい」
- Watch → iPhone へ自動同期で、帰宅後に詳細確認できる

**表示内容（Watch側）:**
- 現在のワークアウト種目
- セット記録（重量・レップ入力）
- 完了ボタン（Haptic確認）

**絶対条件:**
- iPhoneと双方向リアルタイム同期（WatchConnectivity）
- Watch側は最小入力。分析・ビジュアルはiPhone側

---

## App Storeスクリーンショットパイプライン

**ディレクトリ:** `scripts/screenshots/`

**存在理由:**
App Store申請用のスクリーンショットを自動生成するためのパイプライン。
手動スクショの手間を省き、デザイン変更時に一括再生成できる。

**状態:** 準備中（ディレクトリ構造のみ作成済み）

**将来的な構成（計画）:**
- シミュレータ起動 → 各画面へ遷移 → スクショ撮影 → デバイスフレーム合成
- 対象デバイス: iPhone 6.7" / 6.1" / iPad
- 対象画面: ホーム（回復マップ）/ ワークアウト実行中 / 完了画面 / 種目辞典 / Strength Map

---

## 画面実装時のチェックリスト

新しい画面または既存画面を大幅修正した際に必ず確認：

- [ ] この画面を開くユーザーの**感情・文脈**は何か？（上記を参照）
- [ ] その感情に対して、**3秒以内**に答えが出せているか？
- [ ] **人体図・ビジュアル要素**が切れていないか？（スクショ確認）
- [ ] **最重要情報**がL3以上のフォントで表示されているか？
- [ ] **Hapticフィードバック**が実装されているか？
- [ ] **同じデータを表示する他画面**と品質が揃っているか？
- [ ] **Pro判定**が正しく機能しているか？（isPremiumのゲート確認）

---

*最終更新: 2026-03-07（WorkoutShareCard PR前回比表示, オンボーディング4ページ化, WeightInputPage, PersonalizationPage, SplashView/CallToActionPage強化, App Storeスクショパイプライン追記）*
