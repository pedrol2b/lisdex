# Settings reorganisation — verification (2026-11-25)

Build: `make app` on branch `feat/settings-rework`, macOS 27.2 SDK, dark appearance.

| Check | Result | Evidence |
| ----- | ------ | -------- |
| `make test` | ✅ 170 tests in 29 suites | — |
| `make lint` | ✅ | — |
| Five tabs render; every group has a heading | ✅ | `settings-*-dark.png` |
| Schedule: shared hours by default, per-day list when days differ, "Runs overnight" under the day | ✅ (seeded Mon–Thu 09–18, Fri 22–02) | `settings-automation-seeded-dark.png` |
| Custom accent `#E0457B` loads, tints day pills and the icon card; wheel swatch shows it | ✅ | `settings-appearance-seeded-dark.png` |
| Preset swatch click saves (`settings.v1` changed gold → orange) | ✅ synthetic click | — |
| Custom swatch opens the Colors panel; picking a colour saves `#RRGGBB` and re-tints | ✅ synthetic click | — |
| Colors panel opens beside the Settings window | ⚠️ not seen: the check click landed on another app. Fix is in `ColorPanelPresenter.place` | — |
| Engine label no longer truncated ("Power assertions") | ✅ | `settings-power-dark.png` |
| caffeinate warning text identical to ADR 0002 | ✅ `diff` against the old file | — |
| Feature parity with the old six tabs | ✅ owner reviewed every tab; table in the session summary | owner screenshots |

Seeded screenshots used a temporary `settings.v1`; the owner's settings were exported first and
re-imported afterwards.

The Automation screenshot from the owner's real settings shows "Lisdex needs Accessibility
permission": expected for a fresh ad-hoc build (macOS ties the grant to the signature).

## Jiggler permission (follow-up)

TCC log showed `AUTHREQ_RESULT authValue=2` (allowed) for Lisdex while the Settings row still said
"needs Accessibility permission"; after a relaunch the row was ✅. With `AXIsProcessTrusted` added to
the check, the owner switched Lisdex off and on in Accessibility on a fresh build and the row
turned ✅ without a relaunch (2026-11-25).
