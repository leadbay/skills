#!/usr/bin/env bash
set -euo pipefail
DEST="${HOME}/.leadbay-skills"
if [ -d "$DEST/.git" ]; then
  echo "Updating existing install..."
  cd "$DEST" && git pull --rebase origin main
else
  echo "Installing..."
  git clone https://github.com/leadbay/skills.git "$DEST"
fi
"$DEST/setup"
