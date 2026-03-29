---
name: daily
description: "デイリーノートを Obsidian vault に生成する。ユーザーが /daily と言ったとき、または「今日のノート書いて」「デイリー作って」と言ったときに使う。"
argument-hint: "[体重kg] [メンタル/10] [睡眠h]"
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# /daily — Obsidian デイリーノート生成

## 概要
今日の日付で Obsidian vault にデイリーノートを生成する。
既存ノートがあれば上書きせず差分マージを提案する。

## 手順

### 1. 日付と既存チェック
- 今日の日付を `YYYY-MM-DD` 形式で取得
- `/Users/og3939397/Documents/Obsidian Vault/zDOG/Daily/{日付}.md` が既に存在するか確認

### 2. 引数パース
- `$ARGUMENTS` から体重(kg)、メンタルスコア(/10)、睡眠時間(h) を抽出
- 未指定の場合はブランクで生成

### 3. 開発データ自動取得
以下を自動で収集する:
- `git log --oneline --since="today 00:00"` で今日のコミット一覧
- `git log --oneline --since="today 00:00" | wc -l` でコミット数
- `git diff --stat HEAD~5` で直近の変更ファイルサマリー

### 4. ノート生成
以下のフォーマットで生成する（テンプレートに厳密に従う）:

```markdown
---
tags: [daily, {YYYY-MM}]
date: {YYYY-MM-DD}
---

# {YYYY-MM-DD}（{曜日}）

[[{前日YYYY-MM-DD}|← 前日]] | [[{翌日YYYY-MM-DD}|翌日 →]]

---

## 📊 データ

| 項目 | 値 |
|------|-----|
| 体重 | {weight}kg |
| 睡眠 | {sleep}時間 |
| メンタル | {mental}/10 |
| トレ | {部位 or 休養} |

---

## 💡 今日の気づき・決断

*(ここはユーザーが後で記入)*

---

## ✅ 今日やったこと

- [ ] 朝ルーティン（卵4個、トマト、プロテイン）
- [ ] トレーニング
- [x] MuscleMap開発（コミット{N}本）
{各コミットを箇条書き}

---

## 🐦 Twitter投稿

*(投稿した内容 or 投稿案をメモ)*

---

## 💬 Claude対話メモ

*(重要な対話があれば要約 or リンク)*

---

## 📝 明日への引き継ぎ

-

---

## 🔗 関連

- [[../Goals/00_Core|核心]]
- [[../02_Current_Status|現在地]]

---

*毎日ベストを尽くす。*
```

### 5. 出力
- ファイルを書き込む
- 生成したパスとサマリーをユーザーに伝える
- 既存ファイルがあった場合は差分を示して確認を求める

## 注意
- 曜日は日本語（月火水木金土日）
- コミットメッセージは原文のまま記載
- テンプレートのフォーマットを崩さない
- ファイルパス: `/Users/og3939397/Documents/Obsidian Vault/zDOG/Daily/`
