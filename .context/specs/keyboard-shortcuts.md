# Keyboard shortcuts — Phase 7.2

_Approved by owner 2026-11-23. Owner picked Approach B; owner tests on the branch before it is marked ready — if B disappoints, step back to A._

## Intent

Start or stop Keep Awake from any app without touching the menu bar: global keyboard shortcuts the user records in Settings.

## Goals / non-goals / anti-goals

- Goals: four actions, each with an optional global shortcut, recorded in Settings; works without any permission prompt.
- Non-goals: per-preset duration shortcuts (one "Start for a duration" only — owner, 2026-11-22); a Schedule shortcut (Toggle covers it); Shortcuts.app / App Intents (Phase 8, will reuse the same actions).
- Anti-goals: shipping default shortcuts that steal another app's combo; asking for Accessibility permission; a new dependency (unless we fall back to A).

## Actions

| Action | Does | Model call |
| --- | --- | --- |
| Toggle Keep Awake | Same as the toggle click: on/off, keeps the mode | `toggle()` |
| Start Indefinitely | Mode → Indefinitely, on | `setMode(.indefinitely)` + `setOn(true, feedback: true)` |
| Start for a Duration | Mode → Duration with the length picked on its row (15 m / 30 m / 1 h / 2 h), restarts the timer | `startDuration(row length)` |
| Stop | Off | `setOn(false, feedback: true)` |

All four play the toggle sound when on/off actually changes (existing rule in `setOn`). "Start for a Duration" also becomes the remembered duration, the same as tapping a chip.

## Approaches

- **A. KeyboardShortcuts library** — finished recorder, layout-aware names, reserved-combo warnings; but stores outside `settings.v1` (ADR 0006), first dependency in a source-built Homebrew formula, must keep compiling on Swift 6.3.
- **B. Own Carbon wrapper (picked)** — `RegisterEventHotKey`, no permission, no dependency, shortcuts in `settings.v1`, rules testable in Core. Cost: we build the recorder (~300–400 lines).
- Ruled out: `NSEvent` global monitor (needs Accessibility), MASShortcut (Objective-C, unmaintained).

## Design

**Core (Foundation only, tested)**
- `KeyCombo` — `keyCode: UInt16` + `modifiers: KeyModifiers` (OptionSet: control, option, shift, command). Codable. `displayString(keyName:)` → modifier glyphs in macOS order `⌃⌥⇧⌘` + key name.
- `KeyCombo.validate(...) -> KeyComboProblem?` — needs ⌃, ⌥ or ⌘ (⇧ alone is not enough), except F1–F20 which may stand alone; rejects a fixed list of macOS-reserved combos (⌘Q, ⌘W, ⌘Tab, ⌘Space, ⌃Space, ⌘⇧3/4/5, ⌘⌥Esc); rejects a combo already used by another Lisdex action (message names it).
- `ShortcutAction` enum (the four actions, titles) and `ShortcutSettings` (`[ShortcutAction: KeyCombo]` plus `durationSeconds`, default 3600 from `DurationPreset.all`). `AppSettings.shortcuts`, tolerant decoding: missing → none assigned; one bad entry drops that entry only.
- Special-key names (Return, Space, Delete, arrows, F-keys, Esc…) as a table in Core; letter/number names come from the app layer.

**App**
- `HotKeyCenter` (`@MainActor`) — registers/unregisters with `RegisterEventHotKey`, one Carbon event handler, maps hot-key IDs back to `ShortcutAction`, calls `AppModel`. Re-registers whenever `settings.shortcuts` changes. If macOS refuses a combo (taken by another app), the row shows "Already in use by another app" and the stored combo is kept so it works once freed.
- Key names for the current keyboard layout via `UCKeyTranslate` (so AZERTY shows A where QWERTY shows Q).
- Recorder field (SwiftUI wrapping an `NSView`): click → "Type shortcut…"; next valid combo is saved; Esc cancels; Delete clears; an ✕ clears. While recording, Lisdex's own hotkeys are paused so pressing an existing combo records it instead of firing it.
- Settings: new **Shortcuts** tab (`keyboard` symbol) with four rows; the Duration row has a length picker next to its recorder. No shortcuts assigned by default.

**Records**
- ADR 0019 (Carbon hotkeys, no dependency, storage in `settings.v1`; fallback to KeyboardShortcuts if owner testing rejects it).
- Spec `lisdex-v1.md` interactions table gains a "Global shortcuts" row.

## Rollout

Built on a branch; owner tries it in `build/Lisdex.app` before merge. Decision point after testing: keep B → merge; reject → replace `HotKeyCenter` + recorder with KeyboardShortcuts, keep Core actions.

## Left to the builder

File split inside `Sources/Lisdex/Shortcuts/`, exact recorder visuals (match the existing Settings form style), how the "already in use" note is styled.
