# App trigger — Phase 8.1

> **ADR 0026:** the Settings tab described here is now a section of Settings → Automation; see `lisdex-v1.md` "Settings window".

_Approved by owner 2026-11-23 (Approach A), with two changes: no turning on at Lisdex launch, and the app list starts empty._

## Intent

Keep the Mac awake while an app the user picked is open, without touching Lisdex. The owner pictures coding apps (VS Code, Xcode): open Xcode, walk away, the Mac stays awake; quit Xcode, it can sleep again. Any app can be picked.

## Goals / non-goals / anti-goals

- Goals: a list of apps in Settings, empty by default — the user picks every app; a listed app opening turns Keep Awake on; the last listed app quitting turns it off; no permission prompt.
- Non-goals: per-app settings (display awake, mode) — the existing global settings apply; matching by window title or "app is frontmost"; a separate icon for app-triggered sessions (owner: same icon as today).
- Anti-goals: Lisdex turning off a session the user started themselves; Lisdex fighting the user (turning back on right after they switched off).

## Owner's rules (2026-11-23)

1. Icon: unchanged — filled while held awake, whatever the reason.
2. Switch off while a listed app is still open: Keep Awake goes off and stays off; the app keeps running.
3. Battery cutoff and "Keep the display awake" apply to app-triggered sessions too; the battery cutoff comes first, as for any session.

## Approaches

- **A. The app flips the switch (picked).** A listed app opening starts an ordinary session, marked as started by that app. Icon, battery cutoff, display setting, popover all work as today.
- B. A separate hold layer next to the switch — needs an extra "snoozed" state to honour rule 2; more moving parts for the same result.
- C. A fourth mode "While an app is open" — the switch must already be on and the user loses Duration/Schedule meanwhile; doesn't fit "open Xcode and walk away".

## Design

**Core (Foundation only, tested)**
- `Session` gains an origin: `.user` or `.app` (the app session). `Session.start(...)` stays the user path.
- `SessionPlanner`: an app session holds until switched off (`holding(until: nil)`) whatever the mode — no duration deadline, no schedule windows.
- `AppTrigger` (`bundleID`, `name`) and `AppSettings.appTriggers: [AppTrigger]`; tolerant decoding (missing → empty, a bad entry is dropped, duplicates by bundle ID dropped).
- `AppTriggerRules` — pure decision from an event and the current session:
  - a listed app **launched** and Keep Awake is off → start an app session;
  - a listed app **quit**, the session is an app session, and no listed app is still running → off;
  - anything else → nothing (a user session is never touched; a manual "off" is not undone until a listed app launches again).
- `SessionStatus` for an app session: "While Xcode is open." (first running listed app by list order; "While 2 apps are open." for more).

**App**
- `AppWatcher` (`@MainActor`) — `NSWorkspace` `didLaunchApplication` / `didTerminateApplication`; on a quit it checks `runningApplications` for other listed apps; matches by bundle ID; reports to `AppModel`. No permission needed.
- `AppModel` applies `AppTriggerRules` and reconciles as usual. No toggle sound for app-driven changes (programmatic, like expiry).
- Settings: new **Apps** tab (`app.badge` symbol): list of picked apps with icon and name, `+` opens an `NSOpenPanel` on /Applications limited to apps, `−` removes. Empty state: one line explaining what it does.

**Records**
- ADR 0020 (app trigger flips the switch; session origin).
- Spec `lisdex-v1.md` interactions/settings sections gain the Apps tab.

## Calls (approved by owner 2026-11-23)

- **Lisdex starts while a listed app is already open** → nothing happens (owner, 2026-11-23). Only a launch seen while Lisdex runs turns Keep Awake on.
- **The user changes mode, taps a duration chip or uses a shortcut during an app session** → it becomes a normal user session in that mode; quitting the app no longer turns it off. (Any deliberate user action makes it theirs.)
- **Switch turned on by the user while a listed app is open** → user session; quitting the app leaves it on.
- **Battery cutoff ends an app session** → same as a manual off: stays off until a listed app launches again.
- **No "session ended" notification** when the app quits — the user quit it, they know.
- **Removing an app from the list while its session runs** → the session ends if no other listed app is running.

## Rollout

Branch `feat/app-trigger`; owner tests in `build/Lisdex.app` (with VS Code / Xcode) before merge. Ships in v1.2 with the rest of Phase 8.

## Left to the builder

File split, list row visuals (match the Settings form style), the exact empty-state copy.
