# Light bulb menu bar icon (Phase 7.4)

Source: Figma "APPROVED / Lisdex / Pill · Coffee mug · Light bulb" (node 10:254), 18 pt glyphs
24:540 (inactive) and 24:543 (active). The board background in the export was stripped; only
the pure-black glyph paths are kept in `assets/menubar/bulb-{inactive,active}.svg`.
PDF/PNG exports come from `make icons` (ADR 0003).

## Checked in the running app (2026-11-23)

- `settings.v1.iconVariant = "bulb"` → the status item shows the bulb.
- Dark menu bar, Keep Awake on: filled bulb with the filament cut out (`menubar-dark-on.png`).
- Right-click → off: outlined bulb (`menubar-dark-off.png`).
- `build/Lisdex.app/Contents/Resources` contains `bulb-inactive.pdf` and `bulb-active.pdf`.
- 87 tests pass, including the new pill → mug → bulb choice order and titles.

Not checked by me: the light menu bar (template tinting, same as pill/mug) and the Settings →
Appearance card (built from `MenuBarIconVariant.allCases`), left for the owner test.

## Owner test

2026-11-23: owner tested the bulb icon. Merged to main.
