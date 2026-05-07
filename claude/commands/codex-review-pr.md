---
allowed-tools: Bash, AskUserQuestion
description: "Codex CLI で GitHub PR をレビュー（引数: [owner/repo#]PR番号）"
---

GitHub PR を **Codex CLI** でレビューします。引数 `$ARGUMENTS` に PR 番号（オプションでリポジトリ）が渡されます。

**IMPORTANT**: このスキルは Codex CLI (`codex exec review`) を使って PR レビューを実行する専用スキルです。Claude Code の内蔵エージェント（`feature-dev:code-reviewer` 等）や Task ツールで代替してはいけません。必ず Step 3 の `codex exec review` コマンドを実行してください。

## 引数フォーマット

以下のフォーマットをサポート:
- `123` - 現在のリポジトリの PR #123
- `owner/repo#123` - 指定リポジトリの PR #123
- `owner/repo 123` - 指定リポジトリの PR #123

## 手順

### Step 1: 引数をパース

引数からリポジトリと PR 番号を抽出:

```bash
INPUT="${ARGUMENTS:-}"
if [ -z "$INPUT" ]; then
  echo "Error: PR番号を指定してください（例: /codex-review-pr 123 または /codex-review-pr owner/repo#123）"
  exit 1
fi

# GitHub URL形式をパース（例: https://github.com/owner/repo/pull/123）
if [[ "$INPUT" =~ github\.com/([^/]+/[^/]+)/pull/([0-9]+) ]]; then
  REPO="${BASH_REMATCH[1]}"
  PR_NUM="${BASH_REMATCH[2]}"
  echo "Repository: $REPO"
  echo "PR Number: $PR_NUM"
# owner/repo#123 または owner/repo 123 形式をパース
elif [[ "$INPUT" =~ ^([^/#[:space:]]+/[^#[:space:]]+)[#[:space:]]([0-9]+)$ ]]; then
  REPO="${BASH_REMATCH[1]}"
  PR_NUM="${BASH_REMATCH[2]}"
  echo "Repository: $REPO"
  echo "PR Number: $PR_NUM"
elif [[ "$INPUT" =~ ^[0-9]+$ ]]; then
  REPO=""
  PR_NUM="$INPUT"
  echo "Repository: (current)"
  echo "PR Number: $PR_NUM"
else
  echo "Error: 無効なフォーマットです。以下の形式で指定してください:"
  echo "  /codex-review-pr 123"
  echo "  /codex-review-pr owner/repo#123"
  echo "  /codex-review-pr owner/repo 123"
  echo "  /codex-review-pr https://github.com/owner/repo/pull/123"
  exit 1
fi
```

### Step 2: PR の情報を取得

```bash
if [ -n "$REPO" ]; then
  gh pr view "$PR_NUM" -R "$REPO" --json title,body,baseRefName,headRefName
else
  gh pr view "$PR_NUM" --json title,body,baseRefName,headRefName
fi
```

### Step 3: 対象リポジトリに移動して `codex exec review` を実行

**重要**: `codex exec --full-auto "$PROMPT"` は Claude Code の Bash ツール経由だと stdin が閉じられず EOF 待ちでハングする。必ず `codex exec review` サブコマンドを使うこと。

```bash
# base/head ブランチ名を取得
if [ -n "$REPO" ]; then
  BASE_BRANCH=$(gh pr view "$PR_NUM" -R "$REPO" --json baseRefName --jq '.baseRefName')
  HEAD_BRANCH=$(gh pr view "$PR_NUM" -R "$REPO" --json headRefName --jq '.headRefName')

  # ローカルリポジトリパスを解決（org/repo → ~/dev/<org>/<repo-name> or ~/dev/<repo-name>）
  REPO_NAME=$(echo "$REPO" | cut -d'/' -f2)
  ORG_NAME=$(echo "$REPO" | cut -d'/' -f1)

  LOCAL_PATH=""
  for CANDIDATE in \
    "$HOME/dev/$ORG_NAME/$REPO_NAME" \
    "$HOME/dev/stremix/$REPO_NAME" \
    "$HOME/dev/$REPO_NAME" \
    "$HOME/src/$REPO_NAME"; do
    if [ -d "$CANDIDATE/.git" ]; then
      LOCAL_PATH="$CANDIDATE"
      break
    fi
  done

  if [ -z "$LOCAL_PATH" ]; then
    echo "Error: ローカルリポジトリが見つかりません: $REPO_NAME"
    echo "事前に clone してください: gh repo clone $REPO"
    exit 1
  fi

  cd "$LOCAL_PATH"
  git fetch origin "$BASE_BRANCH" "$HEAD_BRANCH"
  git checkout "$HEAD_BRANCH"
else
  BASE_BRANCH=$(gh pr view "$PR_NUM" --json baseRefName --jq '.baseRefName')
  HEAD_BRANCH=$(gh pr view "$PR_NUM" --json headRefName --jq '.headRefName')
  git fetch origin "$BASE_BRANCH" "$HEAD_BRANCH"
  git checkout "$HEAD_BRANCH"
fi

codex exec review --full-auto --base "origin/$BASE_BRANCH" "$(cat ~/.codex/prompts/review-pr.md)"
```

**注意**: `codex exec review` はフォアグラウンド（`timeout: 300000`）で実行すること。バックグラウンドだとユーザーが次のメッセージを送るまで完了通知が届かず、会話が止まる。

レビュー結果をユーザーに報告してください。

---

## AskUserQuestion の使用場面

### リポジトリ選択が必要な場合

引数がなく、複数のリポジトリが想定される場合:

```typescript
AskUserQuestion({
  questions: [
    {
      question: 'どのリポジトリの PR をレビューしますか？',
      header: 'Repository',
      multiSelect: false,
      options: [
        {
          label: '現在のリポジトリ (Recommended)',
          description: 'カレントディレクトリの git リポジトリを使用',
        },
        {
          label: 'リポジトリを指定',
          description: 'owner/repo 形式でリポジトリを指定',
        },
      ],
    },
  ],
});
```

### PR 番号の確認

引数が不完全な場合:

```typescript
AskUserQuestion({
  questions: [
    {
      question: 'レビューする PR 番号を入力してください',
      header: 'PR Number',
      multiSelect: false,
      options: [
        {
          label: '最新の PR',
          description: 'このリポジトリの最新 PR を取得',
        },
        {
          label: 'PR を指定',
          description: 'PR 番号を入力（例: 123）',
        },
      ],
    },
  ],
});
```
