# ADR 0022 — Shortcuts actions and Focus filter need a signed build; links for everyone

- **Status:** Accepted (owner picked option 2 and approved the design 2026-11-23)
- **Date:** 2026-11-23

## Context

Phase 8.3: drive Lisdex from Focus modes and Shortcuts. A spike (2026-11-23) showed:

- `swift build` with `-emit-const-values` plus `xcrun appintentsmetadataprocessor` produces
  `Metadata.appintents`; macOS indexes it and the actions appear in Shortcuts.
- Running an action needs a team-signed app. Ad-hoc signed (every Lisdex build, ADR 0005):
  "LinkDaemon.ProcessRegistry.Errors error 0". Apple Development certificate: the action runs.
- The processor ships with Xcode, not the Command Line Tools.

Options: native only when signed; native when signed plus `lisdex://` links for everyone;
Developer ID releases (paid, supersedes ADR 0005).

## Decision

Native when signed, plus links for everyone (owner, 2026-11-23).

- `lisdex://on`, `on?minutes=N` (1–1440), `on?until=stopped`, `off`, `toggle` — parsed by
  `KeepAwakeCommand` in Core; anything else is ignored. A link is a user action, like a shortcut.
- App Intents: Turn Keep Awake On (optional minutes), Turn Keep Awake Off, Is Keep Awake On?, and
  `KeepAwakeFocusFilter` (`SetFocusFilterIntent`). A Focus-started session has origin `.focus`
  and ends with the Focus; `FocusRules` mirrors the app trigger (never touches other sessions,
  manual off wins, battery cutoff first).
- `scripts/build-app.sh` adds the metadata only when `CODESIGN_IDENTITY` is set and the processor
  exists; otherwise it prints why it skipped. Ad-hoc builds never list actions that would fail.

## Consequences

- Homebrew and default `make app` users get links only; anyone with a free Apple ID certificate
  and Xcode gets the native actions and the Focus filter.
- Signed releases (if ever, ADR 0005) would light up the native actions for everyone.
- The build script depends on unofficial-but-stable compiler flags and the processor's CLI; if a
  future Xcode changes them, the step fails soft and the app builds without actions.
