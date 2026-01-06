#!/bin/bash
set -e

# Build paths
BUILD_PATH="./macos/.build/Build/Products/Debug"
EXECUTABLE="$BUILD_PATH/DevNotch"
DIST_DIR="./dist"
TEMP_DMG_CONTENT="/tmp/devnotch-dmg-content"

# Clean up old temp folder
rm -rf "$TEMP_DMG_CONTENT"
mkdir -p "$TEMP_DMG_CONTENT"

# Copy executable
cp "$EXECUTABLE" "$TEMP_DMG_CONTENT/DevNotch"
chmod +x "$TEMP_DMG_CONTENT/DevNotch"

# Create a simple README
cat > "$TEMP_DMG_CONTENT/README.txt" << 'EOF'
DevNotch - Media Player Notch Display

Usage:
1. Run DevNotch directly from Terminal
2. Or copy to /usr/local/bin/ and run "DevNotch" from anywhere

Requirements:
- macOS 14.0+
- Spotify or Apple Music installed

Features:
- Displays current playing track at top of screen
- Shows Copilot API usage when authenticated  
- Click to expand/collapse
- Fade animation based on state
EOF

# Create DMG
mkdir -p "$DIST_DIR"
hdiutil create -volname 'DevNotch' -srcfolder "$TEMP_DMG_CONTENT" -ov -format UDZO "$DIST_DIR/DevNotch.dmg"

# Cleanup
rm -rf "$TEMP_DMG_CONTENT"

echo "✅ DMG created successfully at $DIST_DIR/DevNotch.dmg"
