# Claude Code グローバル設定

このディレクトリには Claude Code のグローバル設定が含まれています。

## 構成

```
claude/
├── settings.json      # グローバル設定
├── commands/          # カスタムコマンド
│   ├── codex-review-pr.md
│   ├── codex-review.md
│   └── git/
│       └── commit.md
├── skills/            # カスタムスキル
│   └── git-wt/
│       └── SKILL.md
├── setup.sh           # セットアップスクリプト
└── README.md
```

## セットアップ

新しい環境で以下を実行:

```bash
cd ~/develop/dotfiles/claude
./setup.sh
```

これにより `~/.claude/` にシンボリックリンクが作成されます。

## 含まれる設定

### settings.json

- **permissions**: Bash コマンドの許可/拒否ルール
- **enabledPlugins**: 有効なプラグイン一覧
- **alwaysThinkingEnabled**: Thinking mode 有効化

### コマンド

| コマンド | 説明 |
|---------|------|
| `/codex-review-pr` | Codex CLI で PR レビュー |
| `/codex-review` | Codex CLI でコードレビュー |
| `/commit` | Conventional Commits 形式でコミット |

### スキル

| スキル | 説明 |
|-------|------|
| `git-wt` | git worktree wrapper（並列開発用） |
