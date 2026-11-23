# ADR 0020 — App trigger flips the Keep Awake switch

- **Status:** Accepted (owner approved the design 2026-11-23; owner test pending)
- **Date:** 2026-11-23

## Context

Phase 8.1: keep the Mac awake while an app the user picked is open (the owner pictures VS Code
and Xcode). Until now every session came from the one Keep Awake switch plus a mode. Options:

- **A.** A listed app opening turns the switch on, as a session marked "started by an app".
- **B.** A separate hold layer next to the switch. Honouring "switching off wins" would need an
  extra snoozed state.
- **C.** A fourth mode, "While an app is open". The switch must already be on, and Duration or
  Schedule is lost meanwhile.

## Decision

Approach A (owner, 2026-11-23).

- `Session.origin` is `.user` or `.app`. `SessionPlanner` holds an app session until it ends,
  whatever the mode: no deadline, no schedule windows.
- The pure `AppTriggerRules` in Core decides from workspace events:
  - a listed app launching while Keep Awake is off starts an app session;
  - the last listed app quitting (or being removed from the list) ends an app session;
  - nothing else changes the session.
- `AppWatcher` uses `NSWorkspace` launch/terminate notifications. No permission is needed.
- The list lives in `settings.v1` as `appTriggers` (an array of bundle ID + name), empty by
  default, with tolerant decoding (bad, blank or duplicate entries are dropped).

## Consequences

- Owner's rules: the icon is unchanged (filled while held). Switching off while a listed app
  runs wins until a listed app opens again. The battery cutoff and display setting apply first,
  as for any session.
- Apps already open when Lisdex starts don't trigger. Only launches seen while Lisdex runs do.
- Any deliberate user start makes the session the user's: the switch, a mode change, a duration
  chip, the quick menu or a shortcut. Quitting the app then leaves it on.
- App-driven on/off is silent: no toggle sound and no notification.
- The popover switch ignores a set to its current value. SwiftUI re-sends it on the first click
  into a freshly opened popover, which would otherwise have turned an app session into the
  user's.
