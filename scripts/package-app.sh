#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"
bash scripts/build-app.sh "${1:-universal}"
mkdir -p dist
# Preserve executable permissions and bundle metadata through artifact download.
ditto -c -k --sequesterRsrc --keepParent build/NotchDock.app dist/NotchDock-macOS.zip
shasum -a 256 dist/NotchDock-macOS.zip > dist/SHA256SUMS.txt
echo "Packaged: $PROJECT_ROOT/dist/NotchDock-macOS.zip"
