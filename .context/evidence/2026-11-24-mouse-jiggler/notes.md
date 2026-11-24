# Mouse jiggler — evidence

## Spike (2026-11-23/24, throwaway app `io.github.pedrol2b.lisdex.jigglespike`, since deleted)

| Question | Answer |
| --- | --- |
| Posted `.mouseMoved` (0 px, `.cghidEventTap`) resets `HIDIdleTime` and CG combined idle? | Yes |
| `IOPMAssertionDeclareUserActivity` resets them? | No |
| Permission needed | Accessibility / post event (`CGPreflightPostEventAccess`) |
| Ad-hoc rebuild | Grant lost; System Settings still shows the switch on |
| Certificate-signed rebuild | Grant kept |

Cleanup: `tccutil reset Accessibility|PostEvent io.github.pedrol2b.lisdex.jigglespike`.

## Build checks (feat/mouse-jiggler)

- `make test`: 148 tests in 25 suites pass (JigglerSettings 5, JigglerClock 7, AppSettings +1).
- `make lint` clean; `make app` builds; Xcode 26.6 (Swift 6.3.3) release build completes.
- Settings → Power, jiggler off: "Chat apps" section with switch, caption, "Start after 1 min",
  "Repeat every 20 s", sliders disabled (screenshot checked, not committed).
