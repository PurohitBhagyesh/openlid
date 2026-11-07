#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

# Generate 1024x1024 source if missing
if [ ! -f "Resources/icon_1024.png" ]; then
    swift scripts/generate_app_icon.swift
fi

ICONSET_DIR="Resources/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

SOURCE="Resources/icon_1024.png"

sips -z 16 16     "$SOURCE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32     "$SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32     "$SOURCE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64     "$SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128   "$SOURCE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256   "$SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$SOURCE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512   "$SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$SOURCE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
cp "$SOURCE" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "Resources/AppIcon.icns"
rm -rf "$ICONSET_DIR"

# Also copy high-res icon to website assets
cp "$SOURCE" "website/assets/app-icon.png"

echo "✅ AppIcon.icns generated successfully at Resources/AppIcon.icns!"

