# Per-day Schedule Hours Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each schedule day has its own hours, edited in a new Settings → Schedule tab, while the popover card stays as it is for people whose days all share the same hours.

**Architecture:** `Schedule` (LisdexCore) keeps `days` plus a `DayHours` for every weekday; window evaluation reads the hours of the day a window starts on. Decoding migrates the v1.1 `days/start/end` shape and keeps writing it for downgrades. The app layer adds a Settings tab, lets the Settings window switch tab when already open, and gives the popover card a summary + "Edit Hours…" mode when hours differ.

**Tech Stack:** Swift 6 SwiftPM, Foundation-only LisdexCore with Swift Testing; SwiftUI/AppKit app layer.

**Spec:** `.context/specs/per-day-schedule.md`

## Global Constraints

- Decision logic in `Sources/LisdexCore` (Foundation only) with tests; `Sources/Lisdex` is UI/I/O.
- Must compile with Swift 6.3: bind controls with `Bindable(model).x`, never `Binding(get:set: model.method)`. (Closure-based `Binding(get:set:)` like the existing `ScheduleCard.timePicker` is fine.)
- Value types, return new values; no `print` — use `Log`.
- Storage stays `settings.v1`; a v1.1 schedule must load with the same behaviour; old `start`/`end` keep being written (from the first day that's on, Monday first; Monday's if none).
- Copy: tab "Schedule" (`calendar` symbol, after Power); popover button "Edit Hours…"; summary `Mon–Thu 09:00–18:00 · Fri 09:00–14:00` (times in the user's clock format, en dash between days and between times, ` · ` between groups).
- Don't push. Branch `feat/per-day-schedule`, merge locally when the owner says so.

## Review Focus

1. Overnight window on a day whose hours differ from the next day's (Fri 22:00–06:00, Sat 10:00–12:00): Saturday 02:00 belongs to Friday's window; Saturday 10:00 opens Saturday's. → test in Task 1.
2. A v1.1 settings blob with `start`/`end` and no per-day hours → every day gets those hours; behaviour identical. → test in Task 2.
3. One corrupt per-day entry → only that day falls back; the rest are kept. → test in Task 2.
4. Days switched off don't break `sharedHours` (Sat at 10–12 while off, all on-days 09–18 → shared 09–18). → test in Task 1.
5. Settings already open on another tab, popover "Edit Hours…" → the window switches to Schedule. → manual check in Task 4.

---

### Task 1: Per-day hours in `Schedule`

**Files:**
- Modify: `Sources/LisdexCore/Schedule.swift`
- Modify: `Sources/Lisdex/Views/ScheduleCard.swift` (keep compiling: edit `sharedHours ?? hours(for: .monday)` via `withAllHours`)
- Test: `Tests/LisdexCoreTests/ScheduleTests.swift` (existing tests move from `.start/.end` to `hours(for:)`)

**Interfaces:**
- Produces:
  - `public struct DayHours: Codable, Hashable, Sendable { let start: TimeOfDay; let end: TimeOfDay; init(start:end:); static let workday /* 09:00–18:00 */; var isOvernight: Bool /* end < start */ }`
  - `Schedule.init(days: Set<Weekday>, hours: [Weekday: DayHours], fallback: DayHours = .workday)` — missing days get `fallback`.
  - `Schedule.init(days: Set<Weekday>, start: TimeOfDay, end: TimeOfDay)` — every day the same (kept for tests and migration).
  - `func hours(for day: Weekday) -> DayHours`
  - `func with(hours: DayHours, for day: Weekday) -> Schedule`
  - `func withAllHours(_ hours: DayHours) -> Schedule`
  - `var sharedHours: DayHours?` — on days all equal → those; no day on → all seven equal → those; else `nil`.
  - `toggling(_:)`, `window(containing:calendar:)`, `nextStart(after:calendar:)` unchanged signatures. Remove `start`, `end`, `with(start:end:)`.

- [ ] **Step 1: Write the failing tests** in `ScheduleTests`:
  - `perDayWindow`: `Schedule.default.with(hours: DayHours(start: 9:00, end: 14:00), for: .friday)` → window at 2026-11-20 10:00 is 09:00–14:00; at 2026-11-20 15:00 nil; `nextStart(after: 2026-11-20 15:00)` == 2026-11-23 09:00; Monday 2026-11-16 17:00 still inside 09:00–18:00.
  - `overnightUsesStartDayHours`: days [.friday, .saturday], Fri 22:00–06:00, Sat 10:00–12:00 → 2026-11-21 02:00 in Fri window (2026-11-20 22:00 – 2026-11-21 06:00); 2026-11-21 08:00 nil; 2026-11-21 10:30 in 10:00–12:00.
  - `offDayKeepsHours`: set Saturday 10–12, toggle Saturday on then off then on → `hours(for: .saturday)` == 10–12.
  - `sharedHours`: default → `.workday`; Friday 09–14 → nil; Saturday (off) 10–12 with on-days 09–18 → `.workday`; `days: []` with all seven equal → that value; `days: []` with one different → nil.
  - `withAllHours`: sets all seven, including days that are off.
- [ ] **Step 2: Run** `swift test --filter ScheduleTests` → Expected: compile FAIL (`DayHours` not found).
- [ ] **Step 3: Implement** in `Schedule.swift`; store hours as `[Weekday: DayHours]` holding all seven; `window(startingOn:)` reads `hours(for: weekday)`. Update `ScheduleCard` time pickers to read `schedule.sharedHours ?? schedule.hours(for: .monday)` and write `withAllHours` (temporary until Task 4). Update the existing tests that used `.start`/`.end`.
- [ ] **Step 4: Run** `make test` → Expected: all pass. `swift build` clean.
- [ ] **Step 5: Commit** `feat: schedule keeps hours for each day`

### Task 2: Storage and migration

**Files:**
- Modify: `Sources/LisdexCore/Schedule.swift` (custom `Codable`)
- Test: `Tests/LisdexCoreTests/ScheduleCodingTests.swift` (new)

**Interfaces:**
- Consumes: Task 1's `Schedule`, `DayHours`.
- Produces: JSON `{"days":[Int], "start":Int, "end":Int, "hours":{"<weekday raw>":{"start":Int,"end":Int}}}`. Decode: `days` required; legacy = `DayHours(start,end)` if both decode; per day: valid `hours[raw]` → it, else legacy, else `.workday`. Neither legacy nor any valid per-day entry → throw (so `AppSettings` falls back to `.default`, keeping `invalidScheduleAndDuration` green).

- [ ] **Step 1: Write the failing tests:**
  - `roundTrip`: a schedule with Friday 09–14 encodes and decodes equal.
  - `legacyShape`: `{"days":[2,6],"start":600,"end":960}` → days [.monday, .friday], every day 10:00–16:00.
  - `writesLegacyFields`: Friday-only schedule at 09–14 (Monday 09–18) encodes `start` 540 / `end` 840; days `[]` encodes Monday's hours.
  - `badDayFallsBack`: `{"days":[2,6],"start":540,"end":1080,"hours":{"6":{"start":-1,"end":840},"2":{"start":600,"end":700}}}` → Friday 09–18, Monday 10:00–11:40.
  - `hoursWithoutLegacy`: `{"days":[2],"hours":{"2":{"start":600,"end":700}}}` → Monday 10:00–11:40, other days `.workday`.
- [ ] **Step 2: Run** `swift test --filter ScheduleCodingTests` → Expected: FAIL (synthesized Codable ignores `hours`).
- [ ] **Step 3: Implement** `init(from:)` / `encode(to:)` with a private lossy wrapper (`try? DayHours(from:)`) for each per-day entry.
- [ ] **Step 4: Run** `make test` → Expected: all pass (incl. `AppSettingsTests`).
- [ ] **Step 5: Commit** `feat: per-day schedule hours migrate from v1.1 settings`

### Task 3: Summary text

**Files:**
- Create: `Sources/LisdexCore/ClockText.swift` (move `ClockText` out of `SessionStatus.swift`, make it `internal`, add `func time(_ time: TimeOfDay) -> String`)
- Create: `Sources/LisdexCore/ScheduleSummary.swift`
- Test: `Tests/LisdexCoreTests/ScheduleSummaryTests.swift` (new)

**Interfaces:**
- Produces: `extension Schedule { public func summary(calendar: Calendar) -> String }` — on days in `Weekday.displayOrder`, consecutive (in that order) days with equal hours form a group; group label `Mon` or `Mon–Thu` (`calendar.shortWeekdaySymbols`); text `"<label> <start>–<end>"`; groups joined by `" · "`; no day on → `"No days"`.

- [ ] **Step 1: Write the failing tests** (TestClock calendar, en_GB 24 h):
  - default → `"Mon–Fri 09:00–18:00"`
  - Friday 09–14 → `"Mon–Thu 09:00–18:00 · Fri 09:00–14:00"`
  - days Mon, Wed same hours → `"Mon 09:00–18:00 · Wed 09:00–18:00"` (a gap breaks the group)
  - Sat + Sun on, same hours → `"Sat–Sun 09:00–18:00"`
  - no days → `"No days"`
- [ ] **Step 2: Run** `swift test --filter ScheduleSummaryTests` → Expected: compile FAIL.
- [ ] **Step 3: Implement.** `ClockText.time(TimeOfDay)` formats a date at that hour/minute with template `jmm`.
- [ ] **Step 4: Run** `make test` → Expected: all pass (SessionStatus tests unchanged).
- [ ] **Step 5: Commit** `feat: schedule summary text`

### Task 4: Settings → Schedule tab and popover card

**Files:**
- Create: `Sources/Lisdex/Settings/ScheduleSettingsView.swift`
- Create: `Sources/Lisdex/Views/TimeField.swift` (the stepper-field time picker extracted from `ScheduleCard`, shared by both views)
- Modify: `Sources/Lisdex/Settings/SettingsView.swift` (`SettingsTab.schedule`, tab after Power, selection driven by a `SettingsNavigation`)
- Modify: `Sources/Lisdex/Settings/SettingsWindowController.swift` (`@Observable final class SettingsNavigation { var tab }`; `show(tab:)` sets it even when the window exists)
- Modify: `Sources/Lisdex/Views/ScheduleCard.swift`, `Sources/Lisdex/Views/MenuView.swift`, `Sources/Lisdex/StatusItemController.swift`, `Sources/Lisdex/AppDelegate.swift` (`openSettings: (SettingsTab) -> Void`)

**Interfaces:**
- Consumes: Tasks 1–3 (`hours(for:)`, `with(hours:for:)`, `withAllHours`, `sharedHours`, `summary(calendar:)`, `DayHours.isOvernight`); `AppModel.setSchedule(_:)`.
- Produces: `SettingsWindowController.show(tab:)` switches tab on an open window.

- [ ] **Step 1: Schedule tab** — grouped `Form`; one row per day in `Weekday.displayOrder`: `Toggle(fullWeekdayName)` (toggles via `toggling`), From/To `TimeField`s (disabled when the day is off), "overnight" caption when `isOvernight`. Section footer: "A window that ends before it starts runs overnight." (leading-aligned, as in the Apps tab).
- [ ] **Step 2: Tab switching** — `SettingsNavigation` owned by the controller, passed to `SettingsView`; `TabView(selection: Bindable(navigation).tab)`.
- [ ] **Step 3: Popover card** — `if let shared = schedule.sharedHours` → today's From/To (writing `withAllHours`); else → `Text(schedule.summary(calendar: .current))` (caption, secondary, may wrap) + `Button("Edit Hours…") { openSettings(.schedule) }` (`.link` style). `ScheduleCard` gains `editHours: () -> Void`.
- [ ] **Step 4: Verify** `make test`, `make lint`, `make app`; relaunch (`pkill -x Lisdex; open build/Lisdex.app`); in the app: set Friday 09–14 in the tab → popover shows summary + button; button with Settings open on Apps switches to Schedule; set all days back equal → popover shows From/To again; switch a day off/on keeps its hours; `pmset -g assertions` holds inside a window. Screenshots to `.context/evidence/2026-11-23-per-day-schedule/`.
- [ ] **Step 5: Commit** `feat: Settings → Schedule tab with hours for each day`

### Task 5: Records

**Files:** `.context/decisions/0021-per-day-schedule.md`, `.context/specs/lisdex-v1.md` (schedule card + Settings tabs), `.context/specs/per-day-schedule.md` (mark approved), `CHANGELOG.md` [Unreleased] Added, `.context/status/current.md` (Done + roadmap row), evidence README.

- [ ] **Step 1:** Write the records. **Step 2:** `make test` → pass. **Step 3: Commit** `docs: per-day schedule ADR, spec and status`
