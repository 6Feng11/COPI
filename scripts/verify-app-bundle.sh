#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${1:-"$ROOT_DIR/.build/app/Copy.app"}"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
EXECUTABLE="$APP_PATH/Contents/MacOS/CopyApp"

"$ROOT_DIR/scripts/build-app-bundle.sh" >/tmp/copy-build-app-bundle.log

test -d "$APP_PATH"
test -d "$APP_PATH/Contents"
test -d "$APP_PATH/Contents/MacOS"
test -d "$APP_PATH/Contents/Resources"
test -f "$INFO_PLIST"
test -x "$EXECUTABLE"

/usr/libexec/PlistBuddy -c "Print :CFBundlePackageType" "$INFO_PLIST" | grep -qx "APPL"
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" | grep -qx "com.local.copy"
/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$INFO_PLIST" | grep -qx "CopyApp"
/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$INFO_PLIST" | grep -qx "true"
CODE_SIGN_INFO="$(codesign -dv "$APP_PATH" 2>&1)"
grep -qx "Identifier=com.local.copy" <<<"$CODE_SIGN_INFO"
grep -Eq "TeamIdentifier=|Signature=adhoc" <<<"$CODE_SIGN_INFO"

echo "Copy.app bundle 验证通过：$APP_PATH"
