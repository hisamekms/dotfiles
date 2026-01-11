#!/usr/bin/env bash
set -euo pipefail

# OS判定
OS="$(uname -s)"
case "${OS}" in
    Linux*)
        # Linuxの場合: fishがインストールされているかチェック
        if ! command -v fish &> /dev/null; then
            sudo apt update
            sudo apt install -y fish

            sudo chown "$(whoami):$(whoami)" "$HOME/.local"

            sudo chsh -s "$(command -v fish)" "$(whoami)"

            mise exec chezmoi -- chezmoi apply
        fi

        # Linuxの場合: miseがインストールされているかチェック
        if ! command -v mise &> /dev/null; then
            sudo apt update -y && sudo apt install -y curl
            sudo install -dm 755 /etc/apt/keyrings
            curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null
            echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
            sudo apt update
            sudo apt install -y mise
        fi

        ;;
    Darwin*)
        # macOSの場合: brewがインストールされているかチェック
        if ! command -v brew &> /dev/null; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        # Brewfileを使ってパッケージをインストール
        if [ -f "./Brewfile" ]; then
            brew bundle --file=./Brewfile
        fi
        ;;
    *)
        echo "Unsupported OS: ${OS}"
        exit 1
        ;;
esac


