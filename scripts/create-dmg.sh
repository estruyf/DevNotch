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

# Create Applications symlink
ln -s /Applications "$TEMP_DMG_CONTENT/Applications"

# Create DMG
mkdir -p "$DIST_DIR"
DMG_FINAL="$DIST_DIR/DevNotch.dmg"
DMG_TMP="$DIST_DIR/DevNotch_tmp.dmg"
rm -f "$DMG_FINAL" "$DMG_TMP"

# Create temporary read-write DMG
hdiutil create -volname 'DevNotch' -srcfolder "$TEMP_DMG_CONTENT" -ov -format UDRW "$DMG_TMP"

# Mount the DMG
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify "$DMG_TMP")
DEVICE=$(echo "$MOUNT_OUTPUT" | grep -E '^/dev/' | sed 1q | awk '{print $1}')
VOL_NAME=$(echo "$MOUNT_OUTPUT" | grep '/Volumes/' | awk -F'/Volumes/' '{print $2}')

sleep 2

# Customize with AppleScript
echo "Setting up DMG view options for volume: $VOL_NAME..."
osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 100
        
        delay 1
        
        set position of item "DevNotch.app" of container window to {160, 180}
        set position of item "Applications" of container window to {340, 180}
        
        close
        open
        update without registering applications
        delay 1
    end tell
end tell
EOF

# Unmount
hdiutil detach "$DEVICE"

# Convert to compressed DMG
hdiutil convert "$DMG_TMP" -format UDZO -o "$DMG_FINAL"
rm -f "$DMG_TMP"

# Cleanup
rm -rf "$TEMP_DMG_CONTENT"

echo "✅ DMG created successfully at $DMG_FINAL"

