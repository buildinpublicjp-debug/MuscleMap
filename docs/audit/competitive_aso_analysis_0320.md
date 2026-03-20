# MuscleMap 競合分析 & ASO最適化レポート

> **作成日:** 2026-03-20
> **対象バージョン:** v5.0（App Store提出準備）
> **分析対象:** Strong, Hevy, Fitbod, JEFIT vs MuscleMap

---

## 目次

1. [競合比較マトリクス](#1-競合比較マトリクス)
2. [App Store説明文最適化](#2-app-store説明文最適化)
3. [スクリーンショット戦略](#3-スクリーンショット戦略)
4. [キーワード最適化](#4-キーワード最適化)
5. [価格戦略](#5-価格戦略)
6. [総合ポジショニング & アクションアイテム](#6-総合ポジショニング--アクションアイテム)

---

## 1. 競合比較マトリクス

### 1.1 価格比較

| | **Strong** | **Hevy** | **Fitbod** | **JEFIT** | **MuscleMap** |
|:---|:---|:---|:---|:---|:---|
| 無料枠 | ルーティン3個、カスタム種目3個 | 寛大（無制限ワークアウト） | ほぼなし（3回 or 7日間試用） | 広告あり、機能制限 | 週1回ワークアウト |
| 月額（USD） | $4.99 | $2.99-$3.99 | $15.99 | $12.99 | $4.99 |
| 年額（USD） | $29.99 (~$2.50/月) | $23.99 (~$2.00/月) | $95.99 (~$8.00/月) | $39.99-$69.99 | $39.99 |
| 月額（JPY） | ~¥750 [推定] | ~¥480 [推定] | ~¥2,400 [推定] | ~¥1,950 [推定] | ¥590 |
| 年額（JPY） | ~¥4,500 [推定] | ~¥3,600 [推定] | ~¥14,400 [推定] | ~¥6,000-¥10,500 [推定] | ¥4,900 |
| 買い切り | $99.99 | ~$80 [推定] | ~$359.99（不定期） | なし | なし |
| 割引率（年/月） | ~50% | ~46% | ~50% | 変動 | ~31% |

**所見:** MuscleMapの ¥590/月・¥4,900/年 は Strong / Hevy と同価格帯のバジェットティア。Fitbod / JEFIT のプレミアム価格帯ではないが、提供機能は Fitbod に匹敵する。**コストパフォーマンス訴求が最大の武器。**

### 1.2 機能比較マトリクス

| 機能 | Strong | Hevy | Fitbod | JEFIT | **MuscleMap** |
|:---|:---:|:---:|:---:|:---:|:---:|
| 筋肉マップ可視化 | Heat Map | Heatmap + BodyDiagram | Heat Map（後処理） | BodyMap | **21筋肉SVGリアルタイム（前面+背面同時）** |
| 回復トラッキング | - | - | 0-100%回復、6日サイクル | メソサイクル別 | **ボリューム係数付き回復計算** |
| EMGベースデータ | - | - | - | 研究用EMGマップ | **92種目EMG論文ベース** |
| 自動ルーティン生成 | - | HevyGPT（AI） | AI毎回生成 | AIプログレッシブ | **ルールベース（目標/頻度/場所）** |
| Apple Watch | 優秀 | 対応 | 対応 | 不安定 | **watchOS 10.0+対応** |
| ソーシャル機能 | - | フィード・いいね・コメント | - | 13Mコミュニティ | Phase 0（モックデータ） |
| シェアカード | テンプレート共有 | 基本的なシェア | リンク共有 | コミュニティ共有 | **9:16 + 1:1 筋肉マップ付きカード** |
| 種目数 | 200+ | 400+ | 1,600+ | 1,400+ | **92種目** |
| 未刺激警告 | - | - | - | - | **7日+紫色点滅** |
| Strength Map（筋力太さ可視化） | - | - | - | - | **Pro独自機能** |
| PRトラッキング | 追跡のみ | Hevy Trainer | AI駆動 | AI PO | **自動検出+祝福アニメ** |
| オフライン | 対応 | 対応 | 対応 | 対応 | **SwiftData完全ローカル** |
| CSVインポート | エクスポートのみ | エクスポートのみ | - | - | **インポート対応** |

### 1.3 App Store評価・ユーザー規模

| | Strong | Hevy | Fitbod | JEFIT | MuscleMap |
|:---|:---|:---|:---|:---|:---|
| 評価 | 4.9 (108K+件) | 4.9 (430K+件) | 4.8 (5M+DL) | 4.8 | 新規 |
| ユーザー規模 | ~100K/月 DL | 12M+ユーザー | 5M+ DL | 20M+ DL, 13Mコミュニティ | 新規 |

### 1.4 MuscleMap独自の競合優位性

| 優位性 | 競合で不在 | 優先度 |
|:---|:---|:---|
| 21筋肉リアルタイムSVG回復可視化（信号機カラー） | Strong, Hevy（回復追跡なし） | **P0** |
| EMGベース刺激マッピング（92種目） | Strong, Hevy, Fitbod（アルゴリズム推定のみ） | **P0** |
| 未刺激警告（7日+紫色点滅） | 全4競合 | **P0** |
| Strength Map（PR→筋肉太さ可視化） | 全4競合 | **P1** |
| SNS最適化シェアカード（9:16 + 1:1、筋肉マップ付き） | Hevy以外 | **P1** |
| 日本市場ネイティブ（日英バイリンガル、JPY価格） | 全4競合（二次ローカライズ） | **P1** |
| ボリューム係数回復計算 | Strong(なし), Hevy(なし), Fitbod(時間ベース), JEFIT(メソサイクル) | **P0** |
| 目標/頻度/場所ベースの自動ルーティン構築 | Strong（なし）、Hevy/Fitbod/JEFIT（AI依存） | **P1** |

---

## 2. App Store説明文最適化

### 2.1 現状の課題

| 項目 | 現状 | 問題点 | 推奨 |
|:---|:---|:---|:---|
| 英語サブタイトル | "See Your Muscles. Train Smarter." (31文字) | **30文字制限超過**。キーワード密度低い | "Muscle Recovery Map & Tracker" (29文字) |
| 日本語サブタイトル | "筋肉の状態が見える。だから迷わない。" (16文字) | 良い。感情訴求あり | 維持 or "筋肉の回復が見える。迷わず鍛える。" |
| 英語先頭3行 | 情緒的リード文 | **キーワードが先頭3行にない**。ASO上最重要エリア | キーワードリッチな冒頭に変更 |
| 日本語先頭3行 | 同上 | 同上 | 同上 |
| 機能リスト順序 | Muscle Map → Today's Menu → EMG → Routines → ... | 差別化機能が後半に埋もれる | 差別化機能をトップ3に |
| 価格表記（英語） | $4.99/month, $39.99/year | OK | OK（App Store Connect設定と一致させること） |
| CTA | なし | **明確な行動喚起がない** | 末尾にダウンロードCTAを追加 |

### 2.2 推奨: 英語説明文（改善版）

```
## Subtitle (30 chars)
Muscle Recovery Map & Tracker

## Promotional Text (170 chars max)
NEW: Personalized day-split routines auto-built from your goals. 92 EMG-mapped exercises.
Real-time muscle recovery visualization. See your muscles. Train smarter.

## Description

Track muscle recovery in real-time on a 21-muscle body map. Red → yellow → green.
Know exactly which muscles are ready. Never waste a workout again.

MuscleMap is the only workout tracker that visualizes your muscle recovery state
with EMG-based scientific data — so you always know what to train next.

--- WHY MUSCLEMAP ---

REAL-TIME MUSCLE RECOVERY MAP
21 muscles displayed front and back. After each workout, see your stimulated
muscles light up with recovery colors. Red = fatigued. Green = ready to go.

NEGLECT ALERTS — Only in MuscleMap
Muscles untrained for 7+ days flash purple. Prevent imbalances before they start.

92 EXERCISES WITH EMG-BASED DATA
Exercise-to-muscle stimulation percentages based on published EMG research.
Know exactly how each movement targets each muscle.

AUTO-BUILT PERSONALIZED ROUTINES
Tell us your goal, weekly frequency, and training location. MuscleMap builds
your custom day-split routine automatically. Gym, home, or bodyweight.

SMART WORKOUT SUGGESTIONS
Based on your recovery data, MuscleMap recommends what to train today.
No guesswork. Just follow the science.

WORKOUT LOGGING — Fast & Simple
Log weight and reps with one hand. Previous data always visible.
PR detection with celebration animations.

HISTORY & CALENDAR
Review workouts with muscle map or calendar views. Track your balance over time.

SHARE CARDS
Auto-generated workout cards (1080×1080) and Strength Map cards (1080×1920).
Show off your progress on Instagram, X, and more.

--- PRO FEATURES ---

STRENGTH MAP — See Your Power
Your PR data transforms into muscle thickness on the map.
Thick = strong. Thin = room to grow. Grades from S to D.

UNLIMITED WORKOUTS
Free plan: 1 workout/week. Pro: unlimited.

ADVANCED MENU SUGGESTIONS
Recovery-aware personalized workout recommendations with GIF previews.

APPLE WATCH
Log workouts from your wrist. Syncs automatically.

--- SUBSCRIPTION ---

- Monthly: $4.99/month
- Yearly: $39.99/year (includes 7-day free trial)

Start free. Upgrade when you're ready.

Subscription auto-renews unless cancelled 24 hours before period end.
Manage in Settings > Apple ID > Subscriptions.

Terms of Use: https://musclemap.app/terms
Privacy Policy: https://musclemap.app/privacy
```

**変更点:**
1. サブタイトルを30文字以内に修正、キーワード「Muscle Recovery」「Tracker」を含める
2. 先頭3行にキーワード密集（muscle recovery, body map, workout）
3. 「Only in MuscleMap」で未刺激警告の独自性を強調
4. 機能順序を差別化順に再配置（回復マップ → 未刺激警告 → EMG → ルーティン → 提案）
5. 「Start free. Upgrade when you're ready.」CTA追加
6. Promotional Textに「NEW:」フックを追加

### 2.3 推奨: 日本語説明文（改善版）

```
## サブタイトル（30文字以内）
筋肉の回復が見える。迷わず鍛える。

## プロモーションテキスト（170文字以内）
NEW: 目標・頻度・場所からあなた専用のDay分割ルーティンを自動構築。92種目のEMGデータで
刺激を可視化。リアルタイム筋肉マップで回復状態を一目で把握。もう迷わない。

## 説明文

21の筋肉の回復状態を、リアルタイムで人体マップに表示。
赤→黄→緑の信号機カラーで「どこが回復済みか」が一目瞭然。

MuscleMapは、EMG論文に基づく科学的データで筋肉の刺激を可視化する、
唯一のワークアウトトラッカーです。

--- MuscleMapが選ばれる理由 ---

■ リアルタイム筋肉回復マップ
21の筋肉を前面・背面で同時表示。トレーニング後、刺激した部位が光り、
回復カラーでコンディションが一目瞭然。

■ 未刺激アラート — MuscleMapだけの機能
7日以上鍛えていない筋肉が紫色に点滅。偏りに気づける。

■ 92種目 EMGベース刺激マッピング
科学論文に基づく刺激度データ。各種目がどの筋肉にどれだけ効くか正確に把握。

■ あなた専用の自動ルーティン
目標・週間頻度・トレーニング場所を選ぶだけで、Day分割ルーティンを自動構築。
ジム・自宅・自重に完全対応。

■ 今日のメニュー自動提案
回復データから「今日鍛えるべき部位」と種目を自動で提案。
「何をすればいいかわからない」を解消。

■ ワークアウト記録 — シンプル＆高速
重量・レップ数をワンハンドで記録。前回データが常に表示。
自己ベスト更新は自動検出＆祝福アニメーション。

■ 履歴 & カレンダー
マップ表示・カレンダー表示で振り返り。バランスを視覚的に確認。

■ シェアカード
ワークアウト完了時に美しいカードを自動生成（1080×1080正方形）。
Strength Mapカード（1080×1920）でSNS映え。

--- Pro機能（サブスクリプション） ---

■ Strength Map — あなたの筋力を可視化
PRデータが筋肉の太さに変換。太い＝強い。グレードS〜Dで筋力レベルを表示。

■ 無制限ワークアウト記録
無料プラン: 週1回。Proで制限なし。

■ パーソナライズメニュー提案
回復状況に応じた高度なメニュー提案。GIFプレビュー付き。

■ Apple Watch対応
手首からワークアウトを記録。自動同期。

--- サブスクリプション ---

・月額プラン: ¥590/月
・年額プラン: ¥4,900/年（7日間無料トライアル付き）

まず無料で体験。いつでもProへアップグレード。

サブスクリプションはApple IDアカウントに請求されます。
現在の期間終了の24時間前までにキャンセルしない限り自動更新。
設定 > Apple ID > サブスクリプションで管理。

利用規約: https://musclemap.app/terms
プライバシーポリシー: https://musclemap.app/privacy
```

---

## 3. スクリーンショット戦略

### 3.1 基本方針

- **6枚構成**（App Store最大10枚だが、上位6枚が閲覧率の95%以上）
- **サイズ:** 6.7インチ（1290×2796px）+ 6.5インチ（1284×2778px）
- **テーマ:** ダーク基調（アプリのバイオモニターテーマに統一）
- **フォーマット:** 端末フレーム + テキストオーバーレイ（上部1/3にコピー、下部2/3にスクリーンショット）

### 3.2 6枚の構成

#### Shot 1: ヒーローショット（ファーストインプレッション）

| 項目 | 内容 |
|:---|:---|
| **日本語コピー** | 「鍛えた筋肉が光る」 |
| **英語コピー** | "Your Muscles Light Up" |
| **サブコピー（日）** | 21部位のリアルタイム回復マップ |
| **サブコピー（英）** | Real-time recovery map for 21 muscles |
| **表示UI** | ホーム画面 — 筋肉マップ（前面+背面）、複数筋肉が回復カラーで光っている状態 |
| **ハイライト** | 信号機カラー（赤・黄・緑）が同時に表示されている状態が理想 |
| **優先度** | **P0** — 最も重要。ここでDL判断の50%が決まる |

#### Shot 2: 未刺激警告 + 回復ステータス

| 項目 | 内容 |
|:---|:---|
| **日本語コピー** | 「サボった筋肉、バレてる」 |
| **英語コピー** | "Neglected Muscles? We'll Tell You." |
| **表示UI** | ホーム画面 — 一部の筋肉が紫色点滅中 + 他が緑/黄のミックス |
| **ハイライト** | 紫色の未刺激警告が他アプリにない独自機能であることを強調 |
| **優先度** | **P0** — 差別化ポイント。競合にない機能 |

#### Shot 3: ワークアウト記録 + PR達成

| 項目 | 内容 |
|:---|:---|
| **日本語コピー** | 「自己ベスト、自動で検出」 |
| **英語コピー** | "PR Detected. Automatically." |
| **表示UI** | ワークアウト記録画面 — セット入力中 + PR達成の祝福UI |
| **ハイライト** | PRゴールド(`#FFD700`)のバッジ/アニメーションが目に入る構図 |
| **優先度** | **P0** — コアユースケース |

#### Shot 4: パーソナライズルーティン

| 項目 | 内容 |
|:---|:---|
| **日本語コピー** | 「あなた専用メニュー、自動で作る」 |
| **英語コピー** | "Your Routine. Auto-Built." |
| **表示UI** | オンボーディングのRoutineBuilderPage or GoalMusclePreviewPage — Day分割カード表示 |
| **ハイライト** | Day 1, Day 2, Day 3 のカードが見える + 種目名 + GIFサムネイル |
| **優先度** | **P1** — 競合Fitbodとの差別化（無料でルーティン構築可能） |

#### Shot 5: Strength Map（Pro）

| 項目 | 内容 |
|:---|:---|
| **日本語コピー** | 「筋力が"太さ"で見える」 |
| **英語コピー** | "See Your Strength. Literally." |
| **表示UI** | Strength Map画面 — 筋肉の太さが異なる状態 + グレード(S/A/B)表示 |
| **ハイライト** | PRO バッジを小さく表示。「太い＝強い」が直感的にわかる |
| **優先度** | **P1** — Pro訴求 + 完全独自機能 |

#### Shot 6: シェアカード + Apple Watch

| 項目 | 内容 |
|:---|:---|
| **日本語コピー** | 「記録を、自慢に変える」 |
| **英語コピー** | "Turn Records Into Bragging Rights" |
| **表示UI** | シェアカード実物（1:1正方形 or 9:16）+ Apple Watch画面のコンポジット |
| **ハイライト** | SNS投稿イメージ（X/Instagram風のフレーム内にカードを配置） |
| **優先度** | **P1** — ソーシャル訴求 + Watch訴求 |

### 3.3 スクリーンショット制作ノート

- **背景色:** `#0D0D0D`（アプリBgPrimary `#121212` よりわずかに暗く）
- **テキストカラー:** `#FFFFFF` (メイン) + `#00E676` (アクセント、オンボーディングカラー流用)
- **端末フレーム:** iPhone 15 Pro Max ベゼル
- **フォント:** SF Pro Display Heavy（日）/ SF Pro Display Heavy（英）
- **推奨ツール:** Figma or screenshots/ パイプライン（`scripts/screenshots/` にスケルトン準備済み）

---

## 4. キーワード最適化

### 4.1 現状キーワードの評価

**日本語（現在 97文字）:**
```
筋トレ,筋肉,回復,トレーニング,ワークアウト,記録,マッスル,プログラム,メニュー,ジム,自重,PR,自己ベスト,ルーティン,分割法,部位,フィットネス,EMG,ボディビル,ログ
```

| 評価 | 詳細 |
|:---|:---|
| 良い点 | 「筋トレ」「筋肉」「回復」のTier 1キーワードが先頭にある |
| 改善点 | 「マッスル」はカタカナ検索が少ない（「筋肉」で十分）→ 枠の無駄 |
| 改善点 | 「EMG」は一般ユーザーが検索しない → 「可視化」「マップ」に差し替え |
| 改善点 | 「ボディビル」は競合が強すぎる → 「筋力」「体づくり」に差し替え |
| 追加推奨 | 「Apple Watch」「ヘルスケア」（日本市場で検索ボリュームあり） |

**英語（現在 98文字）:**
```
muscle,recovery,workout,tracker,gym,training,log,fitness,bodybuilding,strength,routine,split,PR,EMG
```

| 評価 | 詳細 |
|:---|:---|
| 良い点 | 「muscle」「recovery」「workout」「tracker」のTier 1が先頭 |
| 改善点 | 「EMG」は検索ボリューム極小 → 「planner」「exercise」に差し替え |
| 改善点 | 「bodybuilding」は競合飽和 → 「body map」「muscle map」に差し替え |
| 追加推奨 | 「Apple Watch」は公式に推奨されるキーワード |

### 4.2 推奨キーワード（改善版）

**日本語（100文字以内）:**
```
筋トレ,筋肉,回復,トレーニング,ワークアウト,記録,ジム,自重,PR,自己ベスト,ルーティン,分割法,部位,フィットネス,筋力,可視化,マップ,メニュー,体づくり,ログ
```
文字数: 92

**変更点:**
- 削除: 「マッスル」（カタカナ検索少）、「プログラム」（競合語）、「EMG」（専門用語）、「ボディビル」（競合飽和）
- 追加: 「筋力」「可視化」「マップ」「体づくり」

**英語（100文字以内）:**
```
muscle,recovery,workout,tracker,gym,training,log,fitness,strength,routine,split,PR,body map,planner,exercise
```
文字数: 99

**変更点:**
- 削除: 「EMG」（検索なし）、「bodybuilding」（競合飽和）
- 追加: 「body map」「planner」「exercise」

### 4.3 キーワード戦略マトリクス

| カテゴリ | キーワード | 優先度 | 理由 |
|:---|:---|:---|:---|
| **メインKW** | muscle, 筋トレ, workout tracker | P0 | 最大検索ボリューム |
| **差別化KW** | muscle recovery, body map, 回復, 可視化 | P0 | 競合が少なく、MuscleMapの強み |
| **ロングテールKW** | muscle map tracker, 筋肉 回復 トラッカー | P1 | 低競合・高コンバージョン |
| **競合KW** | gym log, training log, ジム 記録 | P1 | Strong/Hevyのサブタイトルに含まれる語 |
| **ユニークKW** | neglect alert, 未刺激, strength map, 筋力 マップ | P2 | 現在検索ボリューム小だが、PR/マーケで育てる余地 |

### 4.4 サブタイトル最適化（キーワード観点）

| | 現在 | 推奨 | 理由 |
|:---|:---|:---|:---|
| 英語 | "See Your Muscles. Train Smarter." (31文字、超過) | "Muscle Recovery Map & Tracker" (29文字) | 30文字以内、KW「muscle」「recovery」「tracker」含む |
| 日本語 | "筋肉の状態が見える。だから迷わない。" (16文字) | 維持 or "筋肉の回復が見える筋トレ記録" (13文字) | 「回復」「筋トレ」「記録」をサブタイトルに含める |

> **注意:** サブタイトルはキーワードフィールドと同等以上のASO重要度。感情訴求と KW密度のバランスが必要。日本語は感情訴求が強く良いが、KWを入れたバージョンもA/Bテスト推奨。

---

## 5. 価格戦略

### 5.1 現在の価格設定

| プラン | 日本語 | 英語（想定USD） | 月あたり |
|:---|:---|:---|:---|
| 月額 | ¥590 | $4.99 | ¥590 |
| 年額 | ¥4,900 | $39.99 | ¥408 |
| 年額割引率 | | | ~31% |

### 5.2 競合ポジショニング

```
                  価格 (月額USD換算)
                  |
        $16 ─── Fitbod ─────────────────── プレミアム
                  |
        $13 ─── JEFIT ──────────────────── ミドル
                  |
         $5 ─── Strong ── MuscleMap ────── バジェット
         $4 ─── ─────────────────────────
         $3 ─── Hevy ───────────────────── 最安
                  |
                  ├────────────────────────
                  機能少ない    →    機能多い
```

MuscleMapはStrong価格帯に位置するが、機能はFitbodに匹敵（回復追跡、自動ルーティン）。**「Fitbodの1/3の価格でFitbod級の機能」**が最大の価値提案。

### 5.3 推奨アクション

| アクション | 推奨 | 優先度 | 根拠 |
|:---|:---|:---|:---|
| 現在価格の維持 | **推奨** | P0 | ¥590/月・¥4,900/年は日本市場で最適。バジェットティアで機能差別化が最も効果的 |
| 年額割引率の引き上げ | 検討 | P2 | 現在31%。40-50%に引き上げ（¥3,900/年 = ¥325/月）で年額コンバージョン率向上の可能性。ただし収益インパクト要検証 |
| 買い切りプランの追加 | **保留** | P3 | Strong ($99.99)、Hevy (~$80) にあるが、サブスク収益の安定性を優先すべき段階。ユーザー規模が10K+になったら再検討 |
| 無料枠の調整 | 現状維持 | P1 | 「週1回」は Fitbod（3回 or 7日）より寛大で Strong（3ルーティン）より制限的。ちょうど良いバランス |
| 7日間トライアルの強調 | **推奨** | P0 | 年額プランのトライアルをスクショ・説明文で明確に訴求。「リスクゼロで始められる」 |

### 5.4 想定コンバージョンファネル

```
DL → オンボーディング完了: 60-70% [推定]
        ↓
オンボーディング → ハードペイウォール表示: 100%
        ↓
ペイウォール → トライアル開始: 10-15% [業界平均]
        ↓
トライアル → 課金転換: 50-60% [7日トライアルの業界平均]
        ↓
月額 vs 年額: 30:70 [年額推奨UI表示の場合]
```

**年間1万DLの場合の推定収益（保守的）:**
- 10,000 DL × 65% (完了率) × 12% (トライアル) × 55% (転換) × ¥4,900 (年額70%) + ¥590×12 (月額30%)
- = 10,000 × 0.65 × 0.12 × 0.55 × (¥4,900 × 0.70 + ¥7,080 × 0.30)
- = 429人 × ¥5,554
- = **約¥238万/年**

> ※推定値。実際のコンバージョン率はアプリ品質・市場状況により大きく変動する

---

## 6. 総合ポジショニング & アクションアイテム

### 6.1 MuscleMapのポジショニングステートメント

> **MuscleMapは、筋肉の回復状態をリアルタイムで可視化する唯一のワークアウトトラッカー。**
> EMG論文ベースのデータと信号機カラーの筋肉マップで、「今日どこを鍛えるべきか」が一目でわかる。
> Fitbodの1/3の価格で、科学に基づいたパーソナライズトレーニングを実現。

### 6.2 一言差別化（App Store検索結果で目に入る）

| 言語 | 一言 |
|:---|:---|
| 日本語 | 「筋肉の回復が見えるワークアウトトラッカー」 |
| 英語 | "The Workout Tracker That Shows Muscle Recovery" |

### 6.3 アクションアイテム一覧

| # | アクション | 優先度 | 対象ファイル/領域 |
|:---|:---|:---|:---|
| 1 | 英語サブタイトルを30文字以内に修正 | **P0** | `docs/appstore/description_en.md` + App Store Connect |
| 2 | 英語説明文を改善版に差し替え | **P0** | `docs/appstore/description_en.md` |
| 3 | 日本語説明文を改善版に差し替え | **P0** | `docs/appstore/description_ja.md` |
| 4 | キーワードを最適化版に差し替え | **P0** | `docs/appstore/keywords.md` |
| 5 | スクリーンショット6枚を制作 | **P0** | `scripts/screenshots/` パイプライン |
| 6 | プロモーションテキストを更新（「NEW:」フック付き） | **P1** | `docs/appstore/description_*.md` |
| 7 | 7日間無料トライアルを説明文・スクショで強調 | **P1** | 説明文 + Shot 5 or 6 |
| 8 | 日本語サブタイトルのKW版をA/Bテスト候補に | **P2** | App Store Connect |
| 9 | 年額割引率40-50%を検討（¥3,900/年） | **P2** | PurchaseManager + App Store Connect |
| 10 | ソーシャル機能をPhase 1に昇格（Hevy対抗） | **P3** | ActivityFeedView |

### 6.4 競合対策の要点

| 対 | 戦略 | 具体策 |
|:---|:---|:---|
| **vs Strong** | 回復可視化で差別化 | 「Strongには回復トラッキングがない」ことをスクショで暗示（Shot 1, 2） |
| **vs Hevy** | ビジュアル品質で差別化 | シェアカードの美しさ、筋肉マップのリアルタイム性を強調 |
| **vs Fitbod** | 価格で差別化 | 「科学ベースの回復トラッキングが¥590/月」→ Fitbodの1/3の価格 |
| **vs JEFIT** | UI品質 + 日本市場で差別化 | JEFITの旧式UIに対してモダンなバイオモニターデザイン |

### 6.5 リスク & 注意事項

| リスク | 対策 |
|:---|:---|
| 種目数が少ない（92 vs 1400+） | 「EMGベースで厳選した92種目」と品質訴求。量より質のポジショニング |
| ソーシャル機能がない（vs Hevy） | Phase 0のモックは非表示にするか、シェアカードのSNS投稿で代替訴求 |
| 新規アプリでレビューがない | ローンチ初期にApp内レビュー促進（WorkoutSession 3回目以降で `SKStoreReviewController` 表示） |
| 「EMG」が一般ユーザーに伝わらない | 説明文では「科学論文に基づく刺激データ」と平易に表現。「EMG」はキーワードから削除済み |

---

## 付録A: 競合App Storeサブタイトル一覧

| アプリ | サブタイトル（US） |
|:---|:---|
| Strong | "Workout Tracker Gym Log" |
| Hevy | "Workout Tracker Gym Log" |
| Fitbod | "Gym & Fitness Planner" |
| JEFIT | "Workout Plan Gym Tracker" |
| **MuscleMap（推奨）** | **"Muscle Recovery Map & Tracker"** |

MuscleMapのサブタイトルは「Muscle Recovery」で差別化。競合4社すべてが「Workout/Gym」を使用しているため、「Recovery」「Map」で検索結果上の視認性を確保。

## 付録B: 日本フィットネスアプリ市場データ

- 2024年市場規模: $2.5B（約3,750億円）
- 2033年予測: $13.39B（CAGR 20.5%）
- 日本のApp Store Health & Fitness カテゴリ上位20アプリの共通キーワード: 筋トレ、運動、フィットネス、カレンダー、簡単、記録
- 日本市場の特徴: 男性向け筋トレアプリは「筋トレ」キーワードが圧倒的。「フィットネス」はヘルスケア寄り

## 付録C: 情報の確度について

- App Store評価・ユーザー数: 公式マーケティング資料より（高確度）
- 米ドル価格: 公式サイト・App Store確認済み（高確度）
- 円建て価格: Appleの標準価格帯からの推定値（中確度、Japan App Storeでの直接確認推奨）
- 機能比較: 公式サイト・ヘルプセンター・複数レビューサイトからのクロスチェック（高確度）
- 市場規模データ: Globe Newswire / Astute Analytica レポート（中確度）
- コンバージョン率推定: 業界平均値（RevenueCat 2025レポート等）からの推定（低〜中確度）

---

> **結論:** MuscleMapは「筋肉回復のリアルタイム可視化」という明確な差別化ポイントを持ち、バジェット価格帯でプレミアム級の機能を提供する。App Store提出前に、サブタイトル修正（P0）、説明文改善（P0）、キーワード最適化（P0）、スクリーンショット制作（P0）を完了させることが最優先。
