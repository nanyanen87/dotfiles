---
allowed-tools: Bash, AskUserQuestion
description: "Codex CLI で GitHub PR をレビュー（引数: [owner/repo#]PR番号）"
---

GitHub PR を **Codex CLI** でレビューします。引数 `$ARGUMENTS` に PR 番号（オプションでリポジトリ）が渡されます。

**IMPORTANT**: このスキルは Codex CLI (`codex exec`) を使って PR レビューを実行する専用スキルです。Claude Code の内蔵エージェント（`feature-dev:code-reviewer` 等）や Task ツールで代替してはいけません。必ず Step 3 の `codex exec` コマンドを実行してください。

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

# owner/repo#123 または owner/repo 123 形式をパース
if [[ "$INPUT" =~ ^([^/#[:space:]]+/[^#[:space:]]+)[#[:space:]]([0-9]+)$ ]]; then
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
  exit 1
fi
```

### Step 2: PR の情報と diff を取得

```bash
# 前のステップで取得した REPO と PR_NUM を使用
if [ -n "$REPO" ]; then
  # リポジトリ指定あり
  gh pr view "$PR_NUM" -R "$REPO" --json title,body,baseRefName,headRefName
  gh pr diff "$PR_NUM" -R "$REPO"
else
  # 現在のリポジトリを使用
  gh pr view "$PR_NUM" --json title,body,baseRefName,headRefName
  gh pr diff "$PR_NUM"
fi
```

### Step 3: Codex でレビュー実行

```bash
# 前のステップで取得した REPO と PR_NUM を使用
PROMPT=$(cat ~/.codex/prompts/review-pr.md)

if [ -n "$REPO" ]; then
  DIFF=$(gh pr diff "$PR_NUM" -R "$REPO")
else
  DIFF=$(gh pr diff "$PR_NUM")
fi

codex exec --full-auto "$PROMPT

## PR Diff:
\`\`\`diff
$DIFF
\`\`\`
"
```

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
