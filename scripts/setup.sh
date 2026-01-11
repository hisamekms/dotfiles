#!/usr/bin/env bash
set -euo pipefail

# fishがインストールされているかチェック
if ! command -v fish &> /dev/null; then
    sudo apt update
    sudo apt install -y fish

    sudo chown "$(whoami):$(whoami)" "$HOME/.local"

    sudo chsh -s "$(command -v fish)" "$(whoami)"
fi


