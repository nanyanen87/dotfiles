---
allowed-tools: Bash
description: "Codex CLI でコードレビューを実行（公式 /review プロンプト使用）"
---

Codex CLI を使って現在の作業ツリーの変更をレビューします。

以下のコマンドを実行してください：

```bash
codex exec --full-auto "$(cat ~/.codex/prompts/review.md)"
```

レビュー結果を待ち、ユーザーに報告してください。
