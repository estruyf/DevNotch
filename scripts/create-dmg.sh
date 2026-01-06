#!/bin/bash
set -e

# Build paths
BUILD_PATH="./macos/.build/Build/Products/Release"
EXECUTABLE="$BUILD_PATH/DevNotch"
DIST_DIR="./dist"
TEMP_DMG_CONTENT="/tmp/devnotch-dmg-content"
SOURCE_INFO_PLIST="./macos/DevNotch/Info.plist"
ENTITLEMENTS="./macos/DevNotch/DevNotch.entitlements"

# Clean up old temp folder
rm -rf "$TEMP_DMG_CONTENT"
mkdir -p "$TEMP_DMG_CONTENT"

# Create app bundle structure
APP_BUNDLE="$TEMP_DMG_CONTENT/DevNotch.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable into bundle
cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/DevNotch"
chmod +x "$APP_BUNDLE/Contents/MacOS/DevNotch"

# Copy Info.plist
cp "$SOURCE_INFO_PLIST" "$APP_BUNDLE/Contents/Info.plist"

# Note: DO NOT code sign - the binary is already properly set up and code signing
# after creating the bundle can break the signature. The build system handles signing.

# Create DMG
mkdir -p "$DIST_DIR"
hdiutil create -volname 'DevNotch' -srcfolder "$TEMP_DMG_CONTENT" -ov -format UDZO "$DIST_DIR/DevNotch.dmg"

# Cleanup
rm -rf "$TEMP_DMG_CONTENT"

echo "✅ DMG created successfully at $DIST_DIR/DevNotch.dmg"

