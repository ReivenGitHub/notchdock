#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if bash scripts/build-app.sh native; then
  open build/NotchDock.app
else
  echo "Build failed. Read the message above and see README.md for setup help."
  read -r -p "Press Return to close this window. " _reply
  exit 1
fi
