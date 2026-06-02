#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="PhotoUtil"
CONFIGURATION="${CONFIGURATION:-Release}"
case "$CONFIGURATION" in
  release) CONFIGURATION="Release" ;;
  debug) CONFIGURATION="Debug" ;;
esac
DERIVED_DATA="${DERIVED_DATA:-$ROOT_DIR/DerivedData}"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
BUILT_APP="$DERIVED_DATA/Build/Products/${CONFIGURATION}/$APP_NAME.app"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"

cd "$ROOT_DIR"

xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  build

if [[ ! -d "$BUILT_APP" ]]; then
  echo "Build did not produce $BUILT_APP" >&2
  exit 1
fi

if [[ ! -w "$INSTALL_DIR" ]]; then
  echo "$INSTALL_DIR is not writable. Trying $HOME/Applications instead."
  INSTALL_DIR="$HOME/Applications"
  INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"
  mkdir -p "$INSTALL_DIR"
fi

rm -rf "$INSTALLED_APP"
ditto "$BUILT_APP" "$INSTALLED_APP"
codesign --force --deep --sign - "$INSTALLED_APP" >/dev/null
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$INSTALLED_APP" >/dev/null 2>&1 || true

echo "$INSTALLED_APP"
