#!/bin/bash
set -e

# Build paths
BUILD_PATH="./macos/.build/Build/Products/Debug"
APP_BUNDLE="$BUILD_PATH/DevNotch.app"
EXECUTABLE="$BUILD_PATH/DevNotch"
DIST_DIR="./dist"
ENTITLEMENTS="./macos/DevNotch/DevNotch.entitlements"
SOURCE_INFO_PLIST="./macos/DevNotch/Info.plist"

# Clean up old app bundle if it exists
if [ -d "$APP_BUNDLE" ]; then
  rm -rf "$APP_BUNDLE"
fi

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/DevNotch"
chmod +x "$APP_BUNDLE/Contents/MacOS/DevNotch"

# Code sign the executable with entitlements
codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP_BUNDLE/Contents/MacOS/DevNotch" 2>/dev/null || true

# Copy source Info.plist with proper values
cp "$SOURCE_INFO_PLIST" "$APP_BUNDLE/Contents/Info.plist"

# Code sign the app bundle
codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP_BUNDLE" 2>/dev/null || true

# Create DMG
mkdir -p "$DIST_DIR"
hdiutil create -volname 'DevNotch' -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DIST_DIR/DevNotch.dmg"

echo "✅ DMG created successfully at $DIST_DIR/DevNotch.dmg"

