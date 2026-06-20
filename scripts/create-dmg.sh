#!/bin/bash

# Create a fancy DMG installer with drag-to-Applications

set -e

APP_NAME="ImageMate"
APP_PATH="${1:-}"
DMG_NAME="ImageMate.dmg"

# Auto-detect app path if not provided
if [ -z "$APP_PATH" ]; then
    if [ -d "build/DerivedData/Build/Products/Release/ImageMate.app" ]; then
        APP_PATH="build/DerivedData/Build/Products/Release/ImageMate.app"
    elif [ -d "build/Build/Products/Release/ImageMate.app" ]; then
        APP_PATH="build/Build/Products/Release/ImageMate.app"
    elif [ -d "build/DerivedData/Build/Products/Debug/ImageMate.app" ]; then
        APP_PATH="build/DerivedData/Build/Products/Debug/ImageMate.app"
    elif [ -d "build/Build/Products/Debug/ImageMate.app" ]; then
        APP_PATH="build/Build/Products/Debug/ImageMate.app"
    fi
fi
DMG_TEMP="ImageMate-temp.sparsebundle"
VOLUME_NAME="ImageMate"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: ImageMate.app not found."
    echo ""
    echo "Build the app first with:"
    echo "  xcodebuild -workspace ImageMate.xcworkspace -scheme ImageMate -configuration Release build CODE_SIGN_IDENTITY=\"-\" -derivedDataPath build/DerivedData"
    echo ""
    echo "Or pass the path directly:"
    echo "  $0 /path/to/ImageMate.app"
    exit 1
fi

echo "🔨 Creating installer DMG..."

# Clean up any existing files
rm -rf "$DMG_NAME" "$DMG_TEMP"

# Create a temporary directory for DMG contents
DMG_CONTENTS=$(mktemp -d)
trap "rm -rf $DMG_CONTENTS $DMG_TEMP" EXIT

# Copy app to temp directory
cp -R "$APP_PATH" "$DMG_CONTENTS/"

# Create symbolic link to Applications folder
ln -s /Applications "$DMG_CONTENTS/Applications"

# Create the DMG (writable sparsebundle for Finder customization)
echo "📦 Creating DMG volume..."
diskutil image create from "$DMG_CONTENTS" --format UDSB \
    --volumeName "$VOLUME_NAME" "$DMG_TEMP" >/dev/null

# Mount the DMG
echo "💿 Mounting DMG..."
DEVICE=$(diskutil image attach "$DMG_TEMP" | \
    grep -E '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_POINT="/Volumes/$VOLUME_NAME"

sleep 2

# Set up the Finder view
echo "🎨 Configuring Finder view..."
osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 420}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "$APP_NAME.app" of container window to {125, 160}
        set position of item "Applications" of container window to {375, 160}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Sync and unmount
sync
diskutil eject "$DEVICE" >/dev/null

# Convert to compressed DMG
echo "🗜️ Compressing DMG..."
diskutil image create from "$DMG_TEMP" --format UDZO "$DMG_NAME" >/dev/null

# Clean up temp DMG
rm -rf "$DMG_TEMP"

# Show result
echo ""
echo "✅ Created: $DMG_NAME"
ls -lh "$DMG_NAME"
echo ""
echo "📝 The DMG now has:"
echo "   • ImageMate.app"
echo "   • Applications folder shortcut"
echo "   • Drag-to-install layout"
