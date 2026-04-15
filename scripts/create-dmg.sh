#!/bin/bash
set -e

APP_NAME="ClaudeSwitch"
DMG_NAME="${1:-$APP_NAME}"
VOLUME_NAME="$APP_NAME"
DMG_DIR=$(mktemp -d)
DMG_STAGING="$DMG_DIR/staging"

echo "Setting up DMG staging..."
mkdir -p "$DMG_STAGING"
cp -r "${APP_NAME}.app" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}.dmg"

# Remove old artifacts
rm -f "$DMG_TEMP" "$DMG_FINAL"

echo "Creating DMG image..."
hdiutil create -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDRW \
  "$DMG_TEMP"

echo "Configuring DMG window..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_POINT="/Volumes/$VOLUME_NAME"
sleep 2

# Set window size, position, and icon arrangement via AppleScript
osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 900, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file "background.png" of folder ".background" of disk "$VOLUME_NAME"
        delay 1
        set position of item "${APP_NAME}.app" of container window to {140, 200}
        set position of item "Applications" of container window to {360, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Create background image using Python
mkdir -p "$MOUNT_POINT/.background"
python3 - "$MOUNT_POINT/.background/background.png" <<'PYEOF'
import sys
try:
    from PIL import Image, ImageDraw
    img = Image.new("RGBA", (500, 400), (30, 30, 30, 255))
    draw = ImageDraw.Draw(img)

    # Draw arrow from app to Applications
    arrow_y = 210
    draw.line([(180, arrow_y), (310, arrow_y)], fill=(180, 180, 180, 200), width=3)
    # Arrowhead
    draw.polygon([(310, arrow_y), (298, arrow_y - 10), (298, arrow_y + 10)], fill=(180, 180, 180, 200))

    img.save(sys.argv[1])
except ImportError:
    # Fallback: create a simple solid background
    import struct, zlib
    width, height = 500, 400
    def create_png(w, h, rgba):
        raw = b""
        for y in range(h):
            raw += b"\x00"
            for x in range(w):
                raw += struct.pack("BBBB", *rgba)
        def chunk(ctype, data):
            c = ctype + data
            return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)
        ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
        return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
    with open(sys.argv[1], "wb") as f:
        f.write(create_png(w, h, (30, 30, 30, 255)))
PYEOF

# Re-run AppleScript to apply background
osascript <<EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 100, 900, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file "background.png" of folder ".background" of disk "$VOLUME_NAME"
        set position of item "${APP_NAME}.app" of container window to {140, 200}
        set position of item "Applications" of container window to {360, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

echo "Finalizing DMG..."
hdiutil detach "$DEVICE" -quiet
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -f "$DMG_TEMP"
rm -rf "$DMG_DIR"

echo "Created $DMG_FINAL"
