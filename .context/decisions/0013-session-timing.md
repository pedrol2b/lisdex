# 0013 — Session timing: pure planner, wall-clock deadlines, inline schedule editing

- **Status:** Accepted (implemented Phase 3, 2026-11-19)
- **Date:** 2026-11-19

## Context

Phase 3 adds "For a Duration" and "On a Schedule". Acceptance 3–4: a duration must end within 1 s of its deadline and survive sleep/wake; a schedule must start and stop on time, including across sleep, clock and time-zone changes.

## Decision

- **Pure planner in Core.** `SessionPlanner.plan(session:mode:schedule:now:calendar:)` returns `SessionPlan` (`.off`, `.holding(until:)`, `.waiting(next:)`, `.expired`) with a `nextCheck`. `SessionStatus` turns a plan into the header's pill, detail line and progress. Both are tested with a fixed UTC/en_GB calendar.
- **Wall-clock deadlines.** `Session.start` stores `deadline = now + duration` as a `Date`. Nothing counts down, so time spent asleep counts (the spec's choice).
- **One timer plus observers.** `SessionClock` arms a single `Timer` (0.2 s tolerance) at `plan.nextCheck`, and also re-plans on `NSWorkspace.didWakeNotification`, `NSSystemClockDidChange`, `NSSystemTimeZoneDidChange` and `NSCalendarDayChanged`, because timers don't fire while the Mac sleeps. No polling.
- **Schedule model (v1):** one window shared by the selected days; `end < start` runs overnight and belongs to the day it starts on; start inclusive, end exclusive; no days or `start == end` never holds (shown as "Pick at least one day."). Persisted in `settings.v1` as `{days:[Calendar weekday numbers], start, end}` with minutes since midnight. Invalid values fall back to weekdays 09:00–18:00.
- **Inline editing.** The schedule card in the popover is the editor: tap day pills, edit start/end with stepper fields. The spec's separate "Edit" button and Settings → Schedule tab are deferred to per-day windows (v1.1).
- **Behaviour details.** Right-click in Duration restarts the last chosen duration. A chip (or Custom → Start) remembers the length and (re)starts the timer. Changing mode while on starts a fresh session. On expiry Keep Awake switches off and the mode stays Duration. A running session is not persisted (Lisdex launches inactive, ADR 0006).
- The status icon is filled only while the plan holds; a schedule waiting outside its window shows the inactive icon (spec v1).

## Consequences

- All timing logic is unit-tested without waiting on real time; the app layer only wires timers and notifications.
- The "notify when a timed session ends" option arrives with the Settings window (Phase 4).

## Alternatives considered

- A repeating 30 s tick (roadmap draft): simpler, but wakes the CPU constantly and misses the 1 s expiry target.
- Monotonic countdown: pauses during sleep, so a 1 h session could last much longer in wall-clock time.
