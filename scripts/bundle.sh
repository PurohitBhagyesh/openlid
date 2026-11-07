#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🚀 Building OpenLid in Release mode..."
swift build -c release

APP_NAME="OpenLid.app"
DIST_DIR="$DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Assembling $APP_NAME bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy main executable
cp "$DIR/.build/release/OpenLid" "$MACOS_DIR/OpenLid"

# Copy CLI executable
cp "$DIR/.build/release/OpenLidCLI" "$DIST_DIR/openlid"

# Copy Info.plist
cp "$DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy AppIcon if available
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Ad-hoc code sign the bundle
echo "🔏 Signing application bundle..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ Build Complete!"
echo "📍 Application: $APP_DIR"
echo "📍 CLI Tool:    $DIST_DIR/openlid"
echo ""
echo "To run the app right now:"
echo "  open \"$APP_DIR\""
echo ""
echo "To install to /Applications and /usr/local/bin:"
echo "  ./scripts/install.sh"

