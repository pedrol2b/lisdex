# Mouse jiggler — Phase 9

_Approved by owner 2026-11-24 (Approach A)._

## Intent

Keep Teams and Slack showing the owner as available while Keep Awake holds the Mac awake. Power assertions keep the Mac awake but don't stop chat apps from going "Away": they read the system's idle time (time since the last keyboard/mouse input), so Lisdex has to make that idle time look recent.

## Findings (spike, 2026-11-23/24)

| Question | Answer |
| --- | --- |
| A synthetic mouse-move event resets the idle time apps read (IOKit `HIDIdleTime`, CoreGraphics combined/HID state)? | Yes — even a 0 px move at the current position |
| `IOPMAssertionDeclareUserActivity` (no permission) resets it? | No |
| Posting events needs | Accessibility / "post event" permission (`CGPreflightPostEventAccess`) |
| Ad-hoc build after a rebuild / `brew upgrade` | Permission lost; the Settings switch still shows **on** but doesn't apply — the user must switch it off and on |
| Certificate-signed build after a rebuild | Permission kept |

## Goals / non-goals / anti-goals

- Goals: Teams/Slack stay "available" while Keep Awake holds; never visible to the user (no cursor movement); stops the instant the user really touches the Mac; clear guidance when the permission is missing or went stale after an update.
- Non-goals: jiggling while Keep Awake is off or waiting outside a schedule window; per-app targeting; keyboard events; working without the permission.
- Anti-goals: the cursor moving under the user; fighting the user's own input (drag, held key); a silent no-op after an update that the user only discovers when Teams shows Away.

## Approaches (owner picked A, 2026-11-24)

- **A. A section in Settings → Power, plus a warning line in the popover (picked).**
- B. Its own Settings tab — roomy, but it's one switch and two sliders that belong with "stay awake" settings.
- C. A switch in the popover — the popover grows for something set once.

## Design

**Behaviour**
- Off by default (needs a permission). When on, it runs only while Keep Awake is **holding** (any session origin; not while waiting outside a schedule window, not while off).
- After the user has been idle for the **idle threshold** (default 60 s), post one mouse-moved event at the current cursor position (0 px — the spike shows that's enough); repeat every **interval** (default 20 s) while the user stays idle.
- Real input ends jiggling at once: any input not caused by Lisdex, or a key or mouse button held down, restarts the idle wait.
- Sliders: idle threshold 30 s – 4 min (Teams goes Away after about 5 min), step 30 s; interval 10 – 60 s, step 5 s.

**Core (Foundation only, tested)**
- `JigglerSettings { isEnabled, idleThreshold, interval }` in `AppSettings` (key `jiggler`), defaults off / 60 / 20, values clamped to the slider ranges, tolerant decoding.
- `JigglerClock` — pure: given `now`, the system idle seconds, whether input is held, and its state (`lastRealInput`, `lastJiggle`), says *jiggle now* or *check again at*, and returns the new state. An idle reading that matches Lisdex's own last jiggle (within 1 s) is Lisdex's, not the user's.

**App**
- `Jiggler` (`@MainActor`): one timer scheduled from `JigglerClock` (no fixed polling); reads `CGEventSource.secondsSinceLastEventType(.combinedSessionState, …)`, held keys/buttons via `CGEventSource` state, posts `.mouseMoved` at the current location on `.cghidEventTap`. Started/stopped by `AppModel.reconcile` (holding + enabled + permitted).
- Permission: `CGPreflightPostEventAccess()`; refreshed when Settings or the popover opens and when the app becomes active.
- Settings → Power, section "Chat apps": switch "Keep me active in chat apps (mouse jiggler)"; the two sliders (disabled while off); permission row — ✅ "Lisdex can keep you active." or ⚠︎ "Lisdex needs Accessibility permission." with **Open Accessibility Settings** (calls `CGRequestPostEventAccess` once, then opens the pane), and the footnote "After updating Lisdex, macOS may keep showing it as allowed while it isn't: switch Lisdex off and on there."
- Popover: when the jiggler is on and Keep Awake holds but the permission is missing, one warning line "Mouse jiggler needs permission" with a link to the pane.

**Records** — ADR 0024 (jiggler via posted 0 px mouse events; permission and its loss on ad-hoc rebuilds); spec `lisdex-v1.md` Settings; README feature row + note; CHANGELOG; evidence with the spike table.

## Calls (mine — check these)

- 0 px instead of the roadmap's "2 px and back": invisible, and the spike shows it resets idle time just the same.
- Off by default; the jiggler never asks for the permission until the user turns it on.
- Runs for any holding session (user, app, Focus, link), not just user sessions.

## Rollout

Branch `feat/mouse-jiggler`; owner tests with Teams/Slack (leave the Mac idle > 5 min while held; status stays Available) and the permission flow; merge locally. Then all roadmap phases are done and the owner decides on pushing / releasing v1.2.

## Left to the builder

File split, exact slider labels/format, timer tolerance, logging.
