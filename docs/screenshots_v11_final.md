# CC Prompt: MuscleMap v1.1 App Store Screenshots 100点版

## ⚠️ 画像の扱いルール（フリーズ防止）

シミュレーターのスクショは 1290×2796px あり、そのままAPIに送ると2000px上限エラーでフリーズする。

**ルール: 状態確認用と本番用を分ける。**

```bash
# 本番用（フルサイズ）— generate_all.js に渡す
xcrun simctl io booted screenshot screenshots/screens_v11/shot1_screen.png

# 確認用（リサイズ）— 画面の状態を目で見て確認する用
sips -Z 800 screenshots/screens_v11/shot1_screen.png --out /tmp/check_shot1.png
# → /tmp/check_shot1.png を読んで画面の状態を確認
```

- **本番PNG（screens_v11/）は絶対にAPIに送るな。リサイズもするな。**
- **確認用PNG（/tmp/check_*）はsipsで800px以下にリサイズしてから読め。**
- 確認して画面が期待通りでなければ、シミュレーター操作をやり直して再撮影。

## その他のルール
- 1ステップ1コマンド。長いパイプラインを一気に流すな。
- エラーが出たら3回リトライ。それでもダメならユーザーに報告して止まれ。
- シミュレーターのタップ後は必ず `sleep 2` で待て。

---

## 目的
App Store用スクリーンショット6枚（日本語版）を完全自動生成する。
モックデータ投入 → シミュレーター操作 → スクショ撮影 → 状態確認 → HTML合成 → 1284×2778px PNG出力。

## 最初にやること
1. `CLAUDE.md` を読む
2. `docs/screenshot_plan_v11.md` を読む
3. `docs/screenshots_v11_100point.md` を読む（100点設計書）
4. `screenshots/generate_all.js` を確認

---

## Phase 1: 環境準備

```bash
cd ~/MuscleMap
git pull origin main
```

### forceProForTesting を true に変更
`MuscleMap/Utilities/PurchaseManager.swift` の `forceProForTesting = false` を `true` に変更。

### ビルド & シミュレーター起動
```bash
xcrun simctl list devices | grep "Pro Max"
xcrun simctl boot "iPhone 16 Pro Max" 2>/dev/null || true
open -a Simulator

xcodebuild -scheme MuscleMap \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  build 2>&1 | tail -5
```

アプリ起動まで `sleep 5`。

---

## Phase 2: モックデータ投入

### なぜ必要か
データが空/貧弱だと:
- 回復マップに色がつかない（灰色だらけ）
- Strength Mapが全部細い
- カレンダーがスカスカ
- PR達成画面が出せない

### 理想の状態（100点の条件）
- 回復マップに**赤・黄・緑・紫の4色が同時表示**
- Strength Mapで筋肉の太さに差がある（胸・脚が太い、前腕が細い）
- カレンダーに16日分の記録
- PR更新が2件以上出るワークアウト完了画面
- ルーティンに4 Day分のデータ

### 投入すべきデータ

**ワークアウトセッション（過去30日、16回）:**

| 日付 | 部位 | 種目例 | 回復マップの色 |
|------|------|--------|--------------|
| 昨日 | 胸+三頭 | ベンチプレス80kg×8, インクラインDB35kg×10, ケーブルフライ20kg×12 | 赤（疲労） |
| 3日前 | 背中+二頭 | デッドリフト120kg×5, ラットプル60kg×10, バーベルカール30kg×12 | 黄〜緑 |
| 5日前 | 脚 | スクワット100kg×6, レッグプレス150kg×10, レッグカール40kg×12 | 緑（回復済み） |
| 10日前 | 肩 | ショルダープレス40kg×10, サイドレイズ10kg×15 | 紫（未刺激警告） |
| 7日前 | 胸+三頭 | ベンチ75kg×8（前回より軽い→PRにならない） | — |
| 12日前 | 背中 | デッドリフト115kg×5 | — |
| 14日前 | 脚 | スクワット95kg×6 | — |
| + 残り9セッション程度を散りばめる | | | カレンダー用 |

**PR設定のポイント:**
- 昨日のベンチ80kgが過去最高（前回75kg→80kgでPR更新が出る）
- 3日前のデッドリフト120kgが過去最高（前回115kg→120kgでPR更新）

**ルーティン:**
- Day 1: 胸・三頭（4種目）
- Day 2: 背中・二頭（4種目）
- Day 3: 肩（3種目）
- Day 4: 脚（4種目）

### 投入方法
SwiftDataに直接テストデータを投入するヘルパーを一時追加。

**投入後、ホーム画面を確認:**
```bash
xcrun simctl io booted screenshot /tmp/check_data.png
sips -Z 800 /tmp/check_data.png --out /tmp/check_data_small.png
# → /tmp/check_data_small.png を読んで、回復マップに4色が出ているか確認
```

---

## Phase 3: スクショ撮影（6枚）

```bash
mkdir -p screenshots/screens_v11
```

### 撮影→確認の共通パターン
```bash
# 1. 画面を操作して目的の状態にする
# 2. 本番撮影
xcrun simctl io booted screenshot screenshots/screens_v11/shotN_screen.png
# 3. 確認用リサイズ
sips -Z 800 screenshots/screens_v11/shotN_screen.png --out /tmp/check_shotN.png
# 4. /tmp/check_shotN.png を読んで状態確認
# 5. OKなら次へ、NGならシミュレーター操作をやり直して再撮影
```

### Shot 1: ホーム画面（回復マップ）
- ホームタブ表示
- 前面マップに赤（胸）・黄緑（背中）・緑（脚）・紫点滅（肩）
- 「今日のおすすめ」セクションも見えている

### Shot 2: 種目ピッカー（GIFサムネイル）
- ワークアウトタブ → 「種目を追加」→ ピッカー表示
- GIFサムネイルが3つ以上見える
- **種目をタップして選択するな！ピッカーが開いた状態で止める**

### Shot 3: ホームのルーティンセクション
- ホームタブに戻る
- 「今日のルーティン」セクションまでスクロール
- Day 1〜4 のタブ + GIFカードが見えている

### Shot 4: ワークアウト完了画面
- 実際にワークアウトを記録して完了画面を表示
- ベンチプレス80kg×8（PR更新が出る）を記録
- 完了画面でPR更新表示 + 筋肉マップハイライト + ボリューム表示

### Shot 5: Strength Map
- ホーム → Strength Mapボタン
- 前面+背面、筋肉の太さに差がある

### Shot 6: 履歴カレンダー
- 履歴タブ → カレンダー表示
- 16日分の緑ドット

### 全6枚の確認
```bash
for i in 1 2 3 4 5 6; do
  sips -Z 800 screenshots/screens_v11/shot${i}_screen.png --out /tmp/check_shot${i}.png
done
# → /tmp/check_shot1.png 〜 6 を順番に読んで最終確認
```

---

## Phase 4: HTML合成 → PNG出力

```bash
cd screenshots
npm install puppeteer 2>/dev/null
npx puppeteer browsers install chrome 2>/dev/null
node generate_all.js --ja
```

出力確認:
```bash
ls -la output_v11/
for f in output_v11/shot*_ja.png; do
  echo "$f"
  sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | grep pixel
done
```

---

## Phase 5: 後片付け

1. `forceProForTesting` を `false` に戻す
2. モックデータ投入の一時コードがあれば削除
3. `open screenshots/output_v11/` で結果を表示
4. ユーザーに完了報告

---

## 6枚の仕様

| Shot | 画面 | アクセント | コピー |
|------|------|-----------|--------|
| 1 | 回復マップ | #00FFB3 | 昨日の筋トレ、今どこに残ってる？ |
| 2 | GIFピッカー | #00D4FF | 放置した筋肉、教えます |
| 3 | ルーティン | #00FFB3 | 今日やるべき種目、自動で |
| 4 | PR達成 | #FFD700 | 前回を超えるなら、今回を超えろ |
| 5 | Strength Map | #00D4FF | どこに効くか、数値で見る |
| 6 | カレンダー | #00FFB3 | 週間バランス、一目で |

## HTMLテンプレート仕様
- iPhoneフレーム: 角丸56px、Dynamic Island、サイドボタン
- 背景: ダークグラデーション + アクセントグロー + グリッドパターン
- ヘッドライン: 90px Heavy
- サブコピー: 32px Medium、アクセント色70%透明度
- フォント: Noto Sans JP 900 / Inter 900 — Google Fonts
- ボトムフェード: 画面下20%が背景に溶ける
- チップ: ヘッドライン直下、アクセントカラーのピルバッジ
