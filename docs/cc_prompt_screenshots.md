# App Storeスクショ生成 — 完全自立型CCプロンプト

> このプロンプトを丸ごとCCに貼れ。全ステップを順番に自立実行する。
> 各ステップにチェックポイントがある。チェックに失敗したらそのステップをやり直せ。
> ユーザーに聞くな。自分で判断しろ。ただし「判断できない」場合だけ聞け。

---

## ⚠️ 絶対ルール

### 画像の扱い（フリーズ防止 — 最重要）
シミュレーターのスクショは 1290×2796px あり、そのままAPIに送るとフリーズする。
**確認用は必ず sips -Z 800 でリサイズしてから読め。**
```bash
sips -Z 800 /path/to/original.png --out /tmp/check_small.png
```
**元画像（1290×2796）は絶対にAPIに送るな。リサイズした画像のみ読め。**

### 触るなファイル
- LocalizationManager.swift
- その他MuscleMap本体のSwiftファイルすべて（MuscleMap/*.swift）
- docs/DESIGN_SYSTEM.md
- CLAUDE.md

このタスクでは `skills/app-store-screenshots/` 配下と `/tmp/` のみ触る。

### シミュレーター
既存のシミュレーター（booted含む）は絶対に触るな。
専用シミュレーターを新規作成し、そのUDIDのみで操作すること。

---

## Phase 1: 環境セットアップ

### Step 1.1: リポジトリ準備
```bash
cd /Users/og3939397/MuscleMap
git pull origin main
```

**✅ チェック:** `skills/app-store-screenshots/generator/package.json` が存在すること。
```bash
test -f skills/app-store-screenshots/generator/package.json && echo "PASS" || echo "FAIL"
```
FAILなら `git pull origin main` をやり直せ。

### Step 1.2: npm install
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator
npm install
```

**✅ チェック:** `node_modules` ディレクトリが存在すること。
```bash
test -d node_modules && echo "PASS" || echo "FAIL"
```

### Step 1.3: 専用シミュレーター作成
```bash
SCREENSHOT_UDID=$(xcrun simctl create "MuscleMap-Screenshots" "iPhone 16 Pro Max")
echo "UDID: $SCREENSHOT_UDID"
```

**以降すべてのsimctl操作で `$SCREENSHOT_UDID` を使え。`booted` は絶対に使うな。**

### Step 1.4: シミュレーター起動 & アプリビルド
```bash
xcrun simctl boot $SCREENSHOT_UDID

cd /Users/og3939397/MuscleMap
xcodebuild -project MuscleMap.xcodeproj -scheme MuscleMap \
  -destination "id=$SCREENSHOT_UDID" \
  -derivedDataPath /tmp/mm-screenshots \
  build 2>&1 | tail -5

xcrun simctl install $SCREENSHOT_UDID /tmp/mm-screenshots/Build/Products/Debug-iphonesimulator/MuscleMap.app
xcrun simctl launch $SCREENSHOT_UDID com.buildinpublic.MuscleMap
```

**✅ チェック:** アプリが起動していること。
```bash
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/boot_check.png
sips -Z 800 /tmp/boot_check.png --out /tmp/boot_check_small.png
```
`/tmp/boot_check_small.png` を読んで、MuscleMapの画面が表示されていることを確認。
表示されていなければ:
1. `xcrun simctl terminate $SCREENSHOT_UDID com.buildinpublic.MuscleMap`
2. 5秒待つ
3. `xcrun simctl launch $SCREENSHOT_UDID com.buildinpublic.MuscleMap`
4. 再チェック

**Phase 1完了。ユーザーに報告:**
「Phase 1完了。専用シミュレーター（UDID: xxx）でMuscleMapが起動しています。
アプリの状態を確認してください。ルーティンが未設定の場合、手動でオンボーディングを完了してからPhase 2に進むよう指示してください。
もしすでにデータがある状態なら "Phase 2に進め" と言ってください。」

---

## Phase 2: スクショキャプチャ

**Phase 2開始前の確認:** ユーザーから「Phase 2に進め」の指示があること。

### 共通手順（各ショットで繰り返す）
1. スクショ撮影
2. リサイズして確認
3. 品質チェック（以下の基準すべてクリア）
4. OKならpublic/screenshotsにコピー
5. 次のショットへ

### 品質チェック基準
各スクショを `/tmp/shot{N}_small.png` で目視確認し、以下をチェック:
- [ ] アプリUIが表示されている（真っ黒/白ではない）
- [ ] ステータスバーが見えている（時刻表示あり）
- [ ] UIが途中の遷移アニメーション中ではない（完全に表示完了している）
- [ ] ダイアログやアラートが被さっていない
- [ ] 意図した画面が表示されている

1つでも不合格 → 3秒待って再キャプチャ。3回失敗したらユーザーに報告。

### Shot 1: ホーム画面（回復マップ）
**撮りたい画面:** ホームタブが表示されている状態。回復マップ（筋肉の色付き）が見えること。
```bash
sleep 2
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot1_raw.png
sips -Z 800 /tmp/shot1_raw.png --out /tmp/shot1_small.png
```
`/tmp/shot1_small.png` を読んで品質チェック。OKなら:
```bash
cp /tmp/shot1_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot1_screen.png
echo "Shot 1: PASS"
```

### Shot 2: ワークアウト完了画面
**撮りたい画面:** ワークアウト完了後の画面。チェックマーク、ボリューム数値、刺激した筋肉マップが見えること。
**注意:** この画面はワークアウトを完了しないと表示できない。

まずホーム画面からワークアウトを開始する必要がある。
UIオートメーションでタップ操作が必要。以下を試す:
```bash
# ワークアウトタブに移動
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot2_pre.png
sips -Z 800 /tmp/shot2_pre.png --out /tmp/shot2_pre_small.png
```
`/tmp/shot2_pre_small.png` を読んで現在の画面状態を確認。

**もしワークアウト完了画面にたどり着けない場合:**
ユーザーに報告: 「Shot 2（ワークアウト完了画面）はUI操作が必要です。シミュレーターで手動でワークアウトを完了させてから "shot2を撮れ" と言ってください。」

Shot 2のキャプチャ指示が来たら:
```bash
sleep 1
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot2_raw.png
sips -Z 800 /tmp/shot2_raw.png --out /tmp/shot2_small.png
```
品質チェック → OKなら:
```bash
cp /tmp/shot2_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot2_screen.png
echo "Shot 2: PASS"
```

### Shot 3: ホーム画面（TodayActionCard + Day切替タブ）
**撮りたい画面:** ホーム画面で、TodayActionCardとDay切替タブが表示されている状態。
```bash
# ホームタブに戻す（タブバーの一番左）
sleep 2
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot3_raw.png
sips -Z 800 /tmp/shot3_raw.png --out /tmp/shot3_small.png
```
品質チェック。OKなら:
```bash
cp /tmp/shot3_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot3_screen.png
echo "Shot 3: PASS"
```
**注意:** shot1とshot3は同じホーム画面だが、表示内容が違う場合がある（スクロール位置やDay切替状態）。ユーザーにshot1との違いを説明して確認を求めろ。

### Shot 4: 種目ライブラリ
**撮りたい画面:** 種目辞典タブ。2列グリッドでGIFカードが表示されていること。
```bash
# 種目辞典タブへの移動が必要
sleep 2
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot4_pre.png
sips -Z 800 /tmp/shot4_pre.png --out /tmp/shot4_pre_small.png
```
現在の画面を確認。種目辞典タブが表示されていなければ、ユーザーに「種目辞典タブに切り替えてから "shot4を撮れ" と言ってください」と報告。

種目辞典タブが表示されている場合:
```bash
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot4_raw.png
sips -Z 800 /tmp/shot4_raw.png --out /tmp/shot4_small.png
```
品質チェック → OKなら:
```bash
cp /tmp/shot4_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot4_screen.png
echo "Shot 4: PASS"
```

### Shot 5: PR祝福画面
**撮りたい画面:** ワークアウト完了時にPRが発生した場合の祝福表示。ゴールドのPRバッジが見えること。
**注意:** shot2と同様、UIインタラクションが必要。ユーザーに操作を依頼する可能性あり。

手順はshot2と同じ。撮影指示が来たら:
```bash
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot5_raw.png
sips -Z 800 /tmp/shot5_raw.png --out /tmp/shot5_small.png
```
品質チェック → OKなら:
```bash
cp /tmp/shot5_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot5_screen.png
echo "Shot 5: PASS"
```

### Shot 6: Strength Map
**撮りたい画面:** Strength Mapタブ。筋肉の太さ（S〜Dグレード）が表示されている状態。

```bash
sleep 2
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot6_pre.png
sips -Z 800 /tmp/shot6_pre.png --out /tmp/shot6_pre_small.png
```
Strength Map画面が表示されていなければ、ユーザーに切り替えを依頼。

表示されている場合:
```bash
xcrun simctl io $SCREENSHOT_UDID screenshot /tmp/shot6_raw.png
sips -Z 800 /tmp/shot6_raw.png --out /tmp/shot6_small.png
```
品質チェック → OKなら:
```bash
cp /tmp/shot6_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot6_screen.png
echo "Shot 6: PASS"
```

### Phase 2完了チェック
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots
TOTAL=$(ls shot*_screen.png 2>/dev/null | wc -l | tr -d ' ')
echo "Captured: $TOTAL / 6 shots"
if [ "$TOTAL" -ge 4 ]; then echo "PHASE 2: PASS (enough for preview)"; else echo "PHASE 2: NEED MORE SHOTS"; fi
```

最低4枚あればPhase 3に進める。6枚揃ってなくてもプレビュー確認に進んでいい。

**Phase 2完了報告:**
「Phase 2完了。{N}/6枚のスクショをキャプチャしました。
キャプチャ済み: [ファイル名リスト]
未キャプチャ: [ファイル名リスト]
Phase 3（プレビュー確認）に進みますか？」

---

## Phase 3: プレビュー確認

### Step 3.1: dev server起動
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator
npm run dev &
DEV_PID=$!
echo "Dev server PID: $DEV_PID"
sleep 5
```

**✅ チェック:** サーバーが起動していること。
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
```
200が返ればPASS。起動に時間がかかる場合は5秒追加で待つ。

### Step 3.2: ユーザーに確認依頼
ユーザーに報告:
「dev serverが http://localhost:3000 で起動しています。
ブラウザで開いて、以下を確認してください:
1. 6枚（または用意できた枚数）のプレビューが表示されるか
2. iPhoneフレームにスクショが正しくはまっているか
3. コピーテキスト（見出し・サブコピー）が読みやすいか
4. 言語切替（ja/en等）が動くか

確認が終わったら:
- OKなら "Phase 4に進め"
- 修正が必要なら具体的に教えてください」

---

## Phase 4: 書き出し & クリーンアップ

### Step 4.1: ユーザーに書き出し指示
ユーザーに報告:
「ブラウザで http://localhost:3000 を開いて、各ショットの "Export All Sizes" ボタンをクリックしてください。
各ショットにつき4サイズ（6.9", 6.5", 6.3", 6.1"）のPNGが自動ダウンロードされます。

全ショット書き出したら "完了" と言ってください。」

### Step 4.2: クリーンアップ
書き出し完了の報告が来たら:
```bash
# dev server停止
kill $DEV_PID 2>/dev/null

# 専用シミュレーター削除（任意）
# xcrun simctl delete $SCREENSHOT_UDID
```

ユーザーに確認:
「専用シミュレーター "MuscleMap-Screenshots" を削除しますか？ (yes/no)」
yesなら `xcrun simctl delete $SCREENSHOT_UDID` を実行。

### 最終報告
「App Storeスクショ生成が完了しました。

📊 結果:
- キャプチャ: {N}/6 ショット
- 書き出し: 各ショット × 4サイズ = {N*4} ファイル
- 出力先: ブラウザのダウンロードフォルダ

📋 App Store Connectへのアップロード:
1. App Store Connect → アプリ → バージョン → メディア
2. 6.9" のスクショをアップロード（他サイズは自動スケール）
3. 日本語・英語それぞれにアップロード

🧹 クリーンアップ:
- シミュレーター: {削除済み or 残存}
- /tmp/mm-screenshots: 必要なければ手動削除」
