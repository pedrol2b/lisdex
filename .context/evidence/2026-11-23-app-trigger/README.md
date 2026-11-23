# App trigger — verification (2026-11-23)

Build `build/Lisdex.app` from `feat/app-trigger`. TextEdit was the listed app. The state was
read from `pmset -g assertions` (a `Lisdex:` line means held) and the unified log.

| Check | Result |
| --- | --- |
| Lisdex starts with TextEdit not running | off |
| TextEdit opens | on: "A listed app opened; Keep Awake on"; popover "While TextEdit is open." (`popover-while-textedit.png`) |
| TextEdit quits (AppleScript quit, and `pkill`) | off |
| Switch off in the popover while TextEdit runs, quit, reopen | stays off after the quit, on again after the reopen |
| Quick menu → Until I Stop while TextEdit runs, then quit TextEdit | stays on (now the user's session) |
| Settings → Apps empty state | `settings-apps-empty-dark.png` |
| Add App… → picked `/System/Applications/TextEdit.app` | row with icon and name; saved in `settings.v1` |
| Two apps listed | `settings-apps-dark.png` |
| ✕ on TextEdit while it runs | off |
| `swift test` | 103 tests, all pass |

## Bug found while testing

The first click on the Keep Awake switch in a freshly opened popover re-sends the switch's
current value: the log shows "Plan off" while Keep Awake was already off. `setOn(true)` then
restarted the session as the user's, so quitting TextEdit left it on. `switchOn` now ignores a
set to the current value. After the fix the first click does nothing and the next one toggles.
This quirk predates the feature, but before it only restarted the same session.

Not covered: light mode screenshots (would mean switching the owner's appearance). This is
left for the owner's test.
