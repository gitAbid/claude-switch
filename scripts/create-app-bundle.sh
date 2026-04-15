#!/bin/bash
set -e

APP_NAME="ClaudeSwitch"
BUILD_DIR=".build/release"
BUNDLE_DIR="${APP_NAME}.app"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${BUNDLE_DIR}/Contents/MacOS/"

cat > "${BUNDLE_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClaudeSwitch</string>
    <key>CFBundleIdentifier</key>
    <string>com.claude.model-switcher</string>
    <key>CFBundleName</key>
    <string>ClaudeSwitch</string>
    <key>CFBundleDisplayName</key>
    <string>ClaudeSwitch</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
PLIST

echo "Created ${BUNDLE_DIR}"
echo "Install with: cp -r ${BUNDLE_DIR} /Applications/"
