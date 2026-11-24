# Mode badge — verification, 2026-11-24

- `swift test`: 161 tests in 27 suites pass (new: `MenuBarBadge`, `Menu bar assets`, badged
  `MenuBarIcon` names/labels, `AppSettings` mode badge default / round-trip / 1.2 settings).
- `make e2e`: 9/9.
- Figma: pill badge variants rebuilt on 20 × 18 from the shipped pill; SVGs exported with the
  plugin `exportAsync` (the REST export adds background rectangles). Contact sheet of all 24
  glyphs checked by eye.
- Status item, by `log stream` of the debug line "Menu bar icon <resource>" (status-item windows
  can't be captured with `screencapture -l`), badge switch on:

| Scenario | Icon |
| --- | --- |
| off, mode Duration | `pill-duration-inactive` |
| on (Duration) | `pill-duration-active` |
| `lisdex://on?until=stopped` | `pill-indefinitely-active` |
| mug, mode Indefinitely, `on?minutes=90` | `mug-duration-active` |
| mug off, Indefinitely | `mug-indefinitely-inactive` |
| bulb off, Schedule | `bulb-schedule-inactive` |
| TextEdit (listed app) opens | `bulb-indefinitely-active` |
| TextEdit quits | `bulb-schedule-inactive` |
| `on`, schedule waiting outside its window | `bulb-schedule-inactive` |
| 1.2 settings (no key), on | `pill-active` |

- Settings → Appearance: switch + caption under the icon picker (screenshot in
  `assets/screenshots/settings-appearance.png`).
- Owner to check: the icons in light and dark menu bars.
