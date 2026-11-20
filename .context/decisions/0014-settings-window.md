# 0014 — Settings window, Start on Login, notifications, battery rules, accents

- **Status:** Accepted (implemented Phase 4, 2026-11-20)
- **Date:** 2026-11-20

## Decision

- **Window.** An AppKit `NSWindow` hosting SwiftUI (`Settings/SettingsWindowController.swift`, `SettingsView.swift`), opened from the popover's "Settings…" row (⌘,). Lisdex has no SwiftUI `App`/`Settings` scene (ADR 0001), and an accessory app has to activate itself to bring the window forward. Tabs: General · Power · Appearance. The spec's Schedule tab is not needed in v1 because the popover card edits the schedule (ADR 0013).
- **Start on Login** uses `SMAppService.mainApp`. The state is read back from macOS each time the popover or Settings opens, never stored (ADR 0006). `requiresApproval` shows "Waiting for your approval" plus a button that opens Login Items.
- **Activate Keep Awake when Lisdex launches** (default off) is applied by `AppModel.start()` after launch. The on/off switch itself is still not persisted.
- **Notifications** (`UNUserNotificationCenter`) ask for permission the first time one is needed. They are sent when a duration ends (if "Notify when a timed session ends" is on, the default) and when the battery cutoff stops Keep Awake (always). If permission is declined, the skip is logged and nothing else happens.
- **Battery rules** live in Core and are tested:
  - `BatteryCutoff`: on battery at or below 10 % / 20 % → Keep Awake off. Turning it back on while still under the limit switches it straight off again.
  - "Allow display sleep on battery": on battery, only the system assertion is held.
  - `PowerSourceMonitor` (IOKit `IOPSNotificationCreateRunLoopSource`) re-plans on every power-source change; there is no polling.
- **Accent colours** are presets only: gold (default), orange, pink, purple, blue, mint, stored by name. The spec's "custom" colour is dropped until someone asks for it (YAGNI). Views read the accent from the SwiftUI environment (`\.accent`), so a change applies immediately everywhere.
- **Icon variant** is chosen from two preview cards that show both states (Compact / Full molecule) and applies to the status item immediately.
- The `caffeinate` warning text from ADR 0002 is shown under the engine picker while `caffeinate` is selected.

## Consequences

- Notifications from an ad-hoc-signed local build depend on macOS accepting the app; failures only log.
- Start on Login points at wherever this `Lisdex.app` lives. Moving the app (e.g. `build/` → `~/Applications`) requires toggling it again.
