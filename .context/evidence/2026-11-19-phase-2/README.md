# Phase 2 — keep-awake core (2026-11-19)

## Automated

- `swift test`: 24 tests in 6 suites pass (new: `AppSettings`, `PreferencesStore`, `PowerRequest`, `PowerCoordinator`).
- `make lint` clean; `swift build` has no warnings.

## Manual

- Fresh launch: no Lisdex assertion in `pmset -g assertions` (Lisdex launches inactive). Only `runningboardd`'s brief launch assertion appears.
- IOKit, on (owner toggled): `pid 71465(Lisdex) PreventUserIdleSystemSleep named: "Lisdex: Indefinitely"` and `PreventUserIdleDisplaySleep named: "Lisdex: Indefinitely"`; log `IOKit assertions held (2)`. Off: no Lisdex assertions. ✅ acceptance 1
- Persistence: wrote `settings.v1` = `{"engine":"caffeinate"}` with `defaults write … -data`, relaunched; the app loaded it (other fields defaulted). ✅ acceptance 11 (partial: corrupt-data path covered by tests)
- caffeinate, on: exactly one child `/usr/bin/caffeinate -i -d -w 74813` (ppid = Lisdex 74813), no IOKit assertions. ✅
- Supervision: `kill` of the child → log `caffeinate exited unexpectedly (status 15)` then `caffeinate started (pid 75430)` within 1 ms. ✅
- caffeinate, off: no `caffeinate -w` process left. ✅
- Reset afterwards: `defaults delete io.github.pedrol2b.lisdex settings.v1`, relaunched on defaults.
- Not exercised: `kill -9` of Lisdex while caffeinate runs (relies on caffeinate's own `-w`); engine switch while active (no UI until Phase 4; covered by `PowerCoordinator` tests).
