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

IDENTITY="${CODESIGN_IDENTITY:--}"

# Shortcuts actions and the Focus filter (spec shortcuts-focus, ADR 0022) run only in an app
# signed with a team identity, so ad-hoc builds leave the App Intents metadata out entirely.
INTENTS_PROCESSOR=""
if [ "$IDENTITY" = "-" ]; then
  echo "Shortcuts actions: skipped (ad-hoc signature)"
elif ! INTENTS_PROCESSOR="$(xcrun --find appintentsmetadataprocessor 2>/dev/null)"; then
  INTENTS_PROCESSOR=""
  echo "Shortcuts actions: skipped (appintentsmetadataprocessor not found; it comes with Xcode)"
else
  INTENTS_WORK="$(mktemp -d)"
  trap 'rm -rf "$INTENTS_WORK"' EXIT
  for flag in -emit-const-values -Xfrontend -const-gather-protocols-file -Xfrontend \
    "$ROOT/scripts/appintents-protocols.json"; do
    EXTRA+=(-Xswiftc "$flag")
  done
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

if [ -n "$INTENTS_PROCESSOR" ]; then
  # Constant values the compiler emitted for the app module in this configuration. The build
  # directory layout differs between SwiftPM versions and older layouts can linger, so take only
  # the directory holding the newest file, and only files for current sources.
  find "$ROOT/.build" -ipath "*/$CONFIG/*" -name '*.swiftconstvalues' -not -ipath '*LisdexCore*' \
    -exec stat -f '%m %N' {} + 2>/dev/null | sort -rn > "$INTENTS_WORK/candidates.txt" || true
  NEWEST="$(head -1 "$INTENTS_WORK/candidates.txt" | cut -d' ' -f2-)"
  : > "$INTENTS_WORK/constvalues.txt"
  if [ -n "$NEWEST" ]; then
    CONST_DIR="$(dirname "$NEWEST")"
    for file in "$CONST_DIR"/*.swiftconstvalues; do
      name="$(basename "$file" .swiftconstvalues)"
      if [[ "$name" == *-primary ]] || [ -n "$(find "$ROOT/Sources/Lisdex" -name "$name.swift")" ]; then
        echo "$file" >> "$INTENTS_WORK/constvalues.txt"
      fi
    done
  fi
  if [ ! -s "$INTENTS_WORK/constvalues.txt" ]; then
    echo "Shortcuts actions: skipped (no compiler constant values found)"
    INTENTS_PROCESSOR=""
  fi
fi

if [ -n "$INTENTS_PROCESSOR" ]; then
  find "$ROOT/Sources/Lisdex" -name '*.swift' > "$INTENTS_WORK/sources.txt"
  TOOLCHAIN="$(dirname "$(dirname "$(dirname "$(xcrun --find swift)")")")"
  "$INTENTS_PROCESSOR" --force --quiet-warnings \
    --output "$APP/Contents/Resources" \
    --toolchain-dir "$TOOLCHAIN" \
    --module-name Lisdex \
    --sdk-root "${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}" \
    --xcode-version "$(xcodebuild -version | awk '/Build version/ {print $3}')" \
    --platform-family macOS \
    --deployment-target 14.0 \
    --target-triple "$(uname -m)-apple-macos14.0" \
    --source-file-list "$INTENTS_WORK/sources.txt" \
    --swift-const-vals-list "$INTENTS_WORK/constvalues.txt" 2>&1 | grep -v "^[0-9-]* [0-9:.]* appintentsmetadataprocessor" || true
  if [ -f "$APP/Contents/Resources/Metadata.appintents/extract.actionsdata" ]; then
    echo "Shortcuts actions: added"
  else
    echo "Shortcuts actions: metadata step failed; building without them" >&2
  fi
fi

# Ad-hoc signature by default: the app is built on the user's Mac, so it is not quarantined and
# Gatekeeper lets it run (ADR 0005). Override with CODESIGN_IDENTITY="Developer ID Application: …".
codesign --force --sign "$IDENTITY" "$APP"
echo "Signed with: $([ "$IDENTITY" = "-" ] && echo ad-hoc || echo "$IDENTITY")"

# The bundle path is reused across builds; bump its date and re-register so LaunchServices
# picks up the current icon.
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" || true
echo "Built: $APP"
