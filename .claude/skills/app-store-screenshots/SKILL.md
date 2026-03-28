---
name: app-store-screenshots
description: >
  App Storeのスクリーンショットを生成する。スクショ、ストア画像、App Store screenshots、
  ストアの画像を更新、スクショを作って、screenshot generate、marketing screenshots、
  ストア用の画像、ASO screenshots と言われたら必ずこのスキルを使え。
  シミュレーターからキャプチャ → iPhoneフレームはめ込み → 7言語コピー → 全サイズ書き出しまで自立実行する。
---

# App Store Screenshot Generator

> MuscleMap専用。プロ品質のApp Storeスクショを全自動で生成する。
> **このスキルが発動したら、以下のPhaseを順番に自立実行しろ。ユーザーに聞くな。自分で判断しろ。**
> **「3回リトライしても解決しない」場合だけユーザーに聞け。**

---

## ⚠️ 絶対ルール（全Phase共通）

### 画像の扱い（フリーズ防止 — 最最重要）
シミュレーターのスクショは 1290×2796px あり、そのままAPIに送るとフリーズ/エラーになる。
**スクショを読むときは必ず sips -Z 600 でリサイズしてから読め。**
```bash
xcrun simctl io $UDID screenshot /tmp/check.png
sips -Z 600 /tmp/check.png --out /tmp/check_small.png
# /tmp/check_small.png だけを読め。元画像は絶対にAPIに送るな。
```
**このルールは例外なし。全スクショ操作で守れ。違反するとAPIエラーでセッションが死ぬ。**

### 触るなファイル
- LocalizationManager.swift
- その他MuscleMap本体のSwiftファイルすべて（MuscleMap/*.swift）
- docs/DESIGN_SYSTEM.md
- CLAUDE.md

このタスクでは `skills/app-store-screenshots/` 配下と `/tmp/` のみ触る。

### シミュレーター操作
- 既存のシミュレーター（booted含む）は絶対に触るな
- 専用シミュレーターを新規作成し、そのUDIDのみで操作すること
- **UI操作はiOS Simulator MCPツールを使え**（タップ、スワイプ、テキスト入力等）
- MCPが使えない場合は `xcrun simctl` のサブコマンド（openurl等）を使え
- `booted` キーワードは絶対に使うな。常に `$UDID` を指定しろ

### シミュレーターUI操作の方法
MCPのシミュレーターツールでタップ・スワイプ等が可能。
画面のどこをタップすべきか判断するために:
1. スクショを撮る（sips -Z 600でリサイズ）
2. リサイズ画像を読んで画面レイアウトを把握
3. タップすべき座標を計算（元画像の座標系で指定）
4. MCPツールでタップ実行
5. 1秒待つ
6. 再度スクショを撮って遷移を確認

**座標計算の注意:**
- スクショは 1290×2796px（iPhone 16 Pro Max、3xスケール）
- 論理座標は 430×932pt
- MCPのタップ座標は論理座標（pt）で指定する
- 画像の座標(px) ÷ 3 = 論理座標(pt)
- 例: 画像上で(645, 2700)にあるボタン → タップ座標は(215, 900)

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
UDID=$(xcrun simctl create "MuscleMap-Screenshots" "iPhone 16 Pro Max")
echo "UDID: $UDID"
```

**以降すべてのsimctl操作で `$UDID` を使え。`booted` は絶対に使うな。**

### Step 1.4: シミュレーター起動 & アプリビルド
```bash
xcrun simctl boot $UDID

cd /Users/og3939397/MuscleMap
xcodebuild -project MuscleMap.xcodeproj -scheme MuscleMap \
  -destination "id=$UDID" \
  -derivedDataPath /tmp/mm-screenshots \
  build 2>&1 | tail -5

xcrun simctl install $UDID /tmp/mm-screenshots/Build/Products/Debug-iphonesimulator/MuscleMap.app
xcrun simctl launch $UDID com.buildinpublic.MuscleMap
sleep 3
```

**✅ チェック:** アプリが起動していること。
```bash
xcrun simctl io $UDID screenshot /tmp/boot_check.png
sips -Z 600 /tmp/boot_check.png --out /tmp/boot_check_small.png
```
`/tmp/boot_check_small.png` を読んで、MuscleMapの画面が表示されていることを確認。
表示されていなければ:
1. `xcrun simctl terminate $UDID com.buildinpublic.MuscleMap`
2. `sleep 3`
3. `xcrun simctl launch $UDID com.buildinpublic.MuscleMap`
4. `sleep 3` → 再チェック

---

## Phase 1.5: オンボーディング完了（必要な場合）

スクショを読んで「ルーティンを設定しよう」や「オンボーディング」画面が表示されている場合、自動で完了させる。
すでにホーム画面（タブバーが見える、回復マップが表示）なら、このPhaseをスキップしてPhase 2へ。

### オンボーディングの進め方
1. スクショを撮って現在の画面を確認（**必ず sips -Z 600 でリサイズしてから読め**）
2. 画面上のボタン・選択肢を読み取る
3. MCPのタップツールで操作する
4. 1秒待つ
5. 再度スクショで次の画面を確認
6. ホーム画面が出るまで繰り返す

### オンボーディングでの選択方針
- **目標:** 「筋肥大」を選択（最も一般的で映える）
- **頻度:** 「週4回」を選択
- **場所:** 「ジム」を選択
- **経験:** 「中級者」を選択
- その他の選択肢は最もポピュラーなものを選べ
- 「ルーティンを作成」「次へ」「始める」系のCTAは即タップ
- 「ルーティンなしで始める」は使うな。必ずルーティンを作成しろ（スクショ映えのため）

### オンボーディング完了チェック
ホーム画面（タブバーが見える、回復マップが表示されている）が出たらオンボーディング完了。
Phase 2に自動的に進め。

---

## Phase 2: スクショキャプチャ

### 共通手順（全ショット共通）
```bash
# 1. スクショ撮影
xcrun simctl io $UDID screenshot /tmp/shot{N}_raw.png

# 2. 確認用リサイズ（必ずやれ！！）
sips -Z 600 /tmp/shot{N}_raw.png --out /tmp/shot{N}_small.png

# 3. /tmp/shot{N}_small.png を読んで品質チェック
```

### 品質チェック基準（全項目クリアで合格）
- [ ] アプリUIが表示されている（真っ黒/白ではない）
- [ ] ステータスバーが見えている
- [ ] UIが遷移アニメーション中ではない（完全に表示完了）
- [ ] ダイアログやアラートが被さっていない
- [ ] 意図した画面が表示されている

1つでも不合格 → `sleep 2` → 再キャプチャ。3回失敗したらユーザーに報告。

### 合格時の保存
```bash
cp /tmp/shot{N}_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot{N}_screen.png
echo "Shot {N}: PASS"
```

---

### Shot 1: ホーム画面（回復マップ）
**目標:** ホームタブ表示中。回復マップ（筋肉の色付き）が見えること。

1. スクショを撮って現状確認（リサイズ必須）
2. ホームタブにいなければ、タブバー左端をタップして移動
3. 回復マップが見える状態でキャプチャ

---

### Shot 2: ワークアウト完了画面
**目標:** チェックマーク、ボリューム数値、刺激した筋肉マップが見える完了画面。

**自動操作手順:**
1. ホーム画面から「ワークアウト」タブ（タブバー2番目）をタップ
2. スクショで確認 → ワークアウト画面に遷移したか
3. 種目を1つ選択（最初に表示される種目をタップ）
4. セット入力画面で:
   - 重量を入力（デフォルト値でOK）
   - レップ数を入力（10を選択）
   - 「セットを記録」をタップ
5. 最低1セット記録したら「ワークアウト完了」ボタンを探してタップ
6. 完了画面が表示されたらキャプチャ

各ステップでスクショを撮って画面を確認しながら進めろ。
ボタンの位置は画面を読んで座標を計算しろ。

---

### Shot 3: ホーム画面（TodayActionCard）
**目標:** TodayActionCardとDay切替タブが見えるホーム画面。

1. 完了画面を閉じる（「閉じる」ボタンをタップ）
2. ホームタブに戻る
3. ワークアウト完了後なのでマップの色が変わっているはず。そのままキャプチャ。

---

### Shot 4: 種目ライブラリ
**目標:** 種目辞典タブ。2列グリッドでGIFカードが複数表示されていること。

1. タブバーの「種目辞典」タブ（3番目）をタップ
2. スクショで確認
3. 2列グリッドでGIFカードが表示されていること
4. キャプチャ

---

### Shot 5: PR祝福画面
**目標:** PRが発生した完了画面。ゴールドのPRバッジが見えること。

**自動操作手順:**
1. ホームタブに戻る → ワークアウトタブへ
2. 種目を選択
3. 前回よりも重い重量でセットを記録（重量ステッパーで+5kg）
4. ワークアウトを完了
5. PR祝福が表示されたらキャプチャ

**PR祝福が表示されない場合:**
Shot 2の完了画面をShot 5にも流用してOK。
```bash
cp /tmp/shot2_raw.png /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots/shot5_screen.png
echo "Shot 5: REUSED from Shot 2"
```

---

### Shot 6: Strength Map
**目標:** Strength Mapタブ。筋肉の太さ（グレード）が表示されている状態。

1. ホーム画面に戻る
2. 「Strength Map」ボタンを探してタップ（ホーム画面下部にカードがあるはず）
3. Strength Map画面が表示されたらキャプチャ

---

### Phase 2完了チェック
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator/public/screenshots
echo "=== Captured screenshots ==="
ls -la shot*_screen.png 2>/dev/null
TOTAL=$(ls shot*_screen.png 2>/dev/null | wc -l | tr -d ' ')
echo "Total: $TOTAL / 6"
if [ "$TOTAL" -ge 4 ]; then echo "PHASE 2: PASS"; else echo "PHASE 2: NEED MORE"; fi
```

最低4枚あれば自動的にPhase 3に進め。

---

## Phase 3: プレビュー確認

### Step 3.1: dev server起動
```bash
cd /Users/og3939397/MuscleMap/skills/app-store-screenshots/generator
npx next dev -p 3456 &
DEV_PID=$!
sleep 8
```

**ポート3456を使う**（3000は他で使ってる可能性があるため）。

**✅ チェック:**
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3456
```
200が返ればPASS。

### Step 3.2: ユーザーに確認依頼
「Phase 3完了。dev serverが http://localhost:3456 で起動しています。
ブラウザで開いて確認してください:

1. スクショがiPhoneフレームに正しくはまっているか
2. コピーテキスト（見出し・サブコピー）が読みやすいか
3. 言語切替（ja/en等）が動くか

確認後:
- OKなら "Phase 4に進め"
- 修正が必要なら教えてください」

---

## Phase 4: 書き出し & クリーンアップ

### Step 4.1: 書き出し指示
「ブラウザで http://localhost:3456 の各ショットの "Export All Sizes" をクリックしてください。
各ショット × 4サイズ = PNGが自動ダウンロードされます。
完了したら "完了" と言ってください。」

### Step 4.2: クリーンアップ
```bash
kill $DEV_PID 2>/dev/null
```

「専用シミュレーター "MuscleMap-Screenshots" を削除しますか？ (yes/no)」
yesなら:
```bash
xcrun simctl shutdown $UDID
xcrun simctl delete $UDID
```

### 最終報告
「App Storeスクショ生成が完了しました。

📊 結果:
- キャプチャ: {N}/6 ショット
- 書き出し: 各ショット × 4サイズ
- 出力先: ブラウザのダウンロードフォルダ

📋 App Store Connectへのアップロード:
1. App Store Connect → アプリ → バージョン → メディア
2. 6.9" のスクショをアップロード（他サイズは自動スケール）
3. 日本語・英語それぞれにアップロード」

---

## 技術仕様リファレンス

### 出力サイズ
| ディスプレイ | 解像度 |
|:---|:---|
| 6.9" (必須ベース) | 1320 x 2868 |
| 6.5" | 1284 x 2778 |
| 6.3" | 1206 x 2622 |
| 6.1" | 1125 x 2436 |

### MuscleMapブランド
- 背景: `#070A07`
- プライマリアクセント: `#00FFB3`
- セカンダリアクセント: `#00D4FF`
- PRアクセント: `#FFD700`

### ショット定義
| # | 見出し（JA） | アクセント | 画面 |
|:--|:---|:--|:---|
| 1 | 昨日の筋トレ、今どこに残ってる？ | #00FFB3 | ホーム（回復マップ） |
| 2 | 今日、ここを鍛えた | #00FFB3 | ワークアウト完了 |
| 3 | 今日やるべき種目、自動で | #00FFB3 | ホーム（Day切替タブ） |
| 4 | 92種目、全部動く | #00D4FF | 種目ライブラリ |
| 5 | 前回を超えろ | #FFD700 | PR祝福 |
| 6 | どこに効くか、数値で見る | #00D4FF | Strength Map |

### ファイル構造
```
skills/app-store-screenshots/
├── SKILL.md              ← 旧スキルファイル（参照用に残す）
└── generator/
    ├── package.json
    ├── src/
    │   ├── copy.ts       ← 7言語コピー辞書
    │   └── app/
    │       ├── layout.tsx
    │       ├── globals.css ← iPhoneフレームCSS
    │       └── page.tsx   ← メイン生成コンポーネント
    └── public/screenshots/ ← キャプチャしたスクショ
```
