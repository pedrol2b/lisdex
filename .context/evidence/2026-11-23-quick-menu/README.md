# Option-click quick menu — verification (2026-11-23)

Option held via a real key-down (`CGEvent` kVK_Option on the HID state) plus a click on the
status item; state from `pmset -g assertions` and `settings.v1`.

| Step | Result |
| --- | --- |
| Option + left-click, on | menu with 15/30 min, 1/2 h, Until I Stop, Stop (`menu-while-on.png`) |
| Option + left-click, off | same without Stop (`menu-while-off.png`) |
| Option + right-click | menu |
| 30 Minutes | Duration mode, 1800 s remembered, on |
| Stop | off |
| Until I Stop | Indefinitely, on |
| Plain right-click / left-click | toggle / popover, unchanged |

Finding: the status item's click event carried **no modifier flags** (logged `flags 0` even with
Option held), so the click kind now unions `NSApp.currentEvent.modifierFlags` with
`NSEvent.modifierFlags` (keys held right now). cliclick's `kd:alt c:` and a click event with only
`.maskAlternate` set did not reproduce a held Option; a real key-down did.

`make test` 84/84, `make lint` clean.
