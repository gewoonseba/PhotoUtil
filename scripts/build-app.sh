#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PhotoUtil"
CONFIGURATION="${1:-Release}"
case "$CONFIGURATION" in
  release) CONFIGURATION="Release" ;;
  debug) CONFIGURATION="Debug" ;;
esac
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/DerivedData}"
BUILT_APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
OUTPUT_DIR="$ROOT_DIR/outputs"
OUTPUT_APP="$OUTPUT_DIR/$APP_NAME.app"

cd "$ROOT_DIR"

xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  build

rm -rf "$OUTPUT_APP"
mkdir -p "$OUTPUT_DIR"
ditto "$BUILT_APP" "$OUTPUT_APP"

echo "$OUTPUT_APP"
