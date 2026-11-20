# Phase 3 — Duration expiry (2026-11-20)

The planned 30-minute run was interrupted (owner switched to Schedule at 11:47), so expiry was
re-run with a 60 s duration written straight into `settings.v1` (`activateOnLaunch: true`,
engine IOKit) and the app relaunched. Owner settings were backed up with `defaults export`
and restored afterwards.

| Check | Result |
| --- | --- |
| Assertions at start | `PreventUserIdleSystemSleep` + `PreventUserIdleDisplaySleep` named "Lisdex: For a Duration" |
| Deadline | 14:19:08.707 local (launch 14:18:08.707 + 60 s) |
| Expiry log | `Duration ended; Keep Awake off` at 14:19:08.907 (+0.2 s, the timer tolerance) |
| After expiry | `IOKit assertions released`; `pmset -g assertions` shows no Lisdex entries |

Schedule end (18:00 local) and restart-before-release on mode switches were confirmed from
logs earlier the same day (see `status/current.md`).

## Phase 4 owner check

Owner tested the Settings window (General / Power / Appearance), Start on Login, accent and
icon-variant switching and the caffeinate warning: "things seems fine".

## Core coverage (`make coverage`, `llvm-cov report`)

All Core files ≥ 93 % lines, total **96 %**. `KeepAwakeEngine.swift` (titles only) is uncovered.
