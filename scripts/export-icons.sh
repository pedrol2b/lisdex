#!/bin/bash
# Regenerates every icon export from the SVG sources in assets/ (ADR 0003). Never edit PNGs by hand.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RENDER="$ROOT/.build/render-svg"
cd "$ROOT/assets"

mkdir -p "$ROOT/.build"
swiftc -O "$ROOT/scripts/render-svg.swift" -o "$RENDER"

# Menu bar templates (ADR 0015): 18 pt tall pill (20 wide) and coffee mug and light bulb (18 × 18), black + alpha only,
# plain and with a mode badge (ADR 0025). Vector PDF for the app + 1x/2x/3x PNG for docs.
for svg in menubar/*.svg; do
  name="$(basename "$svg" .svg)"
  "$RENDER" "menubar/$name.svg" "menubar/$name.pdf" 18
  "$RENDER" "menubar/$name.svg" "menubar/$name.png" 18
  "$RENDER" "menubar/$name.svg" "menubar/$name@2x.png" 36
  "$RENDER" "menubar/$name.svg" "menubar/$name@3x.png" 54
done

# App icon masters: full-bleed (Icon Composer) and the macOS-grid tile (README, .icns).
mkdir -p app-icon/export app-icon/AppIcon.appiconset
"$RENDER" app-icon/source/app-pill-master.svg app-icon/export/app-pill-1024-fullbleed.png 1024
"$RENDER" app-icon/source/app-pill-macos.svg app-icon/export/app-pill-1024.png 1024

# Icon set (ADR 0012/0015): Figma "macOS grid" exports — 824 px tile at 100 px margin with the
# artwork already scaled inside, so no extra masking here. Optical pill for 16/32 px.
SMALL=app-icon/source/app-pill-optical-macos.svg
LARGE=app-icon/source/app-pill-macos.svg
SET=app-icon/AppIcon.appiconset
for spec in 16:16:$SMALL 16@2x:32:$SMALL 32:32:$SMALL 32@2x:64:$LARGE \
  128:128:$LARGE 128@2x:256:$LARGE 256:256:$LARGE 256@2x:512:$LARGE 512:512:$LARGE 512@2x:1024:$LARGE; do
  IFS=: read -r name px src <<< "$spec"
  base="${name%@2x}"
  suffix="${name#"$base"}"
  "$RENDER" "$src" "$SET/icon_${base}x${base}${suffix}.png" "$px"
done

ICONSET="$ROOT/.build/Lisdex.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
cp "$SET"/*.png "$ICONSET/"
iconutil -c icns "$ICONSET" -o app-icon/Lisdex.icns
echo "Icons exported."
