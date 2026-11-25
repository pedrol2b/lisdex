# Manual test before a release

`make e2e` covers links, timed sessions, crashes, the schedule window, app triggers and settings
(see `scripts/e2e.sh`). These need a person, a permission or a certificate-signed build. Run them
on a signed build: `CODESIGN_IDENTITY="Apple Development: …" make app && open build/Lisdex.app`.
Record the results in `.context/evidence/<date>-release-<version>/`.

## Menu and clicks

- [ ] Left-click opens the menu; right-click toggles (or the other way round, per Settings →
      General → Menu bar icon). Option-click opens the quick menu; 15 Minutes starts a session.
- [ ] The switch in the menu turns Keep Awake on and off; the icon fills and dims.
- [ ] A global shortcut (Settings → Shortcuts) toggles Keep Awake from another app.

## Schedule (per day)

- [ ] Settings → Automation → Schedule: turn on "Different hours per day", give Friday shorter
      hours. The menu shows the summary and Edit Hours…, which opens the Automation tab.
- [ ] Turn "Different hours per day" off: every day takes Monday's hours; the menu shows the plain
      From/To fields again.

## Accent colour

- [ ] Settings → Appearance: the last swatch opens the Colors panel beside the Settings window;
      picking a colour re-tints the window and the menu, and survives a relaunch.

## Apps

- [ ] Settings → Automation → Apps: add an app, open it → Keep Awake on; quit it → off.
- [ ] Turn Keep Awake on yourself, open and quit the app → Keep Awake stays on.

## Mouse jiggler

- [ ] Settings → Automation → Chat apps: switch on. ⚠︎ row shows; Open Accessibility Settings lists
      Lisdex; allow it → the row turns ✅ within a few seconds.
- [ ] Keep Awake on, leave the Mac alone for 6 minutes: Teams/Slack stay Available, the cursor
      doesn't move. `log stream --predicate 'subsystem == "io.github.pedrol2b.lisdex" AND
      category == "jiggler"'` shows jiggles after 1 min, then every 20 s.
- [ ] Touch the mouse: jiggles stop until you've been idle again. Caps Lock on doesn't block them.
- [ ] Display asleep or screen locked: no jiggles (the display stays asleep).
- [ ] Full-screen video while jiggling: no cursor or playback controls appear.
- [ ] Remove Lisdex from Accessibility: the menu shows "Mouse jiggler needs permission".

## Shortcuts and Focus (signed build only)

- [ ] Shortcuts: Turn Keep Awake On (with and without minutes), Turn Off, Is Keep Awake On?
- [ ] System Settings → Focus → a Focus → Focus filters → Lisdex "Keep Mac awake" on. Turn the
      Focus on → Keep Awake on ("While a Focus is on."); off → Keep Awake off.

