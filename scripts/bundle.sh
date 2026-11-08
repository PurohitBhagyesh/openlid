#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🚀 Building OpenLid for Apple Silicon (arm64)..."
swift build -c release --triple arm64-apple-macosx
BIN_PATH="$(swift build -c release --triple arm64-apple-macosx --show-bin-path)"
ARM64_APP_BIN="$BIN_PATH/OpenLid"
ARM64_CLI_BIN="$BIN_PATH/OpenLidCLI"

mkdir -p "$DIR/.build/bin_arm64_app" "$DIR/.build/bin_arm64_cli"
cp "$ARM64_APP_BIN" "$DIR/.build/bin_arm64_app/OpenLid"
cp "$ARM64_CLI_BIN" "$DIR/.build/bin_arm64_cli/openlid_cli"

echo "🚀 Building OpenLid for Intel Macs (x86_64)..."
swift build -c release --triple x86_64-apple-macosx
BIN_PATH_X86="$(swift build -c release --triple x86_64-apple-macosx --show-bin-path)"
X86_APP_BIN="$BIN_PATH_X86/OpenLid"
X86_CLI_BIN="$BIN_PATH_X86/OpenLidCLI"

mkdir -p "$DIR/.build/bin_x86_app" "$DIR/.build/bin_x86_cli"
cp "$X86_APP_BIN" "$DIR/.build/bin_x86_app/OpenLid"
cp "$X86_CLI_BIN" "$DIR/.build/bin_x86_cli/openlid_cli"

DIST_DIR="$DIR/dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "🧬 Creating Universal 2 Mach-O binaries with lipo..."
lipo -create "$DIR/.build/bin_arm64_app/OpenLid" "$DIR/.build/bin_x86_app/OpenLid" -output "$DIST_DIR/OpenLid-Universal-bin"
lipo -create "$DIR/.build/bin_arm64_cli/openlid_cli" "$DIR/.build/bin_x86_cli/openlid_cli" -output "$DIST_DIR/openlid"
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
bundle_app "$DIR/.build/bin_arm64_app/OpenLid" "$DIST_DIR/OpenLid-AppleSilicon.app"

echo "📦 Assembling Intel OpenLid-Intel.app..."
bundle_app "$DIR/.build/bin_x86_app/OpenLid" "$DIST_DIR/OpenLid-Intel.app"

echo "🗜 Creating macOS release archives (with Applications shortcut and openlid CLI)..."
cd "$DIST_DIR"
ln -sf /Applications Applications
tar -czf "$DIST_DIR/OpenLid-Universal.tar.gz" OpenLid.app openlid
zip -rq -y "$DIST_DIR/OpenLid-Universal.zip" OpenLid.app openlid Applications

# Package Apple Silicon zip
TMP_ARM="$DIR/.build/tmp_pkg_arm"
rm -rf "$TMP_ARM" && mkdir -p "$TMP_ARM"
cp -R "$DIST_DIR/OpenLid-AppleSilicon.app" "$TMP_ARM/OpenLid.app"
cp "$DIST_DIR/openlid" "$TMP_ARM/openlid"
ln -sf /Applications "$TMP_ARM/Applications"
(cd "$TMP_ARM" && zip -rq -y "$DIST_DIR/OpenLid-AppleSilicon.zip" OpenLid.app openlid Applications)
rm -rf "$TMP_ARM"

# Package Intel zip
TMP_X86="$DIR/.build/tmp_pkg_x86"
rm -rf "$TMP_X86" && mkdir -p "$TMP_X86"
cp -R "$DIST_DIR/OpenLid-Intel.app" "$TMP_X86/OpenLid.app"
cp "$DIST_DIR/openlid" "$TMP_X86/openlid"
ln -sf /Applications "$TMP_X86/Applications"
(cd "$TMP_X86" && zip -rq -y "$DIST_DIR/OpenLid-Intel.zip" OpenLid.app openlid Applications)
rm -rf "$TMP_X86"
rm -f "$DIST_DIR/Applications"

echo "🪟 Creating Windows release archives (with installer, shortcuts & native icon)..."
WIN_SRC="$DIR/windows"
TMP_WIN="$DIR/.build/tmp_pkg_win"
rm -rf "$TMP_WIN" && mkdir -p "$TMP_WIN"
cp "$WIN_SRC"/* "$TMP_WIN/" 2>/dev/null || true
(cd "$TMP_WIN" && zip -rq "$DIST_DIR/OpenLid-Windows-x64.zip" .)
(cd "$TMP_WIN" && zip -rq "$DIST_DIR/OpenLid-Windows-ARM64.zip" .)
rm -rf "$TMP_WIN"

echo "🔄 Synchronizing release archives to downloads/ and website/downloads/..."
mkdir -p "$DIR/downloads" "$DIR/website/downloads"
cp "$DIST_DIR"/*.zip "$DIR/downloads/"
cp "$DIST_DIR"/*.zip "$DIR/website/downloads/"

# Calculate new universal sha256 and update Homebrew Cask
UNIVERSAL_ZIP="$DIR/downloads/OpenLid-Universal.zip"
NEW_SHA="$(shasum -a 256 "$UNIVERSAL_ZIP" | awk '{print $1}')"
echo "🔑 Universal Zip SHA256: $NEW_SHA"
if [ -f "$DIR/Casks/openlid.rb" ]; then
    sed -i '' -E "s/sha256 \"[a-f0-9]{64}\"/sha256 \"$NEW_SHA\"/" "$DIR/Casks/openlid.rb"
    echo "✅ Updated Casks/openlid.rb with new sha256"
fi

cd "$DIR"

echo "✅ Dual Platform & Architecture Build Complete!"
echo "📍 Universal App:        $DIST_DIR/OpenLid.app"
echo "📍 Apple Silicon App:    $DIST_DIR/OpenLid-AppleSilicon.app"
echo "📍 Intel Mac App:        $DIST_DIR/OpenLid-Intel.app"
echo "📍 Universal CLI:        $DIST_DIR/openlid"
echo "📍 Windows x64 Archive:  $DIST_DIR/OpenLid-Windows-x64.zip"
echo "📍 Windows ARM64 Archive:$DIST_DIR/OpenLid-Windows-ARM64.zip"
