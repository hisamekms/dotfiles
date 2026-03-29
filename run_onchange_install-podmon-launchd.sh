#!/bin/bash
# chezmoi:template: true
# Installs podmon LaunchAgent on macOS.
# Triggered on change to the plist source file.
#
# hash: {{ include "private_dot_config/podmon/dev.podmon.plist" | sha256sum }}

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "[podmon] skipping: not macOS"
  exit 0
fi

PLIST_SRC="${HOME}/.config/podmon/dev.podmon.plist"
PLIST_DST="${HOME}/Library/LaunchAgents/dev.podmon.plist"

if [[ ! -f "$PLIST_SRC" ]]; then
  echo "[podmon] plist source not found: ${PLIST_SRC}"
  exit 1
fi

# Unload existing agent if present
if launchctl list dev.podmon &>/dev/null; then
  echo "[podmon] unloading existing agent..."
  launchctl unload "$PLIST_DST" 2>/dev/null || true
fi

# Copy plist
mkdir -p "$(dirname "$PLIST_DST")"
cp "$PLIST_SRC" "$PLIST_DST"
echo "[podmon] copied plist to ${PLIST_DST}"

# Load agent
launchctl load "$PLIST_DST"
echo "[podmon] loaded LaunchAgent dev.podmon"
