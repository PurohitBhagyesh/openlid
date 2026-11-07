#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

# Ensure apps are bundled
if [ ! -d "$DIR/dist/OpenLid.app" ]; then
    "$DIR/scripts/bundle.sh"
fi

build_dmg() {
    local source_app="$1"
    local dmg_filename="$2"
    local vol_name="$3"
    local temp_dir="$DIR/.build/dmg_temp_$dmg_filename"

    echo "💿 Creating $dmg_filename..."
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"

    # Always name the target inside the DMG as "OpenLid.app"
    cp -R "$DIR/dist/$source_app" "$temp_dir/OpenLid.app"
    ln -s /Applications "$temp_dir/Applications"

    hdiutil create -volname "$vol_name" -srcfolder "$temp_dir" -ov -format UDZO "$DIR/dist/$dmg_filename" > /dev/null
    rm -rf "$temp_dir"

    # Copy to website downloads directory
    mkdir -p "$DIR/website/downloads"
    cp "$DIR/dist/$dmg_filename" "$DIR/website/downloads/$dmg_filename"
}

build_dmg "OpenLid.app" "OpenLid-Universal.dmg" "OpenLid Universal"
build_dmg "OpenLid-AppleSilicon.app" "OpenLid-AppleSilicon.dmg" "OpenLid Apple Silicon"
build_dmg "OpenLid-Intel.app" "OpenLid-Intel.dmg" "OpenLid Intel"

echo "✅ All DMGs created with OpenLid.app -> /Applications link!"
