# Keyboard shortcuts — verification (2026-11-23)

Driven on `build/Lisdex.app` with real clicks (cliclick) and raw `CGEvent` key posts; Keep Awake
state from `pmset -g assertions`, saved combos from `settings.v1`.

| Step | Result |
| --- | --- |
| Record ⌃⌥⌘L on Toggle (Settings frontmost) | saved `{"toggle":{"keyCode":37,"modifiers":11}}` |
| Press ⌃⌥⌘L, Settings frontmost | toggles (2 → 0) |
| Press ⌃⌥⌘L, another app frontmost / at launch | toggles |
| Record ⌃⌥⌘L on Stop | "Already used for Toggle Keep Awake.", nothing fired (hot keys paused) |
| ⌘Q while recording | "Reserved by macOS.", Lisdex keeps running |
| Esc | recording ends, note cleared, ⌃⌥⌘L fires again (0 → 2) |
| Re-record Toggle as ⌃⌥⌘K | old ⌃⌥⌘L no-op, ⌃⌥⌘K toggles |
| Delete while recording | shortcut cleared |
| ⌃⌥⌘S → Stop, ⌃⌥⌘D → Start for a Duration (900 s) | off; Duration mode with 900 s |
| Bare F6 → Toggle | fires on a physical-style event (fn flag set) |

Notes:
- cliclick's `kd:… t:x` does not reliably carry modifier flags on the key event, so Carbon hot
  keys may not see them; raw `CGEvent` posts (and real keyboards) do.
- A hosted `NSView` has no text baseline in SwiftUI forms; the recorder sets
  `alignmentGuide(.firstTextBaseline)` so rows stay single-line.

`make test` 80/80, `make lint` clean.
