---
name: codex-consult
description: Codex CLI とセッション継続可能な対話を行うスキル。設計相談・コードレビュー・疑問点の壁打ちに使用。同一セッション内で文脈を維持したまま追加質問ができる。
---

# Codex Consult Skill

## 概要

Codex CLI (`codex exec`) を使って設計相談やコードレビューを行う。**セッション継続**により、同一の会話コンテキストを維持したまま追加質問・follow-up ができる。

## 前提条件

| 必須ツール | インストール方法 |
|-----------|-----------------|
| Codex CLI | Cursor 拡張 or `npm install -g @openai/codex` |

### 事前確認

```bash
codex --version 2>/dev/null || echo "codex not installed"
```

## コマンド体系

### 新規セッション開始

```bash
codex exec --full-auto "<プロンプト>" < /dev/null
```

### セッション継続（同一コンテキスト）

```bash
# セッションIDを指定して resume
codex exec resume --full-auto <SESSION_ID> "<追加の質問>" < /dev/null

# 直前のセッションを resume
codex exec resume --full-auto --last "<追加の質問>" < /dev/null
```

### セッションID の取得

出力の冒頭にある `session id: <UUID>` 行から取得する。

## Claude の実行フロー

### 重要: フォアグラウンド実行を基本とする

`codex exec` は **フォアグラウンド**（`run_in_background` なし）で実行すること。
バックグラウンド実行するとユーザーが次のメッセージを送るまで完了通知が届かず、会話が止まる。

Codex は実行に 1〜3 分かかるのが通常。フォアグラウンドで実行し、`timeout: 300000` (5分) を設定する。

### Phase 1: 新規相談の開始

1. `codex exec --full-auto "..." < /dev/null` でプロンプトを送信（**フォアグラウンド、timeout: 300000**）
2. 出力から `session id` を抽出して保持
3. 結果をユーザーに報告

### Phase 2: follow-up（セッション継続）

1. 保持している `session id` を使って `codex exec resume --full-auto <SESSION_ID> "<質問>"` を実行
2. 前回の会話コンテキストが引き継がれた状態で回答が返る
3. 結果をユーザーに報告

### Phase 3: 別セッションへの切り替え

新しいトピックや別の相談を始める場合は、Phase 1 に戻って新規セッションを開始する。

## セッションID の管理

Claude は会話中、以下の情報を追跡する:

- **現在のセッションID**: 最後に使った Codex セッションの UUID
- **セッションの目的**: 何について相談しているか（例: "Issue #205 の設計相談"）

セッションIDは Codex の出力冒頭 `session id:` 行から取得する:

```
session id: 019cf7ac-aed6-7013-9418-d6e6c723d342
```

## プロンプト作成のベストプラクティス

### 重要: Codex にコードを自分で読ませる

プロンプトにコードや diff を埋め込まない。Codex は `--full-auto` でファイルを自分で読める。
コードを埋め込むとトークンが無駄に消費され、実行時間が大幅に増加する。

**悪い例**（diff 埋め込み — 遅い、トークン浪費）:
```bash
DIFF=$(gh pr diff 123)
codex exec --full-auto "以下の diff をレビューしてください。$DIFF"
```

**良い例**（Codex に自分で読ませる — 速い）:
```bash
codex exec --full-auto "PR #123 の変更をレビューしてください。gh pr diff 123 で diff を取得して確認してください。" < /dev/null
```

### 設計相談

```bash
codex exec --full-auto "$(cat <<'PROMPT'
[背景・コンテキスト]

[具体的な質問]

関連ファイルを確認して回答してください。
PROMPT
)" < /dev/null
```

### コードレビュー

```bash
codex exec --full-auto "$(cat <<'PROMPT'
以下の実装プランをレビューしてください。

## プラン概要
[プランの内容（簡潔に）]

## 変更ファイル
[ファイルパス一覧]

コードベースの関連ファイルを確認して、問題点・見落とし・改善提案を指摘してください。
PROMPT
)" < /dev/null
```

### follow-up（セッション継続）

```bash
codex exec resume --full-auto <SESSION_ID> "$(cat <<'PROMPT'
前回の回答を踏まえて追加の質問です。

[追加の質問]
PROMPT
)" < /dev/null
```

## 出力の読み取り

Codex の出力は以下の構造:

```
session id: <UUID>        ← セッションID（保持する）
--------
user                      ← ユーザープロンプト
...
codex                     ← Codex の思考・応答
...
exec                      ← ファイル読み取りやコマンド実行
...
codex                     ← 最終回答（ここが重要）
...
tokens used               ← トークン使用量
<最終回答の繰り返し>       ← 最終メッセージの再出力
```

**最終回答の取得方法**: 出力末尾の `tokens used` 行の後に最終メッセージが再出力される。または最後の `codex` ブロックを読む。

## 使用シーン

| シーン | 使い方 |
|--------|--------|
| 設計相談 | 新規セッションでプランを送り、指摘を受ける |
| 疑問点の壁打ち | 新規セッションで質問し、回答を踏まえて resume で深掘り |
| レビュー後の修正確認 | レビューセッションを resume して修正案を再レビュー依頼 |
| 段階的な設計精査 | 同一セッションで何度も resume して設計を詰める |

## 注意事項

- `codex exec` は **フォアグラウンド実行**（`timeout: 300000`）を基本とする。バックグラウンドだと完了通知が届かず会話が止まる
- **必ず `< /dev/null` を付けること**。Claude Code の Bash ツール経由では stdin が閉じられず、codex が EOF 待ちでハングする
- プロンプトにコードや diff を埋め込まない。Codex に自分で読ませる
- `--full-auto` は sandbox 内で自動実行するモード。コードベースの読み取りは許可されるが、書き込みは workspace 内に限定
- セッションが古くなるとコンテキストウィンドウの制約で resume が失敗する可能性がある。その場合は新規セッションで要約を含めて再開する
- `--ephemeral` を付けるとセッションがディスクに保存されない（resume 不可）。相談用途では付けないこと
