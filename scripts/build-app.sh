#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "NotchDock.app must be built on macOS with Xcode 15 or newer." >&2
  exit 1
fi
if ! xcrun --find swift >/dev/null 2>&1; then
  echo "Install Xcode or Apple's Command Line Tools first: xcode-select --install" >&2
  exit 1
fi
BUILD_ARCH="${1:-native}"
APP_PATH="$PROJECT_ROOT/build/NotchDock.app"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
if [[ "$BUILD_ARCH" == "universal" ]]; then
  for ARCH in arm64 x86_64; do
    swift build --configuration release --arch "$ARCH" --product NotchDock
  done
  ARM_BIN="$(swift build --configuration release --arch arm64 --show-bin-path)"
  INTEL_BIN="$(swift build --configuration release --arch x86_64 --show-bin-path)"
  lipo -create "$ARM_BIN/NotchDock" "$INTEL_BIN/NotchDock" -output "$APP_PATH/Contents/MacOS/NotchDock"
elif [[ "$BUILD_ARCH" == "native" || "$BUILD_ARCH" == "arm64" || "$BUILD_ARCH" == "x86_64" ]]; then
  BUILD_FLAGS=(--configuration release)
  if [[ "$BUILD_ARCH" != "native" ]]; then BUILD_FLAGS+=(--arch "$BUILD_ARCH"); fi
  swift build "${BUILD_FLAGS[@]}" --product NotchDock
  BIN_DIR="$(swift build "${BUILD_FLAGS[@]}" --show-bin-path)"
  cp "$BIN_DIR/NotchDock" "$APP_PATH/Contents/MacOS/NotchDock"
else
  echo "Usage: bash scripts/build-app.sh [native|universal|arm64|x86_64]" >&2
  exit 1
fi
cp Resources/Info.plist "$APP_PATH/Contents/Info.plist"
swift scripts/make-icon.swift "$PROJECT_ROOT/build/AppIcon.iconset"
iconutil --convert icns "$PROJECT_ROOT/build/AppIcon.iconset" --output "$APP_PATH/Contents/Resources/AppIcon.icns"
chmod 755 "$APP_PATH/Contents/MacOS/NotchDock"
# Set SIGNING_IDENTITY to your Developer ID Application identity for distribution.
IDENTITY="${SIGNING_IDENTITY:--}"
SIGN_FLAGS=(--force --sign "$IDENTITY" --entitlements Resources/NotchDock.entitlements)
if [[ "$IDENTITY" != "-" ]]; then SIGN_FLAGS+=(--options runtime --timestamp); fi
codesign "${SIGN_FLAGS[@]}" "$APP_PATH"
codesign --verify --strict --verbose=2 "$APP_PATH"
plutil -lint "$APP_PATH/Contents/Info.plist"
echo "Built: $APP_PATH"
