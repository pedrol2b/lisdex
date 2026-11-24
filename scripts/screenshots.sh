#!/bin/bash
# Captures the README screenshots into assets/screenshots/ (dark appearance follows the system).
# Your Lisdex settings are backed up first and restored at the end.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Lisdex.app"
OUT="$ROOT/assets/screenshots"
DOMAIN=io.github.pedrol2b.lisdex
WORK="$(mktemp -d)"
trap 'pkill -x Lisdex || true; defaults delete "$DOMAIN" >/dev/null 2>&1 || true; [ -f "$WORK/prefs.plist" ] && defaults import "$DOMAIN" "$WORK/prefs.plist"; rm -rf "$WORK"' EXIT

mkdir -p "$OUT" "$ROOT/.build"
swiftc -O "$ROOT/scripts/window-id.swift" -o "$ROOT/.build/window-id"
defaults export "$DOMAIN" "$WORK/prefs.plist" 2>/dev/null || rm -f "$WORK/prefs.plist"

quit() { pkill -x Lisdex || true; while pgrep -x Lisdex >/dev/null; do sleep 0.1; done; }

# shot <name> <settings json> <target>
shot() {
  quit
  defaults write "$DOMAIN" settings.v1 -data "$(printf '%s' "$2" | xxd -p | tr -d '\n')"
  open "$APP" --args -LisdexScreenshot "$3"
  sleep 2.5
  local id
  id="$("$ROOT/.build/window-id" Lisdex)"
  screencapture -x -o -l "$id" "$OUT/$1.png"
  echo "captured $1"
}

# Weekdays 09:00–18:00 with a short Friday (weekday 6) until 15:00.
SCHEDULE='"schedule":{"days":[2,3,4,5,6],"start":540,"end":1080,"hours":{"6":{"start":540,"end":900}}}'
APPS='"appTriggers":[{"bundleID":"com.apple.dt.Xcode","name":"Xcode"},{"bundleID":"com.microsoft.VSCode","name":"Visual Studio Code"}]'
BASE="\"engine\":\"iokit\",\"keepDisplayAwake\":true,\"iconVariant\":\"pill\",\"accent\":\"gold\",$SCHEDULE,$APPS,\"notifyOnSessionEnd\":true,\"playsToggleSound\":false"
shot popover-duration "{$BASE,\"mode\":\"duration\",\"duration\":3600,\"activateOnLaunch\":true}" popover
shot popover-schedule "{$BASE,\"mode\":\"schedule\",\"activateOnLaunch\":true}" popover
shot popover-inactive "{$BASE,\"mode\":\"indefinitely\",\"activateOnLaunch\":false}" popover
shot settings-appearance "{$BASE,\"mode\":\"indefinitely\",\"activateOnLaunch\":false}" appearance
shot settings-power "{$BASE,\"mode\":\"indefinitely\",\"activateOnLaunch\":false}" power
shot settings-schedule "{$BASE,\"mode\":\"schedule\",\"activateOnLaunch\":false}" schedule
shot settings-apps "{$BASE,\"mode\":\"indefinitely\",\"activateOnLaunch\":false}" apps
quit
