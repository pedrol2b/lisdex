# Click behavior — verification (2026-11-22)

Real clicks on `build/Lisdex.app` (cliclick), Keep Awake state read from `pmset -g assertions`.

| Setting | Click | Result |
| --- | --- | --- |
| default (no key in `settings.v1`) | left | popover opens, assertions unchanged |
| default | right | toggles (2 → 0 → 2) |
| default | control-click | toggles (2 → 0 → 2) |
| `leftClickToggles` | left | toggles (2 → 0 → 2) |
| `leftClickToggles` | right | popover opens |
| `leftClickToggles` | control-click | popover, no toggle |
| picker → "Right click", no relaunch | right | toggles; saved `rightClickToggles` |

Toggling with the popover/Settings open works. `make test` 65/65, `make lint` clean.
Screenshot: `settings-general-picker.png` (General tab, picker under the first section).
