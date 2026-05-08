---
allowed-tools: Bash, Read, AskUserQuestion
description: "Codex CLI で GitHub PR をレビュー（引数: [owner/repo#]PR番号）"
---

GitHub PR を **Codex CLI** で第三者レビューする。
レビュー観点は `~/.codex/AGENTS.md` で定義（Codex が自動ロード）。
実行ロジックは `~/.claude/scripts/codex-review-pr.sh` に分離。

**IMPORTANT**: このコマンドは Codex CLI による独立レビューを目的とする。
Claude Code 内蔵エージェントや Task ツールでの代替は禁止。必ず Step 2 のスクリプトを実行する。

## 引数フォーマット

- `123` — 現在のリポジトリの PR #123
- `owner/repo#123` / `owner/repo 123`
- `<repo-name> 123` — `~/dev/<*>/<repo-name>` から自動解決
- `https://github.com/owner/repo/pull/123`

## 手順

### Step 1: 引数チェック

`$ARGUMENTS` が空の場合のみ AskUserQuestion で PR 番号を確認する。
それ以外は引数をそのままスクリプトに渡す（パースはスクリプト側で実施）。

### Step 2: スクリプト実行

```bash
bash ~/.claude/scripts/codex-review-pr.sh "$ARGUMENTS"
```

- `timeout: 600000`（10 分）でフォアグラウンド実行する
- スクリプトの **stdout 末尾の 1 行が最終レビューファイルパス**
- 進捗ログは stderr に出る（Codex の探索ログ含む）

### Step 3: レビュー結果の表示

スクリプト stdout 最終行のパスを `Read` で読み、内容をユーザーに転載する。
Codex の出力は `## Critical / Important / Minor / Notes` 形式（`~/.codex/AGENTS.md` で規定）。

報告フォーマット:

```
## PR
[<title>](<PR URL>)

## Codex Review

<ファイル内容をそのまま貼る>
```

問題が無ければ Codex は `No issues found.` を返す。その場合はその旨を伝える。

## 設計メモ

- **prompt 引数を渡さない**: `codex exec review` は `--base` と PROMPT 引数が排他のため
- **隔離 = 一時 worktree**: `${TMPDIR}/codex-review-pr-<num>` に detached worktree を作って codex を実行。元リポの node_modules や兄弟リポを物理的に見せない
- **観点 = AGENTS.md 注入**: `~/dotfiles/codex/AGENTS.md` を worktree ルートに複製して Codex に読ませる（`~/.codex/AGENTS.md` グローバルは [openai/codex#8759](https://github.com/openai/codex/issues/8759) のバグでロードされない）
- **指示と script の分離**: 観点 = `~/dotfiles/codex/AGENTS.md` / 実行 = `~/.claude/scripts/codex-review-pr.sh` / 呼び出し = 本ファイル
- **`--output-last-message`**: 最終結論のみをファイル化。codex の探索ログを context に取り込まない
