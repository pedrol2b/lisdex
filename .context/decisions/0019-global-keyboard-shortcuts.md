# ADR 0019 — Global keyboard shortcuts via Carbon hot keys

- **Status:** Accepted (owner tested the build 2026-11-23)
- **Date:** 2026-11-23

## Context

Phase 7.2 adds four global shortcuts (Toggle, Start Indefinitely, Start for a Duration, Stop),
recorded in Settings. Options: the KeyboardShortcuts package, our own wrapper around Carbon
`RegisterEventHotKey`, or an `NSEvent` global monitor.

## Decision

- Use Carbon `RegisterEventHotKey` directly (`Sources/Lisdex/Shortcuts/`). No permission
  prompt, no package dependency, so the Homebrew source build stays dependency-free (ADR 0008).
- Shortcuts are stored in `settings.v1` (`AppSettings.shortcuts`, ADR 0006) with tolerant
  decoding: a bad entry drops only that entry.
- Combination rules (needs ⌃/⌥/⌘ unless an F-key, macOS-reserved combos, duplicates across
  actions) and display strings live in `LisdexCore` with tests.
- None assigned by default. Hot keys are registered with `kEventHotKeyExclusive`; when another
  app holds the combo exclusively, registration fails, the combo is kept, the row says
  "Already in use by another app", and Lisdex retries whenever it is brought forward. Only
  exclusive holders are detectable: system symbolic hot keys and other apps' non-exclusive
  registrations can't be seen through Carbon.
- `NSEvent` global monitors are not used: they need Accessibility permission, which is reserved
  for the mouse jiggler (Phase 9).

## Fallback

If the owner rejects the recorder/registration after testing, replace `HotKeyCenter` and the
recorder with the KeyboardShortcuts package, keep the Core actions and settings model, and
supersede this ADR.

## Consequences

We own the recorder UI and layout-aware key names (`UCKeyTranslate`). Carbon hot-key APIs are
old but still the supported way to register system-wide shortcuts without permissions.
