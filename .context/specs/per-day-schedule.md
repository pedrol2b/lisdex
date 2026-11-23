# Per-day schedule hours — Phase 8.2

_Approved by owner 2026-11-23 (Approach A)._

## Intent

"On a Schedule" today uses one window shared by every selected day. The owner wants each day to have its own hours, e.g. Mon–Thu 09:00–18:00 and Fri 09:00–14:00. One window per day for now; several windows in a day may come later, so the storage format shouldn't rule that out.

## Goals / non-goals / anti-goals

- Goals: each selected day has its own start and end; a v1.1 schedule carries over unchanged in behaviour; people who never want different hours notice no difference in the popover.
- Non-goals: several windows per day; dates, holidays or exceptions; a calendar view.
- Anti-goals: the popover growing taller; losing a saved schedule on upgrade; a day button that sometimes means "switch this day" and sometimes "pick this day to edit".

## Approaches

- **A. Week editor in a new Settings → Schedule tab; the popover card stays small (picked by owner).**
- B. Everything in the popover card: tapping a day selects it for editing. Rejected: a day button with two meanings makes it easy to switch a day off by accident.
- C. Seven rows inside the popover. Rejected: the popover grows by about 200 pt.

## Design

**Core (Foundation only, tested)**
- `DayHours(start: TimeOfDay, end: TimeOfDay)` — one day's window; end before start runs overnight and belongs to the day it starts on (unchanged rule); start == end never holds.
- `Schedule` keeps `days: Set<Weekday>` (which days are on) and gains hours for **all seven days**, so a day switched off remembers its hours and gets them back when switched on.
- `Schedule.hours(for: Weekday) -> DayHours`; `with(hours:for:)` sets one day; `withAllHours(_:)` sets every day.
- `Schedule.sharedHours: DayHours?` — the hours if every day that's on has the same hours (with no day on: if all seven match), else `nil`.
- `window(containing:)` / `nextStart(after:)` use each day's own hours; the overnight check against yesterday uses yesterday's hours.
- Summary text for the popover: consecutive days with the same hours are grouped, Monday first — `Mon–Thu 09:00–18:00 · Fri 09:00–14:00`; times in the user's clock format as the status line uses.
- Storage (`settings.v1` → `schedule`): new per-day hours field; the old `start`/`end` are still written (from the first day that's on) so a downgrade to v1.1 keeps a sensible schedule. Decoding: per-day hours present → use them; missing → every day gets the old `start`/`end`; a bad per-day entry → that day falls back to the old `start`/`end` (else 09:00–18:00).

**Popover card**
- Same hours on every day that's on → the card looks and works exactly as today; changing From/To sets the days that are on plus any day that's off still at the same hours, so switching a day on later never brings back an odd hour, while a day that's off with its own hours keeps them (review fix 2026-11-23).
- Different hours → day buttons stay; in place of From/To the card shows the summary and an **Edit Hours…** button that opens Settings on the Schedule tab.

**Settings → Schedule tab** (`calendar` symbol, after Power)
```
  ☑ Monday     [09:00] – [18:00]
  ☑ Tuesday    [09:00] – [18:00]
  …
  ☑ Friday     [09:00] – [14:00]  overnight?
  ☐ Saturday   [09:00] – [18:00]   (greyed)
  ☐ Sunday     [09:00] – [18:00]   (greyed)
```
- One row per day, Monday first: a checkbox (same as the day button) and From/To time fields; "overnight" caption when end < start; the time fields of a day that's off are greyed out but keep its hours.
- Footer: one line explaining that a window ending before it starts runs overnight.
- The window must be able to switch to this tab when it's already open (today the tab only applies when the window is first created).

**Records**
- ADR 0021 (per-day hours; storage and migration).
- `lisdex-v1.md`: Schedule card behaviour and the Settings tab list.
- CHANGELOG [Unreleased] → Added.

## Calls (mine — check these)

- Hours are kept for all seven days, so switching a day off and on restores its hours. (Replaces my earlier "a day switched on copies the first day's hours" — simpler and loses nothing.)
- Editing From/To in the popover sets the days that are on and the off days that shared their hours; an off day with its own hours keeps them. (Revised after review: the first call, "every day", silently overwrote customised days.)
- The Schedule tab is always visible, whatever the current mode.

## Rollout

Branch `feat/per-day-schedule`; owner tests in `build/Lisdex.app`; merge locally, no push until Phases 8–9 are done. Ships in v1.2.

## Left to the builder

File split, exact field names in the JSON, row visuals (match the grouped Form style), how the window learns to switch tab.
