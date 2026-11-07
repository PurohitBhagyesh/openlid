#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-8080}"

echo "🌐 Starting OpenLid aesthetic web server on http://localhost:$PORT..."
echo "Press Ctrl+C to stop."
cd "$DIR/website"
python3 -m http.server "$PORT"
