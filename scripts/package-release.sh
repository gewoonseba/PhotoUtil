#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PhotoUtil"
VERSION="${VERSION:-0.1.0}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/DerivedData}"
BUILD_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"

cd "$ROOT_DIR"

xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  build

mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$BUILD_APP" "$ZIP_PATH"

echo "$ZIP_PATH"
