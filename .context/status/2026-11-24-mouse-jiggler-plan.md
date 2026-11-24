# Mouse Jiggler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** While Keep Awake holds and the user has turned the jiggler on, Lisdex posts a 0 px mouse-moved event after the user has been idle for the idle time, every interval, so Teams/Slack keep showing them as available.

**Architecture:** `JigglerSettings` (stored in `AppSettings`) and `JigglerClock` (pure decision: jiggle now / check again at) live in LisdexCore with tests. The app layer's `Jiggler` owns one timer, reads CoreGraphics idle time and held keys/buttons, and posts the event; `AppModel.reconcile` starts/stops it. Settings → Power gains a "Chat apps" section; the popover shows one warning line when the permission is missing.

**Tech Stack:** Swift 6 SwiftPM; Foundation-only LisdexCore with Swift Testing; AppKit/SwiftUI + CoreGraphics (`CGEventSource`, `CGEvent`, `CGPreflightPostEventAccess`) in the app.

**Spec:** `.context/specs/mouse-jiggler.md`

## Global Constraints

- Decision logic in `Sources/LisdexCore` (Foundation only) with tests; CoreGraphics only in `Sources/Lisdex`.
- Swift 6.3 compatible: bind controls with `Bindable(model).x` (add properties to `AppModel+Bindings.swift`); never `Binding(get:set: model.method)`. No `@Entry`. No `print` — `Log`.
- Defaults: off, idle threshold 60 s, interval 20 s. Ranges: threshold 30…240 s step 30; interval 10…60 s step 5. Stored under `jiggler` in `settings.v1`; a missing or bad value falls back to defaults without losing other settings.
- Runs only when: enabled ∧ plan holds awake ∧ permission granted. Never while off or waiting outside a schedule window.
- Event: `.mouseMoved` at the current cursor location, posted at `.cghidEventTap` (0 px).
- Copy (exact): section "Chat apps"; switch "Keep me active in chat apps (mouse jiggler)"; ✅ "Lisdex can keep you active."; ⚠︎ "Lisdex needs Accessibility permission."; button "Open Accessibility Settings"; footnote "After updating Lisdex, macOS may keep showing it as allowed while it isn't: switch Lisdex off and on there."; popover line "Mouse jiggler needs permission".
- Pane URL: `x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility`.
- Branch `feat/mouse-jiggler`; don't push.

## Calls made in this plan (beyond the spec)

- The section caption also says "While it runs, the screen saver and display sleep wait too." — a posted mouse event counts as activity for them as well; the user should know.
- No jiggle while the screen is locked (`CGSessionCopyCurrentDictionary()["CGSSessionScreenIsLocked"]`): locking is a deliberate "I'm away", and a posted event would wake the lock screen's display.
- The permission row re-checks every 2 s while it shows ⚠︎ and the Settings window is open, so granting it in System Settings flips the row without reopening.
- Next check is never sooner than 1 s after now (no tight loop if the timer fires early).

## Review Focus

1. The user's real input arrives between two jiggles (idle reading far from Lisdex's last jiggle) → jiggling stops and the idle wait restarts from that input. → `JigglerClockTests.realInputRestartsWait` (Task 2).
2. Lisdex's own jiggle seen as the latest event (idle reading ≈ now − lastJiggle) must not count as user input, or jiggling would continue forever / stop wrongly. → `ownJiggleIsNotUserInput` (Task 2).
3. A held key or mouse button (drag, long key press) with a stale idle reading → no jiggle. → `heldInputBlocksJiggle` (Task 2).
4. Timer firing slightly early (idle 59.8 s, threshold 60) → reschedules, no jiggle, no tight loop. → `earlyFireReschedules` (Task 2).
5. Corrupt `jiggler` value (`"interval": "x"`, threshold 9999) → defaults / clamped, other settings kept. → `JigglerSettingsTests` (Task 1).

---

### Task 1: `JigglerSettings` in `AppSettings`

**Files:**
- Create: `Sources/LisdexCore/JigglerSettings.swift`
- Modify: `Sources/LisdexCore/AppSettings.swift` (field `jiggler`, init param, decode with `try?` fallback, `with(jiggler:)`)
- Test: `Tests/LisdexCoreTests/JigglerSettingsTests.swift`, `Tests/LisdexCoreTests/AppSettingsTests.swift`

**Interfaces:**
- Produces:
  - `public struct JigglerSettings: Codable, Equatable, Sendable { isEnabled: Bool; idleThreshold: TimeInterval; interval: TimeInterval }`
  - `static let default` (false, 60, 20); `static let idleThresholdRange: ClosedRange<TimeInterval> = 30...240`, `idleThresholdStep = 30`, `intervalRange = 10...60`, `intervalStep = 5`.
  - `init(isEnabled: Bool = false, idleThreshold: TimeInterval = 60, interval: TimeInterval = 20)` — non-finite → default, else clamped to the range.
  - `func with(isEnabled: Bool? = nil, idleThreshold: TimeInterval? = nil, interval: TimeInterval? = nil) -> JigglerSettings`
  - Tolerant `init(from:)`: each key independently, bad/missing → default.
  - `static func label(seconds: TimeInterval) -> String` → `"30 s"`, `"1 min"`, `"1 min 30 s"`, `"4 min"`.
  - `AppSettings.jiggler: JigglerSettings` (default `.default`), `AppSettings.with(jiggler:)`.

- [ ] **Step 1: Write failing tests** — `JigglerSettingsTests`:
  - `defaults`: `.default` == (false, 60, 20).
  - `clamps`: `JigglerSettings(idleThreshold: 9999, interval: 1)` → 240, 10; `idleThreshold: .nan` → 60.
  - `tolerantDecoding`: `{"isEnabled":true,"interval":"x","idleThreshold":9999}` → (true, 240, 20); `{}` → `.default`.
  - `labels`: 30→"30 s", 60→"1 min", 90→"1 min 30 s", 240→"4 min".
  - `AppSettingsTests.jigglerRoundTrip`: `.default.with(jiggler: JigglerSettings(isEnabled: true, idleThreshold: 120, interval: 30))` encodes/decodes equal; `{"jiggler": 5, "mode": "schedule"}` → jiggler `.default`, mode `.schedule`; `AppSettings.default.jiggler == .default`.
- [ ] **Step 2: Run** `swift test --filter "JigglerSettings|AppSettings"` → Expected: compile FAIL (`JigglerSettings` not found).
- [ ] **Step 3: Implement** the type and the `AppSettings` field.
- [ ] **Step 4: Run** `make test` → Expected: all pass.
- [ ] **Step 5: Commit** `feat: jiggler settings`

### Task 2: `JigglerClock`

**Files:**
- Create: `Sources/LisdexCore/JigglerClock.swift`
- Test: `Tests/LisdexCoreTests/JigglerClockTests.swift`

**Interfaces:**
- Consumes: `JigglerSettings` (Task 1).
- Produces:
  - `public struct JigglerClock: Sendable { init(settings: JigglerSettings); func step(now: Date, idleSeconds: TimeInterval, inputHeld: Bool, state: State) -> Step }`
  - `public struct State: Equatable, Sendable { lastRealInput: Date?; lastJiggle: Date?; static let initial }`
  - `public struct Step: Equatable, Sendable { jiggle: Bool; nextCheck: Date; state: State }`
  - `static let ownEventTolerance: TimeInterval = 1`, `static let minimumDelay: TimeInterval = 1`.

Algorithm (the tests pin it):
1. `inputHeld` → real input is `now`; `lastJiggle = nil`.
2. Else latest event = `now − idleSeconds`. If `lastJiggle` exists and `|latest − lastJiggle| ≤ 1` → it's Lisdex's own; keep `lastRealInput` (if nil, use `lastJiggle`). Otherwise `lastRealInput = latest`, `lastJiggle = nil`.
3. `idle = now − lastRealInput`. If `idle < threshold` → no jiggle, `nextCheck = lastRealInput + threshold`.
4. Else if `lastJiggle == nil` or `now − lastJiggle ≥ interval` → jiggle, `lastJiggle = now`, `nextCheck = now + interval`. Else `nextCheck = lastJiggle + interval`.
5. `nextCheck = max(nextCheck, now + minimumDelay)`.

- [ ] **Step 1: Write failing tests** (threshold 60, interval 20, `t0 = Date(timeIntervalSinceReferenceDate: 0)`):
  - `waitsUntilThreshold`: idle 10, initial → no jiggle, nextCheck t0+50.
  - `jigglesAfterThreshold`: idle 60 → jiggle, nextCheck t0+20, state.lastJiggle t0, lastRealInput t0−60.
  - `ownJiggleIsNotUserInput`: after the jiggle at t0, step at t0+20 with idle 20 → jiggle again, lastRealInput still t0−60.
  - `waitsBetweenJiggles`: after jiggle at t0, step at t0+5 with idle 5 → no jiggle, nextCheck t0+20.
  - `realInputRestartsWait`: after jiggle at t0, step at t0+20 with idle 3 → no jiggle, lastJiggle nil, lastRealInput t0+17, nextCheck t0+77.
  - `heldInputBlocksJiggle`: idle 300, inputHeld → no jiggle, lastRealInput now, nextCheck now+60.
  - `earlyFireReschedules`: idle 59.8 → no jiggle, nextCheck == now+1 (minimum delay).
- [ ] **Step 2: Run** `swift test --filter JigglerClock` → Expected: compile FAIL.
- [ ] **Step 3: Implement** `JigglerClock`.
- [ ] **Step 4: Run** `make test` → Expected: all pass.
- [ ] **Step 5: Commit** `feat: jiggler clock decides when to jiggle`

### Task 3: `Jiggler` engine, permission, `AppModel` wiring

**Files:**
- Create: `Sources/Lisdex/System/Jiggler.swift`, `Sources/Lisdex/System/PostEventPermission.swift`
- Modify: `Sources/Lisdex/Log.swift` (`static let jiggler`), `Sources/Lisdex/AppModel.swift`, `Sources/Lisdex/AppModel+Bindings.swift`, `Sources/Lisdex/AppDelegate.swift` (refresh on `didBecomeActive`), `Sources/Lisdex/StatusItemController.swift` (refresh when the popover opens), `Sources/Lisdex/Settings/SettingsWindowController.swift` (refresh on show)

**Interfaces:**
- Consumes: `JigglerSettings`, `JigglerClock` (Tasks 1–2), `SessionPlan.holdsAwake`.
- Produces:
  - `enum PostEventPermission { static var isGranted: Bool; static func request(); static func openSettings() }` — `CGPreflightPostEventAccess`, `CGRequestPostEventAccess`, `NSWorkspace.open(pane URL)`.
  - `@MainActor final class Jiggler { func run(_ settings: JigglerSettings?) }` — `nil` stops (invalidate timer, reset state); non-nil (re)starts with a fresh `JigglerClock`, ticking immediately. Tick: skip when screen locked (reschedule after interval); read `CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)`, held = any of keys 0…127 (`keyState`) or buttons left/right/center (`buttonState`) down; on `jiggle` post `CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGEvent(source: nil)?.location ?? .zero, mouseButton: .left)?.post(tap: .cghidEventTap)`; schedule a one-shot `Timer` at `nextCheck` (tolerance 0.5 s). `run` with settings equal to the running ones is a no-op (no restart).
  - `AppModel`: `private(set) var jigglerPermitted: Bool`; `func refreshJigglerPermission()`; `var jigglerNeedsPermission: Bool` (enabled ∧ `currentPlan.holdsAwake` ∧ ¬permitted); `func setJiggler(_ settings: JigglerSettings)` (update + reconcile); `func requestJigglerPermission()` (request once per launch, then open the pane). `reconcile()` ends with `jiggler.run(settings.jiggler.isEnabled && plan.holdsAwake && jigglerPermitted ? settings.jiggler : nil)`; `shutdown()` calls `jiggler.run(nil)`.
  - Bindings: `jigglerEnabledSetting: Bool`, `jigglerIdleThresholdSetting: Double`, `jigglerIntervalSetting: Double`.

- [ ] **Step 1: Implement** the files above. `refreshJigglerPermission()` reconciles only when the value changed.
- [ ] **Step 2: Run** `make test && make app` → Expected: tests pass, `Built: …/build/Lisdex.app`.
- [ ] **Step 3: Verify** with a temporary `defaults` write of `jiggler` (enabled, threshold 30, interval 10) on a certificate-signed build with the permission granted, Keep Awake on, hands off: `log stream --predicate 'subsystem == "io.github.pedrol2b.lisdex" AND category == "jiggler"'` shows a jiggle ~30 s after the last input and every ~10 s after; `ioreg -c IOHIDSystem | grep HIDIdleTime` stays below ~11 s. Touching the mouse → log shows the wait restarting. Restore the settings backup afterwards.
- [ ] **Step 4: Commit** `feat: jiggler posts mouse moves while Keep Awake holds`

### Task 4: Settings section and popover warning

**Files:**
- Create: `Sources/Lisdex/Settings/JigglerSection.swift`
- Modify: `Sources/Lisdex/Settings/SettingsView.swift` (`PowerSettings` adds `JigglerSection(model:)` after the first section), `Sources/Lisdex/Views/MenuView.swift` (warning line under the Keep Awake row)

**Interfaces:**
- Consumes: Task 3's model API and bindings; `JigglerSettings.label(seconds:)`, ranges and steps.
- Produces: UI only.

- [ ] **Step 1: Implement** `JigglerSection`: `Section("Chat apps")` with the switch; caption "Teams and Slack mark you Away when the Mac sees no input. While Keep Awake is on, Lisdex moves the mouse by 0 px after you've been idle, so they don't. While it runs, the screen saver and display sleep wait too."; two `LabeledContent` rows with `Slider(step:)` — "Start after" (value label `label(seconds:)`) and "Repeat every" — disabled while off; permission row (only while on): ✅/⚠︎ text, "Open Accessibility Settings" button calling `requestJigglerPermission()`, and the footnote; `.task(id:)` re-checking every 2 s while ⚠︎ shows.
- [ ] **Step 2: Implement** the popover line: when `model.jigglerNeedsPermission`, a `.link` button with `exclamationmark.triangle.fill` (orange) titled "Mouse jiggler needs permission" calling `PostEventPermission.openSettings()`, caption font.
- [ ] **Step 3: Run** `make test && make lint && make app` → Expected: pass, no lint findings, app built.
- [ ] **Step 4: Verify** in the running app: Settings → Power shows the section; sliders disabled while off, labels "1 min" / "20 s" by default; with the permission missing the ⚠︎ row and button show; the popover line appears only with the jiggler on, Keep Awake holding and no permission.
- [ ] **Step 5: Commit** `feat: Settings → Power "Chat apps" section and popover permission warning`

### Task 5: Records

**Files:**
- Create: `.context/decisions/0024-mouse-jiggler.md`, `.context/evidence/2026-11-24-mouse-jiggler/notes.md` (spike table + Task 3/4 verification)
- Modify: `.context/specs/lisdex-v1.md` (Settings → Power line), `.context/specs/mouse-jiggler.md` (status: approved), `README.md` (feature row + permission note), `CHANGELOG.md` (Unreleased → Added), `.context/status/current.md` (Phase 9 row)

- [ ] **Step 1: Write** the records.
- [ ] **Step 2: Run** `make test` → Expected: pass.
- [ ] **Step 3: Commit** `docs: mouse jiggler records`
