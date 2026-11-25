# Menu redesign — verification (2026-11-25)

Build: `make app` on branch `feat/settings-rework`, dark appearance, seeded `settings.v1` via
`scripts/screenshots.sh` (owner's settings restored afterwards).

| Check | Result | Evidence |
| ----- | ------ | -------- |
| `make test` | ✅ 176 tests in 31 suites | — |
| `make lint` | ✅ | — |
| Off / timer / schedule waiting render as designed | ✅ | `popover-inactive-dark.png`, `popover-duration-dark.png`, `popover-schedule-dark.png` |
| Jiggler banner with permission missing | ✅ (orange in this capture; accent since) | `popover-warning-dark.png` |
| Schedule row summary no longer truncated ("Mon–Fri") | ✅ | `popover-schedule-dark.png` |
| Banner follows a custom (mint) accent | ✅ owner, live | owner screenshot |
| Owner tried the running build | ✅ 2026-11-25 | — |

Not covered here: VoiceOver pass over the new card and mode rows; the login-approval banner
(needs a Login Items approval state to reproduce).
