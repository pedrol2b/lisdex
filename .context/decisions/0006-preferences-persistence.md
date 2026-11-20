# 0006 — Preferences: one Codable `AppSettings` as JSON in UserDefaults (Low Cortisol pattern)

- **Status:** Accepted (owner, 2026-11-19)
- **Date:** 2026-11-19

## Context

Owner wants preferences saved the same way as Low Cortisol (`Sources/LowCortisolCore/AppSettings.swift` there).

## Decision

- `LisdexCore/AppSettings.swift`: a single `public struct AppSettings: Codable, Equatable, Sendable` with a `static let default`. Holds: `isKeepAwakeOn`, `mode`, `lastDuration`, `schedule`, `engine` (ADR 0002), `keepDisplayAwake`, `allowDisplaySleepOnBattery`, `batteryStopThreshold`, `iconVariant` (ADR 0003), `accent`, `activateOnLaunch`, `notifyOnSessionEnd`, `durationDeadline` (wall-clock, so a timed session can resume after relaunch if still in the future).
- Custom `init(from:)` uses `decodeIfPresent(...) ?? fallback.<field>` for every key, so new fields never break old data; enum fields use `try?` so an unknown case falls back instead of failing.
- `PreferencesStore` (`UserDefaults`, injectable for tests) saves JSON under **`settings.v1`**; `loadSettings()` returns `(settings, error)`. Corrupt data → defaults + logged error, never a crash.
- Settings are changed by creating a new value (`settings.with(mode:engine:...)`, `let` fields) and saved by `AppModel` on every change. They are never mutated in place across layers.
- Start on Login is **not** stored. Its truth is `SMAppService.mainApp.status`.

## Implementation notes (Phase 2, 2026-11-19)

- Phase 2 ships the fields it uses: `mode`, `engine`, `keepDisplayAwake`, `iconVariant`. The rest arrive with their phases; tolerant decoding makes each addition backwards compatible.
- `isKeepAwakeOn` is **not** stored: Lisdex always launches inactive, and the spec's separate "Activate Keep Awake when Lisdex launches" setting (Phase 4) decides otherwise. This avoids silently holding the Mac awake after a crash or reboot.
- Code: `Sources/LisdexCore/AppSettings.swift`, `Sources/LisdexCore/PreferencesStore.swift`; tests in `Tests/LisdexCoreTests/{AppSettings,PreferencesStore}Tests.swift`.

## Consequences

- Tests cover round-trip, missing keys, unknown enum values and corrupt data.
- A breaking schema change means a new key (`settings.v2`) plus a migration from v1.

## Alternatives considered

- `@AppStorage` per key — scatters persistence through views, harder to test and migrate.
