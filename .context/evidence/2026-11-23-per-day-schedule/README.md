# Per-day schedule hours — verification (2026-11-23)

Build `build/Lisdex.app` from `feat/per-day-schedule`, dark mode, main display. Settings restored afterwards.

| Check | Result | Screenshot |
| --- | --- | --- |
| v1.1 `{"days":[2..6],"start":600,"end":960}` loads as Mon–Fri 10:00–16:00, popover edits inline | ✅ | `popover-migrated-v1.1.png` |
| Settings → Schedule shows seven rows; days off greyed with their hours | ✅ | `settings-schedule-dark.png` |
| Friday end set to 2 PM in the tab → stored `hours["6"].end = 840`, `start/end` stay 600/960 | ✅ | — |
| Hours differ → popover shows `Mon–Thu 10:00 AM–4:00 PM · Fri 10:00 AM–2:00 PM` + Edit Hours… | ✅ | `popover-different-hours.png` |
| Settings open on Apps → Edit Hours… switches the open window to Schedule and brings it forward | ✅ (AX: Schedule radio = 1, Apps = 0) | — |
| Friday back to 4 PM → popover returns to From–To | ✅ | — |
| Monday 16:00–21:00, other days 10–16, at Mon 17:20 → `pmset` shows "Lisdex: On a Schedule"; header "Until 9:00 PM · next: Tue 10:00 AM" | ✅ | `popover-holding-monday-evening.png` |

Tests: `swift test` → 119 tests in 21 suites passed (ScheduleTests, ScheduleCodingTests, ScheduleSummaryTests new/extended).
