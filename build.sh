#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "==> Building..."
rm -rf build
xcodebuild -project FinderTools.xcodeproj -scheme FinderTools \
  -configuration Release -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "error:|BUILD|warning:" | head -20

APP="build/Build/Products/Release/FinderTools.app"
EXT="$APP/Contents/PlugIns/FinderToolsExtension.appex"

echo "==> Generating icon..."
ICNS_DIR="/tmp/AppIcon.iconset"
rm -rf "$ICNS_DIR" && mkdir "$ICNS_DIR"
SRC="FinderTools/Assets.xcassets/AppIcon.appiconset"
cp "$SRC/16.png"     "$ICNS_DIR/icon_16x16.png"
cp "$SRC/32.png"     "$ICNS_DIR/icon_16x16@2x.png"
cp "$SRC/32 1.png"   "$ICNS_DIR/icon_32x32.png"
cp "$SRC/64.png"     "$ICNS_DIR/icon_32x32@2x.png"
cp "$SRC/128.png"    "$ICNS_DIR/icon_128x128.png"
cp "$SRC/256 1.png"  "$ICNS_DIR/icon_128x128@2x.png"
cp "$SRC/256.png"    "$ICNS_DIR/icon_256x256.png"
cp "$SRC/512 1.png"  "$ICNS_DIR/icon_256x256@2x.png"
cp "$SRC/512.png"    "$ICNS_DIR/icon_512x512.png"
cp "$SRC/1024.png"   "$ICNS_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICNS_DIR" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICNS_DIR"

echo "==> Patching Info.plist..."
plutil -replace CFBundleIconFile -string "AppIcon" "$APP/Contents/Info.plist"
plutil -replace CFBundleIconName -string "AppIcon" "$APP/Contents/Info.plist"

echo "==> Signing..."
codesign --force --options runtime --sign - \
  --entitlements FinderToolsExtension/FinderToolsExtension.entitlements "$EXT"
codesign --force --options runtime --sign - \
  --entitlements FinderTools/FinderTools.entitlements "$APP"

echo "==> Installing..."
killall FinderTools 2>/dev/null; killall FinderToolsExtension 2>/dev/null; sleep 1
rm -rf /Applications/FinderTools.app
cp -R "$APP" /Applications/FinderTools.app
xattr -cr /Applications/FinderTools.app
chmod +x /Applications/FinderTools.app/Contents/MacOS/FinderTools
chmod +x /Applications/FinderTools.app/Contents/PlugIns/FinderToolsExtension.appex/Contents/MacOS/FinderToolsExtension

pluginkit -e use -i com.lwz.FinderTools.FinderToolsExtension 2>/dev/null
killall Finder 2>/dev/null; sleep 1
open /Applications/FinderTools.app
echo "==> Done!"
