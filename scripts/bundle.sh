#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🚀 Building OpenLid for Apple Silicon (arm64)..."
swift build -c release --triple arm64-apple-macosx
ARM64_APP_BIN="$DIR/.build/out/Products/Release/OpenLid"
ARM64_CLI_BIN="$DIR/.build/out/Products/Release/OpenLidCLI"
mkdir -p "$DIR/.build/bin_arm64"
cp "$ARM64_APP_BIN" "$DIR/.build/bin_arm64/OpenLid"
cp "$ARM64_CLI_BIN" "$DIR/.build/bin_arm64/openlid"

echo "🚀 Building OpenLid for Intel Macs (x86_64)..."
swift build -c release --triple x86_64-apple-macosx
X86_APP_BIN="$DIR/.build/out/Products/Release/OpenLid"
X86_CLI_BIN="$DIR/.build/out/Products/Release/OpenLidCLI"
mkdir -p "$DIR/.build/bin_x86"
cp "$X86_APP_BIN" "$DIR/.build/bin_x86/OpenLid"
cp "$X86_CLI_BIN" "$DIR/.build/bin_x86/openlid"

DIST_DIR="$DIR/dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "🧬 Creating Universal 2 Mach-O binaries with lipo..."
lipo -create "$DIR/.build/bin_arm64/OpenLid" "$DIR/.build/bin_x86/OpenLid" -output "$DIST_DIR/OpenLid-Universal-bin"
lipo -create "$DIR/.build/bin_arm64/openlid" "$DIR/.build/bin_x86/openlid" -output "$DIST_DIR/openlid"
chmod +x "$DIST_DIR/openlid"

# Function to assemble an app bundle
bundle_app() {
    local target_bin="$1"
    local app_path="$2"
    local contents="$app_path/Contents"
    local macos="$contents/MacOS"
    local res="$contents/Resources"

    rm -rf "$app_path"
    mkdir -p "$macos" "$res"
    cp "$target_bin" "$macos/OpenLid"
    chmod +x "$macos/OpenLid"
    cp "$DIR/Resources/Info.plist" "$contents/Info.plist"

    if [ -f "$DIR/Resources/AppIcon.icns" ]; then
        cp "$DIR/Resources/AppIcon.icns" "$res/AppIcon.icns"
    fi

    codesign --force --deep --sign - "$app_path" > /dev/null 2>&1
}

echo "📦 Assembling Universal OpenLid.app..."
bundle_app "$DIST_DIR/OpenLid-Universal-bin" "$DIST_DIR/OpenLid.app"
rm -f "$DIST_DIR/OpenLid-Universal-bin"

echo "📦 Assembling Apple Silicon OpenLid-AppleSilicon.app..."
bundle_app "$DIR/.build/bin_arm64/OpenLid" "$DIST_DIR/OpenLid-AppleSilicon.app"

echo "📦 Assembling Intel OpenLid-Intel.app..."
bundle_app "$DIR/.build/bin_x86/OpenLid" "$DIST_DIR/OpenLid-Intel.app"

echo "🗜 Creating release archives..."
(cd "$DIST_DIR" && zip -rq "OpenLid-AppleSilicon.zip" "OpenLid-AppleSilicon.app")
(cd "$DIST_DIR" && zip -rq "OpenLid-Intel.zip" "OpenLid-Intel.app")
(cd "$DIST_DIR" && zip -rq "OpenLid-Universal.zip" "OpenLid.app")

echo "✅ Dual Architecture Build Complete!"
echo "📍 Universal App:      $DIST_DIR/OpenLid.app"
echo "📍 Apple Silicon App:  $DIST_DIR/OpenLid-AppleSilicon.app"
echo "📍 Intel Mac App:      $DIST_DIR/OpenLid-Intel.app"
echo "📍 Universal CLI:      $DIST_DIR/openlid"
