#!/usr/bin/env bash
set -e

TAP_DIR="/opt/homebrew/Library/Taps/purohitbhagyesh/homebrew-openlid"
REPO_URL="git@github.com:PurohitBhagyesh/homebrew-openlid.git"

if [ ! -d "$TAP_DIR" ]; then
    echo "❌ Tap directory not found at $TAP_DIR"
    exit 1
fi

echo "🚀 Publishing Homebrew tap to GitHub..."
cd "$TAP_DIR"

if ! git remote | grep -q "origin"; then
    git remote add origin "$REPO_URL"
else
    git remote set-url origin "$REPO_URL"
fi

git push -u origin main
echo "✅ Successfully published Homebrew tap to https://github.com/PurohitBhagyesh/homebrew-openlid"
echo "Users can now install OpenLid with: brew install --cask PurohitBhagyesh/openlid/openlid"
