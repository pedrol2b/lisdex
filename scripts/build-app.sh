#!/bin/bash
# Builds build/Lisdex.app from the SwiftPM package (no Xcode project needed). ADR 0001 / 0005.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${CONFIG:-release}"
APP="$ROOT/build/Lisdex.app"

cd "$ROOT"
# SWIFT_BUILD_FLAGS: extra flags, e.g. "--disable-sandbox" inside Homebrew's build sandbox.
read -r -a EXTRA <<< "${SWIFT_BUILD_FLAGS:-}"

# The macOS 27 SDK turns SwiftUI's @State into a macro whose plugin ships only with Xcode, so with
# just the Command Line Tools the build fails. Fall back to their newest macOS 26 SDK (the app
# targets macOS 14, so nothing is lost) until the plugin ships with them too.
if [ -z "${SDKROOT:-}" ]; then
  SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
  SDK_MAJOR="$(xcrun --sdk macosx --show-sdk-version | cut -d. -f1)"
  SWIFT_BIN="$(dirname "$(xcrun --find swift)")"
  PLATFORM_PLUGINS="$(xcrun --sdk macosx --show-sdk-platform-path 2>/dev/null || true)/Developer/usr/lib/swift/host/plugins"
  if [ "$SDK_MAJOR" -ge 27 ] \
    && [ ! -e "$PLATFORM_PLUGINS/libSwiftUIMacros.dylib" ] \
    && [ ! -e "$SWIFT_BIN/../lib/swift/host/plugins/libSwiftUIMacros.dylib" ]; then
    FALLBACK_SDK="$(find "$(dirname "$SDK_PATH")" -maxdepth 1 -name 'MacOSX26*.sdk' | sort -V | tail -1)"
    if [ -z "$FALLBACK_SDK" ]; then
      echo "error: the macOS $SDK_MAJOR SDK needs SwiftUI's macro plugin, which comes with Xcode." >&2
      echo "Install Xcode (or Command Line Tools that include a macOS 26 SDK) and try again." >&2
      exit 1
    fi
    export SDKROOT="$FALLBACK_SDK"
    echo "Using $(basename "$FALLBACK_SDK"): SwiftUI's macro plugin isn't in these Command Line Tools"
  fi
fi
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
