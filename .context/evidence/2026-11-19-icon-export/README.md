# Icon export from Figma — 2026-11-19

- Source: `sources/figma-identity.md` (iteration 02 production nodes). Downloaded SVGs contained Figma preview backgrounds (`#E5E5E5` / white rects); clean sources were rewritten with the **exact path geometry and stroke widths** and no backgrounds.
- `assets/menubar/status-{a,b}-{inactive,active}.svg` — `currentColor`; `.pdf` (vector, 22 pt, black → template) and `.png` / `@2x` / `@3x` generated from them.
- `assets/app-icon/source/` — `app-{a,b}-master.svg` (full-bleed), `app-{a,b}-foreground.svg` (for Icon Composer), `app-b-optical.svg`.
- `assets/app-icon/export/app-{a,b}-1024{,-fullbleed}.png`; `AppIcon.appiconset` (16/32 slots from B optical, ≥ 64 px from A; masked to 824 px rounded rect r = 185.4); `Lisdex.icns` via `iconutil`.
- Renderer: `scripts/render-svg.swift` (`NSImage(data:)` SVG decoding + CoreGraphics; `swiftc -O scripts/render-svg.swift -o .build/render-svg`). Phase 1 should wrap the full export (sizes, appiconset, `iconutil`) in `make icons`.
- Visual check: contact sheet on light (#ECECEC) and dark (#1E1E22) menu-bar backgrounds — both states distinguishable for A and B; app icon legible at 256/64/32/16 px.
