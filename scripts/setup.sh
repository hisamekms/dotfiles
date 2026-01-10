#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt install -y fish

if command -v chsh >/dev/null 2>&1; then
  chsh -s "$(command -v fish)" || true
fi