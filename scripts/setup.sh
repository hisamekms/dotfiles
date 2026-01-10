#!/usr/bin/env bash
set -euo pipefail

# fishがインストールされているかチェック
if ! command -v fish &> /dev/null; then
    sudo apt update
    sudo apt install -y fish
    
    # fishインストール後にディレクトリの所有権を修正
    if [ -d "$HOME/.local/share/fish" ]; then
        sudo chown -R "$(whoami):$(whoami)" "$HOME/.local/share/fish"
    fi

    sudo chsh -s "$(command -v fish)" "$(whoami)" || true
fi


