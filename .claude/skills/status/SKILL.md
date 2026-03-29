---
name: status
description: "Obsidian の 02_Current_Status.md を最新データで更新する。ユーザーが /status と言ったとき、または「ステータス更新して」「現在地更新」と言ったときに使う。"
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# /status — Obsidian 現在地ダッシュボード更新

## 概要
`/Users/og3939397/Documents/Obsidian Vault/zDOG/02_Current_Status.md` を
最新の開発データ・数値で更新する。

## 手順

### 1. 現在のステータス読み込み
- ファイル読み込み: `/Users/og3939397/Documents/Obsidian Vault/zDOG/02_Current_Status.md`
- 既存の構造を完全に維持する（セクション順序、フォーマット変更禁止）

### 2. 自動データ収集

#### 開発データ
```bash
# 今週のコミット数
git log --oneline --since="last monday" | wc -l

# 最新コミット
git log --oneline -1

# 直近の主な変更
git log --oneline -10
```

#### MuscleMap コードベース情報
- CLAUDE.md から現在のバージョン・機能状態を読み取る
- 直近のコミットメッセージから進捗を推定

### 3. 更新対象セクション

以下のセクションを最新データで更新する:

#### 🚀 今のフェーズ
- 最新の状態テキスト
- 完了タスクの ✅ マーク更新
- 日付の更新

#### ⏳ 直近のアクション
- 完了したタスクの状態更新
- 新タスクの追加（コミットログから推定）

#### 📈 最新の数字 > 開発
- 今週のコミット数を更新
- CC prompt MD の本数を更新

#### 最終更新行
- `*最終更新: {YYYY-MM-DD HH:MM}（{やっていること}）*` を更新

### 4. 更新ルール
- **既存のセクション構造を絶対に変えない**
- **数値データのみ更新する**（文章の書き換えは最小限）
- **⚠️ 躁状態チェック** セクションは絶対にいじらない
- **💡 忘れるな** セクションの内容は追加のみ（削除禁止）
- **財務データ**はユーザーから明示的に指示があった場合のみ更新
- **Xフォロワー数**はユーザーから明示的に指示があった場合のみ更新
- **体重・PR**はユーザーから明示的に指示があった場合のみ更新

### 5. 出力
- 更新した項目の差分サマリーを表示
- 更新後のファイルパスを伝える

## 注意
- ダッシュボードのフォーマットは 02_Current_Status.md の既存構造に厳密に従う
- Obsidian wiki link の `[[]]` 記法を壊さない
- callout block (`> [!important]`) を壊さない
- ファイルパス: `/Users/og3939397/Documents/Obsidian Vault/zDOG/02_Current_Status.md`
