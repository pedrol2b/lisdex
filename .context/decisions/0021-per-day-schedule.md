# ADR 0021 — Per-day schedule hours

- **Status:** Accepted (owner approved the design 2026-11-23)
- **Date:** 2026-11-23

## Context

Phase 8.2: "On a Schedule" had one window shared by every selected day. The owner wants
different hours on some days (e.g. a short Friday); one window per day for now, several later
if needed. Where to edit was the main choice:

- **A.** A week editor in a new Settings → Schedule tab; the popover card stays small.
- **B.** Tapping a day in the popover selects it for editing — a day button with two meanings.
- **C.** Seven rows in the popover — about 200 pt taller.

## Decision

Approach A (owner, 2026-11-23).

- `Schedule` keeps `days` plus a `DayHours` for **all seven** days; a day switched off keeps its
  hours. A window belongs to the day it starts on and uses that day's hours (overnight included).
  Windows that overlap or touch (e.g. Fri 22:00–06:00 and Sat 02:00–12:00) hold as one, so the
  status line shows the real end.
- `sharedHours` is non-nil when every day that's on has the same hours. Then the popover card
  edits inline and writes the hours to the days that are on plus any day that's off still at
  the same hours (a day that's off with its own hours keeps them); otherwise it shows `summary(calendar:)`
  and "Edit Hours…", which opens (or switches an open) Settings window to the Schedule tab.
- Storage stays in `settings.v1.schedule`: per-day `hours` keyed by weekday number, plus the
  v1.1 `start`/`end` (from the first day that's on) so a downgrade keeps a sensible schedule.
  A missing or invalid per-day entry falls back to the v1.1 hours, else 09:00–18:00.

## Consequences

- v1.1 schedules load unchanged in behaviour; no migration step or version bump.
- The JSON shape (`hours` as a map) leaves room for several windows per day later, e.g. a map
  of arrays, with the same fallback rules.
- The popover can't edit a single day's hours; that is the Settings tab's job.
