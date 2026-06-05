#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="COPI"
EXECUTABLE_NAME="CopyApp"
PRODUCT_NAME="CopyApp"
APP_DIR="$ROOT_DIR/.build/app/$APP_NAME.app"
CODE_SIGN_IDENTITY="${COPY_CODE_SIGN_IDENTITY:-}"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
APP_ICON_NAME="AppIcon"
APP_ICON_SOURCE="$ROOT_DIR/Resources/AppIconSource.jpg"
EMPTY_STATE_SOURCE="$ROOT_DIR/Resources/EmptyState.png"
EMPTY_STATE_RESOURCE_NAME="EmptyState.png"
APP_ICONSET_DIR="$ROOT_DIR/.build/app/$APP_ICON_NAME.iconset"

cd "$ROOT_DIR"

swift build -c "$CONFIGURATION" --product "$PRODUCT_NAME"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_DIR/$PRODUCT_NAME" "$MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

if [[ ! -f "$APP_ICON_SOURCE" ]]; then
  echo "缺少应用图标源文件：$APP_ICON_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$EMPTY_STATE_SOURCE" ]]; then
  echo "缺少空态图片资源：$EMPTY_STATE_SOURCE" >&2
  exit 1
fi

rm -rf "$APP_ICONSET_DIR"
mkdir -p "$APP_ICONSET_DIR"

create_icon_png() {
  local base_size="$1"
  local scale_suffix="$2"
  local pixel_size="$3"
  local output_name="icon_${base_size}x${base_size}${scale_suffix}.png"

  sips -s format png -z "$pixel_size" "$pixel_size" "$APP_ICON_SOURCE" \
    --out "$APP_ICONSET_DIR/$output_name" >/dev/null
}

create_icon_png 16 "" 16
create_icon_png 16 "@2x" 32
create_icon_png 32 "" 32
create_icon_png 32 "@2x" 64
create_icon_png 128 "" 128
create_icon_png 128 "@2x" 256
create_icon_png 256 "" 256
create_icon_png 256 "@2x" 512
create_icon_png 512 "" 512
create_icon_png 512 "@2x" 1024

iconutil -c icns "$APP_ICONSET_DIR" -o "$RESOURCES_DIR/$APP_ICON_NAME.icns"
rm -rf "$APP_ICONSET_DIR"
cp "$EMPTY_STATE_SOURCE" "$RESOURCES_DIR/$EMPTY_STATE_RESOURCE_NAME"

cat > "$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.local.copy</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if [[ -z "$CODE_SIGN_IDENTITY" ]]; then
  CODE_SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null \
    | awk -F'"' '/Apple Development:/ { print $2; exit }')"
fi

if [[ -z "$CODE_SIGN_IDENTITY" ]]; then
  CODE_SIGN_IDENTITY="-"
fi

codesign --force --deep --sign "$CODE_SIGN_IDENTITY" "$APP_DIR" >/dev/null

echo "$APP_DIR"
