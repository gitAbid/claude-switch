#!/bin/bash
set -e

APP_NAME="ClaudeSwitch"
DMG_NAME="${1:-$APP_NAME}"
VOLUME_NAME="$APP_NAME"
DMG_FINAL="${DMG_NAME}.dmg"
STAGING=$(mktemp -d)

echo "Setting up DMG staging..."
mkdir -p "$STAGING"
cp -r "${APP_NAME}.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_FINAL"

rm -rf "$STAGING"
echo "Created $DMG_FINAL"
