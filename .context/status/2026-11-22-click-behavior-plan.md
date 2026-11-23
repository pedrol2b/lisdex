# Click Behavior Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Settings choice of which status-item click toggles Keep Awake and which opens the popover.

**Architecture:** Pure mapping (click + setting → action) in `LisdexCore` with tests; `AppSettings` stores the choice with tolerant decoding; `StatusItemController` asks the mapping; Settings → General gets a picker.

**Tech Stack:** Swift 6, SwiftPM, Swift Testing, AppKit + SwiftUI.

**Spec:** `.context/specs/click-behavior.md`

## Global Constraints

- Default = `rightClickToggles` (v1.0 behaviour unchanged for existing users).
- Missing or unknown `clickBehavior` in `settings.v1` → default, other fields untouched.
- Control-click counts as a secondary click.
- Option-click is not handled here (reserved for the quick menu).
- Picker copy: label "Quick-Start a Session"; options "Right click (left click shows menu)" / "Left click (right click shows menu)".
- Compile with Swift 6.3: bind with `Bindable(model).clickBehaviorSetting`, never `Binding(get:set:)`.
- No `print`; immutable values.

## Review Focus

- Settings saved by v1.0.x (no `clickBehavior` key) → right-click still toggles. Test in Task 1.
- Garbage value (`"clickBehavior":"middle"`) → default, rest of settings kept. Test in Task 1.
- Control-click under `leftClickToggles` → opens popover (it is a secondary click). Test in Task 1 (`secondary` → `openPopover`).
- Toggle click while the popover is open → still toggles; popover is transient and closes itself. Manual check in Task 2.
- Changing the setting takes effect on the next click without relaunch (controller reads `model.settings` per click). Manual check in Task 2.

---

### Task 1: Core — click behavior model + setting

**Files:**
- Create: `Sources/LisdexCore/StatusItemClick.swift`
- Modify: `Sources/LisdexCore/AppSettings.swift` (property, init param, decoding, `with`)
- Test: `Tests/LisdexCoreTests/StatusItemClickTests.swift`

**Interfaces:**
- Produces:
  - `public enum StatusItemClick: Sendable { case primary, secondary }`
  - `public enum StatusItemAction: Equatable, Sendable { case toggle, openPopover }`
  - `public enum StatusItemClickBehavior: String, Codable, CaseIterable, Sendable { case rightClickToggles, leftClickToggles }` with `static let default = .rightClickToggles`, `var title: String`, `func action(for click: StatusItemClick) -> StatusItemAction`
  - `AppSettings.clickBehavior: StatusItemClickBehavior`, `with(clickBehavior:)`

- [ ] **Step 1: Write the failing tests** (`@Suite("StatusItemClick")`)

```swift
@Test("default keeps v1.0: right-click toggles, left-click opens the popover")
func defaults() {
  let b = AppSettings.default.clickBehavior
  #expect(b == .rightClickToggles)
  #expect(b.action(for: .secondary) == .toggle)
  #expect(b.action(for: .primary) == .openPopover)
}

@Test("swapped: left-click toggles, right/control-click opens the popover")
func swapped() {
  #expect(StatusItemClickBehavior.leftClickToggles.action(for: .primary) == .toggle)
  #expect(StatusItemClickBehavior.leftClickToggles.action(for: .secondary) == .openPopover)
}

@Test("titles match the Settings copy")
func titles() {
  #expect(StatusItemClickBehavior.rightClickToggles.title == "Right click (left click shows menu)")
  #expect(StatusItemClickBehavior.leftClickToggles.title == "Left click (right click shows menu)")
}

@Test("older settings load with the default; unknown values fall back; the choice round-trips")
func decoding() throws {
  let old = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"accent":"mint"}"#.utf8))
  let bad = try JSONDecoder().decode(
    AppSettings.self, from: Data(#"{"clickBehavior":"middle","accent":"mint"}"#.utf8))
  let swapped = AppSettings.default.with(clickBehavior: .leftClickToggles)
  let back = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(swapped))

  #expect(old.clickBehavior == .rightClickToggles && old.accent == .mint)
  #expect(bad.clickBehavior == .rightClickToggles && bad.accent == .mint)
  #expect(back == swapped)
}
```

- [ ] **Step 2: Run** `swift test --filter StatusItemClick` → fails to compile (types missing).
- [ ] **Step 3: Implement** the types above in `StatusItemClick.swift`; add `clickBehavior` to `AppSettings` after `toggleSound` (init default `.default`, decode with `(try? decodeIfPresent) ?? fallback`, `with(clickBehavior:)`).
- [ ] **Step 4: Run** `make test` → all pass.
- [ ] **Step 5: Commit** `feat: add click behavior setting to core`

### Task 2: App — wire the click and the Settings picker

**Files:**
- Modify: `Sources/Lisdex/StatusItemController.swift:62-71` (`handleClick`)
- Modify: `Sources/Lisdex/AppModel.swift` (`setClickBehavior(_:)` next to `setToggleSound`)
- Modify: `Sources/Lisdex/AppModel+Bindings.swift` (`clickBehaviorSetting`)
- Modify: `Sources/Lisdex/Settings/SettingsView.swift` (`GeneralSettings`, new `Section` before "Sound")
- Modify: `.context/specs/lisdex-v1.md` (Interactions table + note), `.context/status/current.md`

**Interfaces:**
- Consumes: `StatusItemClick`, `StatusItemAction`, `AppSettings.clickBehavior`, `with(clickBehavior:)` from Task 1.
- Produces: `AppModel.setClickBehavior(_ behavior: StatusItemClickBehavior)`, `AppModel.clickBehaviorSetting`.

- [ ] **Step 1:** `handleClick`: map `rightMouseUp` or `.control` modifier → `.secondary`, else `.primary`; `switch model.settings.clickBehavior.action(for:)` → `.toggle` calls `model.toggle()`, `.openPopover` calls `togglePopover(relativeTo:)`.
- [ ] **Step 2:** `setClickBehavior` → `update(settings.with(clickBehavior:))`; binding property per the file's pattern; `Picker("Quick-Start a Session", selection: Bindable(model).clickBehaviorSetting)` over `allCases` with `title`, in its own `Section` at the top of General's second block.
- [ ] **Step 3:** Update spec Interactions table: left/right rows say "depends on Settings → General → Quick-Start a Session (default: right-click toggles)".
- [ ] **Step 4: Verify** `make test && make lint && make app`; launch, check both settings: default right-click toggles / left opens; swapped left toggles / right and control-click open; toggle with popover open; switching takes effect without relaunch. Notes + screenshot in `.context/evidence/2026-11-22-click-behavior/`.
- [ ] **Step 5: Commit** `feat: let users swap which click toggles keep awake` (include the roadmap update and spec/plan docs).
