#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
zsh scripts/generate-icon.sh
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$PWD/dist/SF Symbols Viewer.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/SymbolViewer" "$APP_DIR/Contents/MacOS/"
cp Sources/SymbolViewer/Resources/* "$APP_DIR/Contents/Resources/"
cp Sources/SymbolViewer/Resources/AppMetadata.plist "$APP_DIR/Contents/Info.plist"
plutil -lint "$APP_DIR/Contents/Info.plist"
codesign --force --deep --sign - "$APP_DIR"
print "Built: $APP_DIR"
