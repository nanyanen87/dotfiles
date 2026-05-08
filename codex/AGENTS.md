# Codex Code Review Instructions

このファイルはコードレビュー時のガイドライン（Source of Truth）。
`codex-review-pr` スクリプトが PR レビュー実行用の一時 worktree ルートに **AGENTS.md として複製** することで Codex に読み込ませる。

`~/.codex/AGENTS.md`（グローバル）はバグでロードされない（[openai/codex#8759](https://github.com/openai/codex/issues/8759)）ため、worktree への注入経路を採用している。

## Code Review

以下のルールでレビューを実施する。

### レビュー対象

- `--base <BRANCH>` / `--commit <SHA>` / `--uncommitted` で指定された差分のみが対象
- 差分外のファイルは「依存関係を理解するために最低限必要な範囲」のみ参照する
- **テストコードの不足は指摘しない**（テストカバレッジは別系統で監査される）

### 観点（優先度順）

1. **Code Correctness** — ロジックエラー、エッジケース、エラーハンドリング、型安全性
2. **Project Conventions** — リポジトリ直下の `AGENTS.md` / `CLAUDE.md` を読み、命名・レイヤー境界・ディレクトリ規約に従っているか
3. **Performance** — アルゴリズム複雑度、N+1 クエリ、不要な再計算
4. **Security** — 入力検証、認証 / 認可、データ露出、依存の既知脆弱性、SQL/XSS/コマンドインジェクション

### 出力フォーマット

レビュー結論は以下の構造で 1 つのメッセージにまとめる。

```
## Critical (must fix)
- [path:line] 問題の簡潔な説明と修正案

## Important (should fix)
- [path:line] ...

## Minor (consider)
- [path:line] ...

## Notes
- 設計判断に対する所見（任意）
```

問題が無い場合は `No issues found.` のみ返す。

### 禁止事項

- PR の概要要約・一般的なコメントは出さない（指摘のみ）
- 「テストを追加すべき」は書かない
- 推測のみのコメントは出さない（コードを読んで根拠を示す）
- ファイルへの書き込み・コミット・PR コメント投稿は行わない（read-only でレビュー結果を返すのみ）

## General Behavior

- 日本語で応答する
- ファイル参照は `path:line` 形式
- 不明点はユーザーに確認せず、可能な限りコードから推論する
