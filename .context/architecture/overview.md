# Architecture overview (planned)

_Last updated 2026-11-19. **Implemented (Phases 1–2):** Core — `KeepAwakeState` / `KeepAwakeMode`, `MenuBarIcon` / `MenuBarIconVariant`, `KeepAwakeEngine`, `AppSettings`, `PreferencesStore`, `PowerRequest`, `PowerCoordinator` + `PowerHold`. App — `main`, `AppDelegate`, `AppModel` (loads/saves settings, drives `PowerCoordinator`), `Power/{IOKitAssertion,CaffeinateProcess}`, `StatusItemController`, `MenuBarImages`, `AboutPanel`, `Log`, `Views/{MenuView,ModePicker,Rows,Theme}`. Phase 3 adds Core `Schedule`, `Session`, `SessionPlanner`, `SessionStatus` and App `Power/SessionClock`, `Views/{DurationPanel,ScheduleCard}` (ADR 0013). Still the target: `LoginItemService`, Settings window._

Implemented power path: UI / right-click → an `AppModel` intent → `reconcile()` → save `settings.v1` if changed → `SessionPlanner.plan` → `PowerRequest(plan:settings:)` → `PowerCoordinator.apply` (+ `SessionClock` armed at `plan.nextCheck`) → `IOKitAssertion` or `CaffeinateProcess` (new hold first, then release the old one).

```
Package.swift
├── LisdexCore        (library, Foundation only — fully unit-tested)
│   ├── KeepAwakeMode.swift     .indefinitely | .duration(TimeInterval) | .schedule
│   ├── Schedule.swift          Weekday set + TimeWindow, validation, next transition
│   ├── SessionPlanner.swift    pure: (settings, isEnabled, startedAt, now) → Plan(holdAwake, until, nextCheck)
│   └── AppSettings.swift       settings + PreferencesStore (UserDefaults JSON "settings.v1")
├── Lisdex            (executable — AppKit + SwiftUI shell)
│   ├── main.swift / AppDelegate.swift      accessory app bootstrap
│   ├── AppModel.swift                      @Observable @MainActor single source of truth
│   ├── StatusItemController.swift          NSStatusItem, left/right click, template icon variant
│   ├── Services/PowerAssertionService.swift  IOKit assertions (ADR 0002), KeepAwakeBackend protocol
│   ├── Services/SessionClock.swift         timer + NSWorkspace wake / clock-change observers → re-plan
│   ├── Services/LoginItemService.swift     SMAppService.mainApp
│   └── Views/                              MenuView, ModePicker, DurationChips, ScheduleCard, Settings, About
└── LisdexCoreTests   (Swift Testing)
```

Data flow: UI / right-click → `AppModel.apply(change)` → persist → `SessionPlanner.plan(...)` → `PowerAssertionService.set(holdAwake:, display:)` + schedule the next re-plan at `plan.nextCheck`.
