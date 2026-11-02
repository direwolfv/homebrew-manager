#!/bin/bash
# Build "Homebrew Manager.app". No Xcode needed — Command Line Tools are enough.
set -e
cd "$(dirname "$0")/.."

APP="Homebrew Manager.app"
VERSION=1.0.0

# Command Line Tools can ship an SDK newer than the running macOS (MacOSX.sdk -> 27 on macOS 26).
# Its SwiftUI @State is a macro whose plugin CLT lacks, so build against the SDK matching this
# macOS. Homebrew clears SDKROOT, so this matters most there. Xcode has no versioned dir: skipped.
SDK="$(xcode-select -p)/SDKs/MacOSX$(sw_vers -productVersion | cut -d. -f1).sdk"
[ -z "$SDKROOT" ] && [ -d "$SDK" ] && export SDKROOT="$SDK"

swift build -c release "$@"   # the Homebrew formula passes --disable-sandbox
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/HomebrewManager "$APP/Contents/MacOS/"

cat > "$APP/Contents/Info.plist" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Homebrew Manager</string>
  <key>CFBundleDisplayName</key><string>Homebrew Manager</string>
  <key>CFBundleIdentifier</key><string>com.direwolfv.homebrew-manager</string>
  <key>CFBundleExecutable</key><string>HomebrewManager</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>NSHumanReadableCopyright</key><string>© 2026 direwolfv. ISC License.</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
PLIST_EOF

codesign --force --sign - "$APP" >/dev/null 2>&1 || echo "(ad-hoc signing skipped)"
echo "built $PWD/$APP ($(du -sh "$APP" | cut -f1))"
echo "Next:  open \"$PWD/$APP\""
