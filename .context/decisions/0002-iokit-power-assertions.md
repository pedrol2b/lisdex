# 0002 — Keep awake with IOKit power assertions; `caffeinate` as an opt-in engine

- **Status:** Accepted (owner, 2026-11-19)
- **Date:** 2026-11-19

## Context

The prototype spawned `/usr/bin/caffeinate`, which itself just holds IOKit power assertions. Calling IOKit directly removes the child process. Owner wants `caffeinate` kept as a user-selectable option with a clear explanation.

## Decision

- `KeepAwakeEngine` setting: `.iokit` (default) | `.caffeinate`. Both implement one `KeepAwakeBackend` protocol (`hold(display: Bool, reason: String)`, `release()`), so the rest of the app doesn't care which is active.
- **IOKit backend:** `IOPMAssertionCreateWithName` with `kIOPMAssertPreventUserIdleSystemSleep`, plus `kIOPMAssertPreventUserIdleDisplaySleep` when "Keep the display awake" is on. Named `"Lisdex: <mode>"` (visible in `pmset -g assertions`). macOS releases them automatically if the process exits or crashes.
- **caffeinate backend:** `/usr/bin/caffeinate -i [-d] -w <our pid>`. `-w` makes it exit when Lisdex exits, even on crash / `kill -9`. Terminated on release; restarted if it exits unexpectedly while a session is active (logged).
- Switching engines while active: start the new backend first, then release the old one (no sleep gap).
- Settings → Power shows this warning under the picker when `caffeinate` is selected:

  > **Lisdex uses macOS power assertions (IOKit) by default.** They live inside the app, show up as "Lisdex" in `pmset -g assertions`, and macOS clears them automatically if the app quits or crashes.
  > `caffeinate` runs as a separate background process. Lisdex ties it to its own lifetime, but it is one more process to manage, shows up only as "caffeinate", and may be blocked or killed by device-management tools. Use it only if you specifically prefer the system command.

## Implementation notes (Phase 2, 2026-11-19)

- Core: `PowerRequest` (state + settings → what to hold, reason `"Lisdex: <mode title>"`, caffeinate arguments) and `PowerCoordinator`, which acquires the new `PowerHold` before releasing the old one and keeps the old one if acquiring fails. Tested with a fake engine.
- App: `Sources/Lisdex/Power/IOKitAssertion.swift` (one assertion per type, rolled back if the second fails) and `Sources/Lisdex/Power/CaffeinateProcess.swift` (restarts up to 3 times if caffeinate dies while wanted, then turns Keep Awake off).
- Any failure to start turns Keep Awake off and logs to `Log.power`; the UI never shows "Active" without a hold.

## Consequences

- Default path has no child process and is crash-safe by design; Core stays IOKit-free and testable with a fake backend.
- The caffeinate path needs process supervision code (small, isolated in `CaffeinateBackend`).
- Neither engine keeps the Mac awake with the lid closed on battery (out of scope v1).

## Alternatives considered

- caffeinate only — the original prototype; kept as an option.
- `ProcessInfo.beginActivity(.idleSystemSleepDisabled)` — no named assertion, less control over display sleep.
