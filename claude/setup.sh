#!/bin/bash
# Claude Code グローバル設定セットアップスクリプト
# 使用方法: ./setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Claude Code グローバル設定をセットアップします..."

# ~/.claude ディレクトリが存在しない場合は作成
mkdir -p "$CLAUDE_DIR"

# シンボリックリンク作成関数
create_symlink() {
    local src="$1"
    local dst="$2"

    if [ -L "$dst" ]; then
        echo "  既存のシンボリックリンクを削除: $dst"
        rm "$dst"
    elif [ -e "$dst" ]; then
        echo "  既存ファイルをバックアップ: $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    ln -s "$src" "$dst"
    echo "  リンク作成: $dst -> $src"
}

# settings.json
echo ""
echo "settings.json をセットアップ..."
create_symlink "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"

# commands/
echo ""
echo "commands/ をセットアップ..."
if [ -d "$CLAUDE_DIR/commands" ] && [ ! -L "$CLAUDE_DIR/commands" ]; then
    echo "  既存の commands/ をバックアップ: ${CLAUDE_DIR}/commands.bak"
    mv "$CLAUDE_DIR/commands" "${CLAUDE_DIR}/commands.bak"
fi
create_symlink "$SCRIPT_DIR/commands" "$CLAUDE_DIR/commands"

# skills/
echo ""
echo "skills/ をセットアップ..."
if [ -d "$CLAUDE_DIR/skills" ] && [ ! -L "$CLAUDE_DIR/skills" ]; then
    echo "  既存の skills/ をバックアップ: ${CLAUDE_DIR}/skills.bak"
    mv "$CLAUDE_DIR/skills" "${CLAUDE_DIR}/skills.bak"
fi
create_symlink "$SCRIPT_DIR/skills" "$CLAUDE_DIR/skills"

echo ""
echo "セットアップ完了!"
echo ""
echo "現在の設定:"
ls -la "$CLAUDE_DIR"
