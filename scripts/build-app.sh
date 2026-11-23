#!/bin/bash
# Builds build/Lisdex.app from the SwiftPM package (no Xcode project needed). ADR 0001 / 0005.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${CONFIG:-release}"
APP="$ROOT/build/Lisdex.app"

cd "$ROOT"
# SWIFT_BUILD_FLAGS: extra flags, e.g. "--disable-sandbox" inside Homebrew's build sandbox.
read -r -a EXTRA <<< "${SWIFT_BUILD_FLAGS:-}"
swift build -c "$CONFIG" ${EXTRA[@]+"${EXTRA[@]}"}
BIN="$(swift build -c "$CONFIG" ${EXTRA[@]+"${EXTRA[@]}"} --show-bin-path)/Lisdex"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Lisdex"
cp "$ROOT/Support/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/assets/app-icon/Lisdex.icns" "$APP/Contents/Resources/Lisdex.icns"
# Menu bar pill / mug / bulb: vector template PDFs (ADR 0003, 0015).
cp "$ROOT"/assets/menubar/{pill,mug,bulb}-*.pdf "$APP/Contents/Resources/"

# Ad-hoc signature by default: the app is built on the user's Mac, so it is not quarantined and
# Gatekeeper lets it run (ADR 0005). Override with CODESIGN_IDENTITY="Developer ID Application: …".
IDENTITY="${CODESIGN_IDENTITY:--}"
codesign --force --sign "$IDENTITY" "$APP"
echo "Signed with: $([ "$IDENTITY" = "-" ] && echo ad-hoc || echo "$IDENTITY")"

# The bundle path is reused across builds; bump its date and re-register so LaunchServices
# picks up the current icon.
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" || true
echo "Built: $APP"
