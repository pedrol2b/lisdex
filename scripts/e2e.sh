#!/bin/bash
# End-to-end smoke test: launches build/Lisdex.app, drives it with lisdex:// links, seeded
# settings and a trigger app, and checks the power assertions macOS reports (`pmset -g
# assertions`). Runs on GitHub's macOS runners and locally (`make e2e`).
#
# Not covered (needs a person or a signed build): the mouse jiggler (Accessibility permission),
# Shortcuts actions and the Focus filter (team-signed build), clicks in the menu.
#
# Your Lisdex settings are backed up first and restored at the end; a running Lisdex is quit.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Lisdex.app"
DOMAIN=io.github.pedrol2b.lisdex
TRIGGER_APP=TextEdit
TRIGGER_ID=com.apple.TextEdit
WORK="$(mktemp -d)"
FAILED=0
STARTED_AT="$(date '+%Y-%m-%d %H:%M:%S')"

restore() {
  quit
  pkill -x "$TRIGGER_APP" 2>/dev/null || true
  defaults delete "$DOMAIN" >/dev/null 2>&1 || true
  [ -f "$WORK/prefs.plist" ] && defaults import "$DOMAIN" "$WORK/prefs.plist"
  rm -rf "$WORK"
}

quit() {
  pkill -x Lisdex 2>/dev/null || true
  while pgrep -x Lisdex >/dev/null; do sleep 0.1; done
}

launch() {
  open "$APP" || { sleep 1 && open "$APP"; }
  wait_for "Lisdex is running" 10 pgrep -x Lisdex
  sleep 1 # let it finish launching before links arrive
}

seed() { defaults write "$DOMAIN" settings.v1 -data "$(printf '%s' "$1" | xxd -p | tr -d '\n')"; }
stored() {
  defaults export "$DOMAIN" "$WORK/now.plist" && /usr/libexec/PlistBuddy -c 'Print :settings.v1' "$WORK/now.plist"
}
link() { open "lisdex://$1"; }

# Capture first: with pipefail, `grep -q` closing the pipe early would fail the pipeline.
holds() {
  local assertions
  assertions="$(pmset -g assertions)"
  grep -q 'named: "Lisdex' <<<"$assertions"
}
released() { ! holds; }
# Lisdex's caffeinate is the one tied to its pid (`-w <pid>`); others may be running.
LISDEX_PID=""
caffeinate_running() { pgrep -f "^/usr/bin/caffeinate .*-w $LISDEX_PID\$" >/dev/null; }
caffeinate_gone() { ! caffeinate_running; }

# wait_for <what> <seconds> <command...>: polls every 0.5 s until the command succeeds.
wait_for() {
  local what="$1" seconds="$2"
  shift 2
  local tries=$((seconds * 2))
  for ((i = 0; i < tries; i++)); do
    "$@" && return 0
    sleep 0.5
  done
  echo "  timed out after ${seconds}s waiting for: $what"
  return 1
}

check() {
  local name="$1"
  shift
  if "$@"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    FAILED=$((FAILED + 1))
  fi
}

# Minutes since midnight, `offset` minutes from now, wrapped to 0..1439.
minutes_from_now() {
  local now=$((10#$(date +%H) * 60 + 10#$(date +%M)))
  echo $((((now + $1) % 1440 + 1440) % 1440))
}

# Each seed names a key once: with duplicate keys the decoder keeps the first.
COMMON='"engine":"iokit","keepDisplayAwake":false,"notifyOnSessionEnd":false,"playsToggleSound":false'
BASE="$COMMON,\"activateOnLaunch\":false"
ACTIVE="$COMMON,\"activateOnLaunch\":true"
ALL_DAYS='[1,2,3,4,5,6,7]'

# --- Tests ---------------------------------------------------------------------------------

test_links() {
  seed "{$BASE,\"mode\":\"indefinitely\"}"
  launch
  released || return 1
  link on && wait_for "assertion after lisdex://on" 5 holds || return 1
  link off && wait_for "release after lisdex://off" 5 released || return 1
  link toggle && wait_for "assertion after toggle" 5 holds || return 1
  link toggle && wait_for "release after second toggle" 5 released || return 1
  link "on?until=stopped" && wait_for "assertion after until=stopped" 5 holds || return 1
  link off && wait_for "release" 5 released
}

test_bad_link_ignored() {
  link "on?minutes=0" && sleep 2
  released || return 1
  link "nonsense" && sleep 1
  pgrep -x Lisdex >/dev/null
}

test_duration_expires() {
  link "on?minutes=1" && wait_for "assertion after on?minutes=1" 5 holds || return 1
  sleep 50
  holds || { echo "  released before the minute was up"; return 1; }
  wait_for "release when the minute is up" 20 released
}

test_kill_releases_iokit() {
  link on && wait_for "assertion" 5 holds || return 1
  pkill -9 -x Lisdex
  wait_for "release after kill -9" 10 released
}

test_kill_releases_caffeinate() {
  quit
  seed "{${BASE/iokit/caffeinate},\"mode\":\"indefinitely\"}"
  launch
  LISDEX_PID="$(pgrep -x Lisdex)"
  link on && wait_for "caffeinate started" 5 caffeinate_running || return 1
  pkill -9 -x Lisdex
  wait_for "caffeinate gone after kill -9" 10 caffeinate_gone
}

test_schedule_window() {
  quit
  local start end
  start=$(minutes_from_now -10)
  end=$(minutes_from_now 60)
  seed "{$ACTIVE,\"mode\":\"schedule\",\"schedule\":{\"days\":$ALL_DAYS,\"start\":$start,\"end\":$end}}"
  launch
  wait_for "schedule holds inside its window" 5 holds || return 1
  quit
  start=$(minutes_from_now 120)
  end=$(minutes_from_now 180)
  seed "{$ACTIVE,\"mode\":\"schedule\",\"schedule\":{\"days\":$ALL_DAYS,\"start\":$start,\"end\":$end}}"
  launch
  sleep 2
  released || { echo "  held outside the schedule window"; return 1; }
}

test_app_trigger() {
  quit
  pkill -x "$TRIGGER_APP" 2>/dev/null || true
  seed "{$BASE,\"mode\":\"indefinitely\",\"appTriggers\":[{\"bundleID\":\"$TRIGGER_ID\",\"name\":\"$TRIGGER_APP\"}]}"
  launch
  released || return 1
  open -a "$TRIGGER_APP" && wait_for "assertion while $TRIGGER_APP is open" 10 holds || return 1
  pkill -x "$TRIGGER_APP"
  wait_for "release after $TRIGGER_APP quits" 10 released
}

test_settings_survive_relaunch() {
  quit
  seed "{$BASE,\"mode\":\"duration\",\"duration\":5400,\"iconVariant\":\"bulb\",\"accent\":\"gold\"}"
  launch
  quit
  launch
  quit
  local json
  json="$(stored)"
  echo "$json" | grep -q '"duration":5400' && echo "$json" | grep -q '"mode":"duration"' \
    || { echo "  settings after relaunch: $json"; return 1; }
}

test_corrupt_settings_fall_back() {
  quit
  defaults delete "$DOMAIN" settings.v1.corrupt >/dev/null 2>&1 || true
  seed '{"mode": not json'
  launch
  pgrep -x Lisdex >/dev/null || return 1
  released || return 1
  defaults read "$DOMAIN" settings.v1.corrupt >/dev/null 2>&1 \
    || { echo "  unreadable settings weren't kept under settings.v1.corrupt"; return 1; }
}

# --- Run -----------------------------------------------------------------------------------

[ -d "$APP" ] || { echo "No $APP — run 'make app' first."; exit 1; }
defaults export "$DOMAIN" "$WORK/prefs.plist" 2>/dev/null || rm -f "$WORK/prefs.plist"
trap restore EXIT
quit
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

check "lisdex:// links switch Keep Awake" test_links
check "invalid links are ignored" test_bad_link_ignored
check "on?minutes=1 ends after a minute" test_duration_expires
check "kill -9 releases the IOKit assertion" test_kill_releases_iokit
check "kill -9 stops caffeinate" test_kill_releases_caffeinate
check "schedule holds only inside its window" test_schedule_window
check "a listed app keeps the Mac awake while open" test_app_trigger
check "settings survive a relaunch" test_settings_survive_relaunch
check "corrupt settings fall back to defaults" test_corrupt_settings_fall_back

if [ "$FAILED" -gt 0 ]; then
  echo
  echo "$FAILED check(s) failed. Lisdex log since $STARTED_AT:"
  log show --style compact --start "$STARTED_AT" --predicate "subsystem == \"$DOMAIN\"" | tail -80
  exit 1
fi
echo
echo "All checks passed."
