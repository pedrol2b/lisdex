# Icon redesign — verification (2026-11-25)

Build: `make app` on branch `feat/settings-rework`, macOS 27.2 SDK.

| Check | Result | Evidence |
| ----- | ------ | -------- |
| 24 menu bar SVGs exported from Figma page 50:2093 export frames; background rect and ids stripped | ✅ only black / `none` fills, no `<image>` or `<text>` | `assets/menubar/*.svg` |
| `make icons` regenerates PDFs + 1x/2x/3x PNGs (120 files) and mode PDFs; app icon outputs identical | ✅ | — |
| `make test` | ✅ 178 tests (aliases pill/bulb → Capsule, mug → Coffee, minimal/faithful/unknown → Capsule; every variant × state × badge and mode symbol has its files) | — |
| `make lint` | ✅ | — |
| Settings → Appearance shows Capsule / Molecule / Coffee cards | ✅ | `assets/screenshots/settings-appearance.png` |
| Menu mode rows show the new ∞ / clock / calendar symbols | ✅ | `assets/screenshots/popover-*.png` |
| Owner's saved `pill` shows as Capsule after the update | ✅ owner's running build | — |
| Real menu bar crispness, light/dark, badge legibility at actual size | ✅ owner approved ("it looks nice") | owner's menu bar |

Contact sheet (all 24 at 18 pt on light and dark) was shown in the browser companion
(`.superpowers/brainstorm/`, not committed).
