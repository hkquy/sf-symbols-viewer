#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"

SVG_PATH="$PWD/Sources/SymbolViewer/Resources/AppIcon.svg"
DEST_ICNS="$PWD/Sources/SymbolViewer/Resources/AppIcon.icns"
APP_ICNS="$PWD/dist/SF Symbols Viewer.app/Contents/Resources/AppIcon.icns"
TMP_DIR="$(mktemp -d /tmp/icon_build.XXXXXX)"
ICONSET_DIR="$TMP_DIR/AppIcon.iconset"
TMP_ICNS="$TMP_DIR/AppIcon.icns"

mkdir -p "$ICONSET_DIR"

print "Rendering SVG to iconset with alpha channel..."
osascript -l JavaScript - "$SVG_PATH" "$ICONSET_DIR" <<'EOF'
function run(argv) {
    ObjC.import("AppKit");
    ObjC.import("Foundation");

    var svgPath = argv[0];
    var outIconsetDir = argv[1];

    var sizes = [
        { name: "icon_16x16.png", size: 16 },
        { name: "icon_16x16@2x.png", size: 32 },
        { name: "icon_32x32.png", size: 32 },
        { name: "icon_32x32@2x.png", size: 64 },
        { name: "icon_128x128.png", size: 128 },
        { name: "icon_128x128@2x.png", size: 256 },
        { name: "icon_256x256.png", size: 256 },
        { name: "icon_256x256@2x.png", size: 512 },
        { name: "icon_512x512.png", size: 512 },
        { name: "icon_512x512@2x.png", size: 1024 }
    ];

    var img = $.NSImage.alloc.initWithContentsOfFile(svgPath);
    if (!img) {
        throw new Error("Failed to load SVG: " + svgPath);
    }

    for (var i = 0; i < sizes.length; i++) {
        var item = sizes[i];
        var s = item.size;
        var rep = $.NSBitmapImageRep.alloc.initWithBitmapDataPlanesPixelsWidePixelsHighBitsPerSampleSamplesPerPixelHasAlphaIsPlanarColorSpaceNameBytesPerRowBitsPerPixel(
            null, s, s, 8, 4, true, false, $.NSCalibratedRGBColorSpace, 0, 32
        );
        rep.size = $.NSMakeSize(s, s);

        $.NSGraphicsContext.saveGraphicsState;
        var context = $.NSGraphicsContext.graphicsContextWithBitmapImageRep(rep);
        context.imageInterpolation = $.NSImageInterpolationHigh;
        $.NSGraphicsContext.setCurrentContext(context);

        img.drawInRectFromRectOperationFraction(
            $.NSMakeRect(0, 0, s, s),
            $.NSMakeRect(0, 0, img.size.width, img.size.height),
            $.NSCompositeCopy,
            1.0
        );
        $.NSGraphicsContext.restoreGraphicsState;

        var data = rep.representationUsingTypeProperties($.NSPNGFileType, $());
        var filePath = outIconsetDir + "/" + item.name;
        data.writeToFileAtomically(filePath, true);
    }
}
EOF

print "Converting iconset to ICNS format..."
iconutil -c icns "$ICONSET_DIR" -o "$TMP_ICNS"

print "Updating project AppIcon.icns..."
cat "$TMP_ICNS" > "$DEST_ICNS"

if [ -d "$PWD/dist/SF Symbols Viewer.app" ]; then
    cat "$TMP_ICNS" > "$APP_ICNS"
    touch "$PWD/dist/SF Symbols Viewer.app"
fi

rm -rf "$TMP_DIR"
print "Successfully updated $DEST_ICNS (with transparent alpha channel)!"
