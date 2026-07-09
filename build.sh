#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_NAME="FinderTools"
EXT_NAME="FinderToolsExtension"

echo "==> Cleaning..."
rm -rf build

echo "==> Building..."
xcodebuild -project "${APP_NAME}.xcodeproj" -scheme "$APP_NAME" \
  -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "error:|BUILD|FAILED" || true

APP="build/Build/Products/Release/${APP_NAME}.app"
EXT="$APP/Contents/PlugIns/${EXT_NAME}.appex"

echo "==> Generating icon..."
ICNS_DIR="/tmp/${APP_NAME}.iconset"
rm -rf "$ICNS_DIR" && mkdir "$ICNS_DIR"
SRC="${APP_NAME}/Assets.xcassets/AppIcon.appiconset"
for pair in "16.png 16x16" "32.png 16x16@2x" "32 1.png 32x32" "64.png 32x32@2x" \
            "128.png 128x128" "256 1.png 128x128@2x" "256.png 256x256" \
            "512 1.png 256x256@2x" "512.png 512x512" "1024.png 512x512@2x"; do
  src=$(echo "$pair" | cut -d' ' -f1)
  dst=$(echo "$pair" | cut -d' ' -f2)
  cp "$SRC/$src" "$ICNS_DIR/icon_$dst.png"
done
iconutil -c icns "$ICNS_DIR" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICNS_DIR"

echo "==> Patching Info.plist..."
plutil -replace CFBundleIconFile -string "AppIcon" "$APP/Contents/Info.plist"
plutil -replace CFBundleIconName -string "AppIcon" "$APP/Contents/Info.plist"

echo "==> Signing..."
codesign --force --options runtime --sign - \
  --entitlements "${EXT_NAME}/${EXT_NAME}.entitlements" "$EXT"
codesign --force --options runtime --sign - \
  --entitlements "${APP_NAME}/${APP_NAME}.entitlements" "$APP"

echo "==> Installing..."
killall "$APP_NAME" 2>/dev/null || true
killall "$EXT_NAME" 2>/dev/null || true
sleep 1
rm -rf "/Applications/${APP_NAME}.app"
cp -R "$APP" "/Applications/${APP_NAME}.app"
xattr -cr "/Applications/${APP_NAME}.app"
chmod +x "/Applications/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
chmod +x "/Applications/${APP_NAME}.app/Contents/PlugIns/${EXT_NAME}.appex/Contents/MacOS/${EXT_NAME}"

pluginkit -e use -i "com.lwz.${APP_NAME}.${EXT_NAME}" 2>/dev/null || true
killall Finder 2>/dev/null || true
sleep 1
open "/Applications/${APP_NAME}.app"

echo "==> Done!"
