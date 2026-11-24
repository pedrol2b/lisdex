# ADR 0024 — Mouse jiggler: posted 0 px mouse moves, Accessibility permission

- **Status:** Accepted (owner approved spec `mouse-jiggler.md`, 2026-11-24)
- **Date:** 2026-11-24

## Context

Teams and Slack mark the user Away from the system idle time, which power assertions don't
touch. Spike 2026-11-23/24 (evidence `2026-11-24-mouse-jiggler`):

- A `CGEvent` `.mouseMoved` posted at `.cghidEventTap` resets IOKit `HIDIdleTime` and the
  CoreGraphics combined-session idle time, even at the current cursor position (0 px).
- `IOPMAssertionDeclareUserActivity` (no permission needed) does not reset them.
- Posting events needs the Accessibility / post-event permission (`CGPreflightPostEventAccess`).
- Ad-hoc builds lose the grant on every rebuild / `brew upgrade` while System Settings keeps
  showing the switch on; certificate-signed builds keep it.

## Decision

- Jiggle with a 0 px `.mouseMoved` at the cursor (not "2 px and back"): invisible, same effect.
- Off by default; Lisdex asks for the permission only from Settings → Power → Chat apps
  ("Open Accessibility Settings"). Runs only while enabled, Keep Awake holds (any session
  origin) and the permission is granted; not while the screen is locked or the display asleep
  (a jiggle would wake it). Caps Lock and fn don't count as held keys. While running, Lisdex
  holds a `ProcessInfo` activity so App Nap can't delay the timer.
- `JigglerClock` (Core, pure) decides from the idle time and held keys/buttons; an idle reading
  within 1 s of Lisdex's own last jiggle is Lisdex's. One timer, no fixed polling.
- The permission is re-read when the popover or Settings opens, when Lisdex becomes active and
  every 2 s while Settings shows it missing. Settings explains the stale-grant fix (switch
  Lisdex off and on in System Settings); the popover shows "Mouse jiggler needs permission"
  when it matters.

## Consequences

- Ad-hoc / Homebrew users re-grant after each update (documented in Settings and README).
- While the jiggler runs the screen saver and display sleep wait too (said in Settings).
- Lisdex now holds the Accessibility permission when the user grants it; it only posts mouse
  moves at the current cursor position.
