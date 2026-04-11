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

### Step 2: PR の情報を取得

```bash
# 前のステップで取得した REPO と PR_NUM を使用
if [ -n "$REPO" ]; then
  gh pr view "$PR_NUM" -R "$REPO" --json title,body,baseRefName,headRefName
else
  gh pr view "$PR_NUM" --json title,body,baseRefName,headRefName
fi
```

### Step 3: Codex でレビュー実行

**重要**: diff をプロンプトに埋め込まない。Codex は `--full-auto` でコマンドを実行できるので、Codex 自身に diff を取得させる。埋め込むとトークンが浪費され実行時間が大幅に増加する。

diff の取得には `gh pr diff` ではなく `git diff` を使う。`.gitattributes` の `linguist-generated=true` パターンをシェルコマンドで自動抽出し、生成物ファイルを除外する。

```bash
# 前のステップで取得した REPO と PR_NUM を使用
PROMPT=$(cat ~/.codex/prompts/review-pr.md)

if [ -n "$REPO" ]; then
  codex exec --full-auto "$PROMPT

対象: $REPO の PR #$PR_NUM
以下の手順で diff を取得してレビューしてください:

1. gh pr view $PR_NUM -R $REPO --json baseRefName,headRefName で base/head ブランチ名を取得
2. git fetch origin <base> <head>
3. 以下のコマンドで .gitattributes の linguist-generated=true パターンを除外して diff を取得:
   EXCLUDES=\$(grep -E 'linguist-generated\s*=\s*true' .gitattributes 2>/dev/null | awk '{print \":(exclude)\" \$1}')
   git diff origin/<base>...origin/<head> -- \$EXCLUDES
"
else
  codex exec --full-auto "$PROMPT

対象: PR #$PR_NUM
以下の手順で diff を取得してレビューしてください:

1. gh pr view $PR_NUM --json baseRefName,headRefName で base/head ブランチ名を取得
2. git fetch origin <base> <head>
3. 以下のコマンドで .gitattributes の linguist-generated=true パターンを除外して diff を取得:
   EXCLUDES=\$(grep -E 'linguist-generated\s*=\s*true' .gitattributes 2>/dev/null | awk '{print \":(exclude)\" \$1}')
   git diff origin/<base>...origin/<head> -- \$EXCLUDES
"
fi
```

**注意**: `codex exec` はフォアグラウンド（`timeout: 300000`）で実行すること。バックグラウンドだとユーザーが次のメッセージを送るまで完了通知が届かず、会話が止まる。

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
