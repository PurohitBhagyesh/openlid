#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

# Ensure bundle exists or build it
if [ ! -d "$DIR/dist/OpenLid.app" ]; then
    "$DIR/scripts/bundle.sh"
fi

echo "📦 Installing OpenLid.app to /Applications..."
rm -rf "/Applications/OpenLid.app"
cp -R "$DIR/dist/OpenLid.app" "/Applications/OpenLid.app"

echo "⚙️ Installing 'openlid' CLI tool..."
if [ -w "/usr/local/bin" ]; then
    cp "$DIR/dist/openlid" "/usr/local/bin/openlid"
    chmod +x "/usr/local/bin/openlid"
    echo "✅ CLI installed to /usr/local/bin/openlid"
else
    echo "🔑 Sudo required to copy CLI to /usr/local/bin/openlid:"
    sudo cp "$DIR/dist/openlid" "/usr/local/bin/openlid"
    sudo chmod +x "/usr/local/bin/openlid"
    echo "✅ CLI installed to /usr/local/bin/openlid"
fi

echo ""
echo "🎉 OpenLid installed successfully!"
echo "• Launch from Applications or Spotlight: OpenLid"
echo "• Or run from Terminal: openlid on"

