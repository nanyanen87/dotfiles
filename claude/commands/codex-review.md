---
allowed-tools: Bash
description: "Codex CLI でコードレビューを実行（公式 /review プロンプト使用）"
---

Codex CLI を使って現在の作業ツリーの変更をレビューします。

以下のコマンドを実行してください：

```bash
codex exec --full-auto "$(cat ~/.codex/prompts/review.md)"
```

**注意**:
- **フォアグラウンド**（`timeout: 300000`）で実行すること。バックグラウンドだとユーザーが次のメッセージを送るまで完了通知が届かず、会話が止まる
- 変更がない（clean な状態）場合は Codex がレビュー対象なしと報告するので、先に `git status` で変更の有無を確認してもよい

レビュー結果をユーザーに報告してください。
