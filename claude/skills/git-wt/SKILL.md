---
name: git-wt
description: 並列作業・マルチブランチ開発時に git-wt（git worktree wrapper）を活用するスキル。複数タスクの同時進行、レビュー中の別作業、緊急修正対応時に自動的に使用される。
---

# Git Worktree Wrapper (git-wt) Skill

## 概要

**git-wt** は、Git の `git worktree` 機能を簡潔に使えるようにするラッパーツールです。複数のブランチで同時に作業したい場合に、各ブランチを別ディレクトリで管理し、作業コンテキストを分離できます。

- **作者**: k1LoW
- **リポジトリ**: https://github.com/k1LoW/git-wt

---

## このスキルが自動で判断する場面

Claude が以下の場合に **自動的にこのスキルを使用** します：

1. **並列作業の依頼**: 「別ブランチで作業しながら」「同時に複数タスクを」と言われた
2. **レビュー待ち中の作業**: 「PRレビュー待ちの間に別タスク」と要求された
3. **緊急修正対応**: 「hotfix対応しながら現在の作業を維持したい」と言われた
4. **ブランチ切り替えのコスト言及**: 「stashせずに」「作業中の変更を維持したまま」
5. **マルチタスク開発**: 複数のissueやfeatureを同時に進めたい場合

**使用者の明示的な指示は不要** — Claude が文脈から判断します。

---

## Claude の必須フロー: AskUserQuestion によるベースブランチ確認

### ワークツリー作成時の対話フロー

**重要**: 新しいワークツリーを作成する際、Claude は **必ず AskUserQuestion ツールを使用して** ベースブランチを確認すること。

#### 確認が必要な項目

1. **ブランチ名**: 新しく作成するブランチ名
2. **ベースブランチ**: どのブランチから分岐するか

#### AskUserQuestion の使用例

```typescript
// Claude が使用すべき AskUserQuestion の例
AskUserQuestion({
  questions: [
    {
      question: "新しいワークツリーのベースブランチはどれにしますか？",
      header: "Base branch",
      multiSelect: false,
      options: [
        {
          label: "main (Recommended)",
          description: "本番ブランチから分岐。hotfix や新機能開発に最適"
        },
        {
          label: "develop",
          description: "開発ブランチから分岐。進行中の機能を含む"
        },
        {
          label: "現在のブランチ",
          description: `現在の ${currentBranch} から分岐`
        }
      ]
    }
  ]
})
```

#### コンテキストに応じた推奨選択

| ユースケース | 推奨ベースブランチ | 理由 |
|-------------|-------------------|------|
| hotfix / 緊急修正 | main | 本番環境の状態から分岐すべき |
| 新機能開発 | main または develop | プロジェクトのフローに依存 |
| 既存機能の拡張 | 関連する feature ブランチ | コンテキストを引き継ぐ |
| PR レビュー用 | PR のブランチ | そのままチェックアウト |

---

## コマンドリファレンス

### git-wt コマンド（シンプルな場合）

```bash
# ワークツリー一覧
git wt

# 既存ブランチのワークツリーを作成（ベースブランチ選択不要）
git wt feature/existing-branch

# ワークツリー削除（安全）
git wt -d feature/done

# ワークツリー削除（強制）
git wt -D feature/abandoned
```

### ベースブランチを指定する場合（git worktree を直接使用）

**git-wt はベースブランチ指定をサポートしていないため**、新しいブランチをカスタムベースから作成する場合は `git worktree add` を直接使用する：

```bash
# main から新しいブランチを作成
git worktree add -b issues/123 ../project-wt/issues/123 main

# develop から新しいブランチを作成
git worktree add -b feature/new ../project-wt/feature/new develop

# 特定のコミットから新しいブランチを作成
git worktree add -b hotfix/urgent ../project-wt/hotfix/urgent origin/main
```

#### コマンド構文

```bash
git worktree add -b <new-branch> <path> <base-branch>
```

- `<new-branch>`: 新しく作成するブランチ名
- `<path>`: ワークツリーのパス（通常 `../{repo}-wt/{branch}`）
- `<base-branch>`: ベースとなるブランチ（main, develop, origin/main など）

---

## Claude 実行フロー

### 1. 情報収集

```bash
# 現在のブランチを確認
git branch --show-current

# 利用可能なブランチを確認
git branch -a

# 既存のワークツリーを確認
git wt
```

### 2. AskUserQuestion でユーザーに確認

```typescript
// 必須: ベースブランチの確認
AskUserQuestion({
  questions: [
    {
      question: "新しいワークツリーのベースブランチはどれにしますか？",
      header: "Base branch",
      multiSelect: false,
      options: [
        // 状況に応じて適切な選択肢を提示
        // hotfix の場合は main を推奨
        // 新機能の場合は develop または main を推奨
      ]
    }
  ]
})
```

### 3. ワークツリー作成

```bash
# ユーザーが選択したベースブランチに基づいてコマンドを実行

# 例: main をベースにする場合
git worktree add -b issues/123 ../stremix-wt/issues/123 main

# 例: 現在のブランチをベースにする場合（git-wt が使える）
git wt issues/123
```

### 4. 後処理の確認

```bash
# ワークツリーが作成されたことを確認
git wt

# 依存関係のインストール（必要に応じて）
cd ../stremix-wt/issues/123 && pnpm install
```

---

## 設定オプション

git config で設定可能なオプション：

### wt.basedir - ベースディレクトリ

```bash
git config wt.basedir "../{gitroot}-wt"
```

### wt.copyignored - .gitignore'd ファイルのコピー

```bash
git config wt.copyignored true
```

### wt.copyuntracked - 未追跡ファイルのコピー

```bash
git config wt.copyuntracked true
```

### wt.copymodified - 変更ファイルのコピー

```bash
git config wt.copymodified true
```

### wt.nocopy - コピー除外パターン

```bash
git config --add wt.nocopy "*.log"
git config --add wt.nocopy "node_modules/"
git config --add wt.nocopy ".pnpm-store/"
```

### wt.hook - ポストプロセスフック

```bash
git config wt.hook "pnpm install"
```

---

## 推奨初期設定（Stremix向け）

```bash
# 環境ファイルを自動コピー
git config wt.copyignored true

# ログファイルはコピーしない
git config --add wt.nocopy "*.log"
git config --add wt.nocopy ".pnpm-store/"

# 依存関係を自動インストール
git config wt.hook "pnpm install"
```

---

## ワークフロー例

### パターン A: PR レビュー待ち中に別タスク

**Claude の実行手順**:

1. `git branch --show-current` で現在のブランチを確認
2. AskUserQuestion でベースブランチを確認（main を推奨）
3. `git worktree add -b feature/B ../project-wt/feature/B main` でワークツリー作成
4. 必要に応じて `pnpm install` 実行

### パターン B: 緊急 Hotfix 対応

**Claude の実行手順**:

1. AskUserQuestion でベースブランチを確認（**main を強く推奨**、hotfix は本番から分岐すべき）
2. `git worktree add -b hotfix/urgent ../project-wt/hotfix/urgent origin/main` でワークツリー作成
3. 修正作業を実施
4. 完了後 `git wt -d hotfix/urgent` で削除

### パターン C: コードレビュー用

**Claude の実行手順**:

1. `git fetch origin pull/123/head:pr/123` で PR をフェッチ
2. ベースブランチ確認は不要（既存ブランチをチェックアウトするため）
3. `git wt pr/123` でワークツリー作成

---

## FAQ

**Q: git-wt でベースブランチを指定できないのはなぜ？**

A: git-wt はシンプルさを重視した設計で、新規ブランチは現在のブランチから自動的に分岐します。ベースブランチを指定したい場合は `git worktree add -b` を直接使用してください。

**Q: どのコマンドを使うべき？**

A:
- **既存ブランチに切り替える場合**: `git wt <branch>`
- **現在のブランチから新規作成**: `git wt <new-branch>`
- **特定のベースから新規作成**: `git worktree add -b <new-branch> <path> <base-branch>`

**Q: ワークツリーはどこに作成される？**

A: デフォルトでは `../{リポジトリ名}-wt/` 配下に作成されます。

---

## 関連リソース

- [git-wt GitHub Repository](https://github.com/k1LoW/git-wt)
- [Git Worktree 公式ドキュメント](https://git-scm.com/docs/git-worktree)

---

**最終更新**: 2026-01-11
**対応ツール版**: git-wt (latest)
