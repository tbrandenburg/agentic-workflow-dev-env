#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p /data /workspace \
  "$HOME/.cache" "$HOME/.local/state"

# GH_TOKEN lets private-repository operations work without persisting a token.
if [[ -n "${GH_TOKEN:-}" ]]; then
  gh auth setup-git >/dev/null 2>&1 || true
fi

exec "$@"
