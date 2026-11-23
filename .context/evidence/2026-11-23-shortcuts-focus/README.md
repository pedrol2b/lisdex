# Shortcuts, Focus filter and links — verification (2026-11-23)

## Spike (throwaway, not committed)

- Const-values build + `appintentsmetadataprocessor` → `Metadata.appintents`; linkd "Inserting canonical bundle"; action listed in Shortcuts.
- Ad-hoc signed → running the action fails: "LinkDaemon.ProcessRegistry.Errors error 0" (Lisdex log: "Unable to re-register with Process Instance Registry"). Apple Development signed → "Registered process", `perform()` ran. Re-signed ad-hoc → fails again.
- LaunchServices won't create an app record for a bundle under `/private/tmp` (-10814).

## Branch build

| Check | Result |
| --- | --- |
| `make app` (ad-hoc) prints "Shortcuts actions: skipped (ad-hoc signature)", no `Metadata.appintents` | ✅ |
| `CODESIGN_IDENTITY=<Apple Development> make app` prints "Shortcuts actions: added"; metadata lists `TurnOnKeepAwakeIntent`, `TurnOffKeepAwakeIntent`, `IsKeepAwakeOnIntent`, `KeepAwakeFocusFilter` | ✅ |
| Signed build: Lisdex log "Registered process with identifier …" | ✅ |
| `open "lisdex://on?minutes=5"` → 2 Lisdex assertions; `lisdex://off` → 0 | ✅ |
| `open "lisdex://on?minutes=0"` → log "Ignored link …", nothing changes | ✅ |
| `lisdex://toggle` twice → on, then off | ✅ |
| Actions run from Shortcuts; Focus filter on/off with a real Focus | ⏳ owner test (GUI check stopped: the owner was using the Mac) |

Tests: `swift test` → 131 tests in 23 suites passed.
