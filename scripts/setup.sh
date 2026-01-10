#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y fish

if command -v chsh >/dev/null 2>&1; then
  sudo chsh -s "$(command -v fish)" vscode || true
fi