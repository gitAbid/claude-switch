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

# Create double-clickable installer that copies app and removes quarantine
cat > "$STAGING/Install.command" << 'INSTALL'
#!/bin/bash
set -e
echo "Installing ClaudeSwitch..."
sudo cp -r "$(dirname "$0")/ClaudeSwitch.app" /Applications/
sudo xattr -cr /Applications/ClaudeSwitch.app
echo ""
echo "ClaudeSwitch installed successfully!"
echo "You can find it in /Applications or search via Spotlight."
open /Applications
INSTALL
chmod +x "$STAGING/Install.command"

echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_FINAL"

rm -rf "$STAGING"
echo "Created $DMG_FINAL"
