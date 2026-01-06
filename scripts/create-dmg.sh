#!/bin/bash
set -e

# Build paths
BUILD_PATH="./macos/.build/Build/Products/Release"
APP_BUNDLE="$BUILD_PATH/DevNotch.app"
EXECUTABLE="$BUILD_PATH/DevNotch"
DIST_DIR="./dist"

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

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>DevNotch</string>
    <key>CFBundleIdentifier</key>
    <string>com.devnotch.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DevNotch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Create DMG
mkdir -p "$DIST_DIR"
hdiutil create -volname 'DevNotch' -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DIST_DIR/DevNotch.dmg"

echo "✅ DMG created successfully at $DIST_DIR/DevNotch.dmg"
