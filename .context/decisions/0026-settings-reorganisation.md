# ADR 0026 — Settings reorganised: five tabs, one row pattern

- **Status:** Accepted (owner approved the mockups and tested the build, 2026-11-25)
- **Date:** 2026-11-25

## Context

Settings had grown one tab per feature (General, Power, Schedule, Appearance, Shortcuts, Apps).
The owner found it unorganised: explanations were done three ways (section footer, caption row,
none), capitalisation was mixed, some settings sat in the wrong group (notification apart from the
sound, the click behaviour apart from the icon, the jiggler under Power), the schedule repeated a
switch and two time fields seven times, the mode-badge caption mixed a symbol with words, and the
spec's "custom" accent was never built. The owner doesn't use different hours per day.

Options weighed in the browser mockups (`.superpowers/brainstorm/`, not committed):

- Schedule: **A.** day pills + one shared From–To + "Different hours per day" (picked) vs
  **B.** a summary row with an Edit… sheet (one extra click for every change).
- Jiggler: **Automation** (picked; it acts on its own while you're idle, like the schedule and app
  triggers) vs General (would be the heaviest group there).
- Build: native SwiftUI `Form(.grouped)` (picked) vs custom-drawn rows like the popover (more code,
  loses native keyboard/VoiceOver) vs a sidebar window (built for dozens of panes).

## Decision

- Tabs: **General · Appearance · Power · Automation · Shortcuts**. Schedule, Apps and Chat apps
  are sections of Automation; "Edit Hours…" in the popover opens Automation. Spec `lisdex-v1.md`
  "Settings window" lists every row.
- Row rules: every group has a heading; sentence case (`ShortcutAction.title`,
  `StatusItemClickBehavior.title` and the engine title changed to match); an explanation is the
  label's second `Text` (the grey line macOS draws under the row), only where the effect isn't
  obvious; `SectionFooter` only for group-wide notes; no inline symbols. The ADR 0002 caffeinate
  warning keeps its exact text.
- Schedule: "Different hours per day" is not stored. It shows on when the days that are on have
  different hours, or when the user turned it on this session. Turning it off calls
  `Schedule.unifyingHours()`: every day gets the hours of the first day that's on (Monday first),
  the same day the v1.1 `start`/`end` come from. Only days that are on are listed.
- Accent: `AppSettings.accent` is now `Accent` (`.preset(AccentChoice)` or `.custom(rgb:)`),
  stored as one string — a preset's name, as before, or `#RRGGBB`. An older Lisdex can't read
  `#RRGGBB` and falls back to gold (ADR 0006). The custom swatch opens `NSColorPanel` beside the
  Settings window (it opened in the screen corner and looked broken).
- `WeekdayPills` is shared by the popover card and Settings.

## Consequences

- No settings migration; v1.3 settings load unchanged.
- `-LisdexScreenshot` targets are now `general|appearance|power|automation|shortcuts`;
  `scripts/screenshots.sh` takes one `settings-automation` shot instead of schedule + apps.
- Shortcut conflict messages use the new action names ("Already used for Start indefinitely.").
