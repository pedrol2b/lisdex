# Keyboard Shortcuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (owner chose native execution). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Four optional global shortcuts (Toggle, Start Indefinitely, Start for a Duration, Stop), recorded in a new Settings → Shortcuts tab.

**Architecture:** Combination model, validation, display and settings storage in `LisdexCore` (tested). App layer: `HotKeyCenter` wraps Carbon `RegisterEventHotKey`; a recorder `NSView` in SwiftUI; layout-aware key names via `UCKeyTranslate`.

**Tech Stack:** Swift 6, SwiftPM, Swift Testing, AppKit/SwiftUI, Carbon.HIToolbox.

**Spec:** `.context/specs/keyboard-shortcuts.md` · ADR 0019.

## Global Constraints

- No package dependencies. No Accessibility permission. No shortcuts assigned by default.
- Valid combo: contains ⌃, ⌥ or ⌘ — or the key is F1–F20 (any modifiers).
- Reserved (refused): ⌘Q, ⌘W, ⌘Tab, ⌘Space, ⌃Space, ⌘⇧3, ⌘⇧4, ⌘⇧5, ⌘⌥Esc. Letters/digits matched by layout key name, special keys by key code.
- Same combo on two Lisdex actions refused; message names the other action.
- Display order of modifiers `⌃⌥⇧⌘`.
- Duration row lengths: `DurationPreset.all` (15 m / 30 m / 1 h / 2 h); default 3600 s.
- Swift 6.3: SwiftUI bindings via `Bindable(model).x`, never `Binding(get:set:)`. No `print`; `Log`.
- Branch `feat/keyboard-shortcuts` is **not merged** until the owner has tested it.

## Review Focus

- Pressing a shortcut while the Settings recorder is focused must record, not fire (hotkeys paused while recording). Manual, Task 4.
- Changing a combo unregisters the old one (old combo no longer fires). Manual, Task 3.
- Combo already taken by another app → row says so, combo kept. Manual, Task 3 (register a combo twice from a second Lisdex instance is not possible; simulate by checking `RegisterEventHotKey` status path with a test log) — at minimum code-reviewed.
- Settings from v1.0.x / garbage `shortcuts` JSON → no shortcuts, other settings kept. Test, Task 2.
- Quitting unregisters hot keys and removes the event handler (no dangling handler). Code review, Task 3.

---

### Task 1: Core — KeyCombo, modifiers, names, validation

**Files:** Create `Sources/LisdexCore/KeyCombo.swift`, `Sources/LisdexCore/ShortcutAction.swift`; Test `Tests/LisdexCoreTests/KeyComboTests.swift`.

**Produces:**
- `public struct KeyModifiers: OptionSet, Codable, Hashable, Sendable` (`rawValue: UInt8`; `.control, .option, .shift, .command`), `var symbols: String` in `⌃⌥⇧⌘` order.
- `public struct KeyCombo: Codable, Hashable, Sendable { keyCode: UInt16; modifiers: KeyModifiers }`
  - `static func specialKeyName(_ keyCode: UInt16) -> String?` (Return 36 "↩", Tab 48 "⇥", Space 49 "Space", Delete 51 "⌫", Esc 53 "⎋", Fwd-Delete 117 "⌦", Home 115 "↖", End 119 "↘", PgUp 116 "⇞", PgDn 121 "⇟", ←123 →124 ↓125 ↑126, F1–F20 by kVK codes)
  - `var isFunctionKey: Bool`
  - `func displayString(keyName: String) -> String` = `modifiers.symbols + (specialKeyName ?? keyName.uppercased())`
- `public enum ShortcutAction: String, CaseIterable, Codable, CodingKey, Sendable { case toggle, startIndefinitely, startDuration, stop }` with `title` ("Toggle Keep Awake", "Start Indefinitely", "Start for a Duration", "Stop").
- `public enum KeyComboProblem: Equatable, Sendable { case needsModifier, reservedBySystem, usedBy(ShortcutAction) }` with `message` ("Add ⌃, ⌥ or ⌘.", "Reserved by macOS.", "Already used for <title>.").
- `KeyCombo.problem(keyName: String, action: ShortcutAction, assigned: [ShortcutAction: KeyCombo]) -> KeyComboProblem?` — checks in order: needsModifier, reservedBySystem, usedBy (ignoring `action` itself).

- [ ] **Step 1: tests** — `symbols` order for all four; display `⌃⌥⌘L` for keyName "l"; `⌘Space` for 49; F5 (96) alone valid; `⇧A` → `.needsModifier`; bare `A` → `.needsModifier`; ⌘Q (keyName "q") → `.reservedBySystem`; ⌘⇧4 → reserved; ⌃Space → reserved; ⌘⌥Esc → reserved; ⌃⌥⌘L valid; same combo assigned to `.stop` → `.usedBy(.stop)` when recording `.toggle`, `nil` when recording `.stop`; JSON round-trip of `KeyCombo`; `message` strings exact.
- [ ] **Step 2:** `swift test --filter KeyCombo` → compile failure.
- [ ] **Step 3:** implement.
- [ ] **Step 4:** `make test` → pass. **Step 5:** commit `feat: add key combo model and validation to core`.

### Task 2: Core — ShortcutSettings in AppSettings

**Files:** Create `Sources/LisdexCore/ShortcutSettings.swift`; Modify `Sources/LisdexCore/AppSettings.swift`; Test `Tests/LisdexCoreTests/ShortcutSettingsTests.swift`.

**Consumes:** Task 1 types. **Produces:**
- `public struct ShortcutSettings: Codable, Equatable, Sendable { combos: [ShortcutAction: KeyCombo]; durationSeconds: TimeInterval }`, `static let default` (empty, 3600), `func with(_ combo: KeyCombo?, for: ShortcutAction) -> ShortcutSettings`, `func with(durationSeconds:)`.
- Codable shape: `{"combos":{"toggle":{"keyCode":37,"modifiers":13}},"durationSeconds":3600}`. Decoding: nested container keyed by `ShortcutAction`; each entry `try?` (bad entry dropped); unknown keys ignored; non-finite/≤0 duration → 3600.
- `AppSettings.shortcuts: ShortcutSettings` (after `clickBehavior`), init default, tolerant decode, `with(shortcuts:)`.

- [ ] **Step 1: tests** — default empty + 3600; `with` set/clear returns new value, original untouched; round-trip; `{"accent":"mint"}` → default shortcuts, accent kept; `{"shortcuts":"garbage"}` → default; one bad entry (`"stop":{"keyCode":"x"}`) dropped while `toggle` kept; `durationSeconds: -5` → 3600.
- [ ] **Step 2–4:** red → implement → `make test` green. **Step 5:** commit `feat: store keyboard shortcuts in settings`.

### Task 3: App — actions, HotKeyCenter, key names

**Files:** Create `Sources/Lisdex/Shortcuts/HotKeyCenter.swift`, `Sources/Lisdex/Shortcuts/KeyboardLayout.swift`; Modify `AppModel.swift`, `AppDelegate.swift`.

**Produces:**
- `AppModel.perform(_ action: ShortcutAction)`: toggle → `toggle()`; startIndefinitely → `setMode(.indefinitely)` then `setOn(true, feedback: true)`; startDuration → `startDuration(settings.shortcuts.durationSeconds)`; stop → `setOn(false, feedback: true)`.
- `AppModel.setShortcut(_ combo: KeyCombo?, for: ShortcutAction)`, `setShortcutDuration(_:)`; observable `var isRecordingShortcut = false`; `private(set) var shortcutsInUseElsewhere: Set<ShortcutAction> = []` with a setter used by HotKeyCenter (`func reportUnavailableShortcuts(_:)`).
- `@MainActor final class HotKeyCenter` — `init(model:)`; one `InstallEventHandler` on `GetApplicationEventTarget()` for `kEventHotKeyPressed`; C callback reads `EventHotKeyID`, hops via `MainActor.assumeIsolated` to a static registry → `model.perform`. Observes `settings.shortcuts` + `isRecordingShortcut` with `withObservationTracking`; on change unregisters all, then (unless recording) registers each combo (signature `"LSDX"`, id = action index + 1). Non-`noErr` status → action added to unavailable set. `stop()` unregisters + `RemoveEventHandler`, called from `applicationWillTerminate`.
- `enum KeyboardLayout { static func keyName(for keyCode: UInt16) -> String }` — `TISCopyCurrentKeyboardLayoutInputSource` / `kTISPropertyUnicodeKeyLayoutData` + `UCKeyTranslate` (no modifiers); fallback `"#\(keyCode)"`.
- Modifier mapping KeyModifiers → Carbon (`controlKey`, `optionKey`, `shiftKey`, `cmdKey`) and NSEvent.ModifierFlags → KeyModifiers as small private helpers.

- [ ] **Step 1:** implement; `make test && make lint && make app` green.
- [ ] **Step 2: verify** — write `shortcuts` with ⌃⌥⌘L→toggle into `settings.v1`, launch, press it with `cliclick kd:ctrl,alt,cmd t:l ku:ctrl,alt,cmd`, check `pmset -g assertions` flips; change combo, old one no longer fires; F-key alone works.
- [ ] **Step 3:** commit `feat: register global keyboard shortcuts with carbon hot keys`.

### Task 4: App — recorder + Shortcuts tab + docs

**Files:** Create `Sources/Lisdex/Shortcuts/ShortcutRecorder.swift`, `Sources/Lisdex/Settings/ShortcutSettingsView.swift`; Modify `SettingsView.swift` (tab `.shortcuts`, `Label("Shortcuts", systemImage: "keyboard")`), `AppModel+Bindings.swift` (`shortcutDurationSetting`), `.context/specs/lisdex-v1.md` (interactions row "Global shortcuts"), `.context/status/current.md`.

- Recorder: `NSView` subclass (first responder) in `NSViewRepresentable`; click → recording (sets `model.isRecordingShortcut = true`), shows "Type shortcut…"; `keyDown`/`performKeyEquivalent` → build `KeyCombo`; Esc cancels; Delete/⌫ clears; problem → shows `message` under the row, nothing saved; valid → `setShortcut`. Losing focus ends recording. ✕ button clears. Shows `displayString(keyName:)`.
- Row note "Already in use by another app" when action ∈ `shortcutsInUseElsewhere`.
- Duration row: `Picker` over `DurationPreset.all` bound to `Bindable(model).shortcutDurationSetting`.
- `-LisdexScreenshot shortcuts` opens the tab (extend `SettingsTab`).

- [ ] **Step 1:** implement; `make test && make lint && make app`.
- [ ] **Step 2: verify** — record ⌃⌥⌘L via cliclick into Toggle row → saved & fires; record ⌘Q → "Reserved by macOS."; record same combo on Stop → "Already used for Toggle Keep Awake."; while recording, existing combo is captured not fired; screenshot to `.context/evidence/2026-11-23-keyboard-shortcuts/`.
- [ ] **Step 3:** docs + status; commit `feat: add shortcuts settings tab with recorder`.
