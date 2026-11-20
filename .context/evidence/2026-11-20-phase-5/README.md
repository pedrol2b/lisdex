# Phase 5 — Hardening (2026-11-20)

Two read-only reviews ran: a Swift code review (no HIGH findings, no assertion or caffeinate
leak path) and an energy + VoiceOver audit. After the fixes: lint clean, no build warnings,
51 tests pass, Core line coverage 96 %.

## Fixed

| Finding | Fix |
| --- | --- |
| Engine start failure / caffeinate give-up only logged | Notification "Keep Awake couldn't start" / "Keep Awake stopped" (`AppModel`) |
| Start on Login failure only logged | Notification pointing to System Settings → Login Items |
| caffeinate restart budget never reset | A run ≥ 60 s resets it (`CaffeinateProcess.healthyRun`) |
| Corrupt settings silently overwritten | Raw data copied to `settings.v1.corrupt` first (+ test) |
| Non-finite duration accepted | `isFinite` check on decode |
| Power-source callback in `.defaultMode` only | `.commonModes`, like `SessionClock` |
| Popover SwiftUI tree (1 s timelines) alive while closed | Hosting controller created on show, dropped in `popoverDidClose` |
| Header refreshed every second in every mode | 1 s only for a running duration, otherwise 15 s |
| Status icon re-rendered on every settings change | Renders only when `MenuBarIcon` changes |
| Every 1 % battery tick re-planned | Re-plan only on AC/battery flip or when a cutoff applies |
| Selected state not announced | `accessibilityValue` "Selected" / day pills "On"/"Off" |
| Chips read "1 h" | Spoken labels ("1 hour", "Custom duration, 45 minutes") via `DurationText.spoken` (+ test) |
| Right-click toggle undiscoverable; toggle row detail not read | Status item `accessibilityHelp`; `accessibilityHint(detail)` on rows |

## Accepted (documented, not changed)

- **Wall-clock deadlines move with manual clock changes** — intended by ADR 0013 so sleep time
  counts; NTP corrections are seconds.
- **A failure at a schedule window start turns Keep Awake off** — now announced by notification
  instead of silent; automatic retry deferred until it's seen in practice.
- **Schedule windows inside a DST gap skip that day** — consistent in `window()`/`nextStart()`,
  no loop.
- **`DateFormatter` per header refresh** — only while the popover is open, now ≤ 1/s in
  duration mode.
- **Focus rings on plain-style buttons** — needs a manual check with Full Keyboard Access.

## Not verified here

Automated clicks couldn't open the popover (menu bar extras aren't exposed to the automation
helper, and System Events lacks assistive access), so the owner checks that the popover still
opens and closes normally after the on-demand content change.
