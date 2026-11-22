# ADR 0015 — Pill icon direction (supersedes the icon parts of 0009–0012)

- **Status:** Accepted — assets landed 2026-11-20 (Figma node 10:254, exported as SVG)
- **Date:** 2026-11-20

## Context

The molecule doesn't read well at menu bar size, even after several rounds (ADR 0009–0012).

## Decision

- App icon and default menu bar icon become a **round pill**: outlined when inactive, filled
  when active.
- The alternative menu bar variant (Settings → Appearance) becomes a **coffee mug**,
  also outlined / filled. The app icon stays the pill whatever menu icon is chosen.
- Molecule Figma frames stay in the file, marked deprecated. Asset work is done in a separate
  session; this repo keeps the existing pipeline (`assets/` SVG → `make icons`, ADR 0003).

## Asset spec handed to the asset session

- **Menu bar** (template images, black + alpha only, `isTemplate`): SVG sources at
  18 × 18 pt (viewBox `0 0 18 18`), glyph ≈ 16 pt with ~1 pt optical padding, 1.5–2 pt
  strokes, pixel-aligned at 1x/2x. Four files: `pill-inactive`, `pill-active`,
  `mug-inactive`, `mug-active`. Exported as vector PDF + 1x/2x/3x PNG by `make icons`.
- **App icon**: 1024 × 1024 SVG master (full bleed) plus a macOS-grid version
  (824 × 824 rounded rect, 100 px margin, ~185 px corner radius), and a simplified
  "optical" version for 16/32 px. `make icons` builds the `.iconset` (16–512 @1x/@2x) and
  `Lisdex.icns`.

## Consequences

`MenuBarIconVariant` cases and the Appearance cards will be renamed when the assets land;
`iconVariant` decoding already falls back to the default for unknown values (ADR 0006),
so stored settings survive the rename.

## Implementation (2026-11-20)

- SVGs from the Figma components in `assets/menubar/{pill,mug}-{inactive,active}.svg` and
  `assets/app-icon/source/app-pill-{master,macos,optical-macos}.svg`; `make icons` renders the
  PDFs, PNGs, iconset and `Lisdex.icns` (optical pill for 16/32 px).
- `MenuBarIconVariant` is now `.pill` (default) / `.mug`; the retired `minimal`/`faithful`
  values decode to the pill (tested), other settings are kept.
- The Keep Awake tile in the popover shows the selected glyph.
- Molecule sources and exports moved to `assets/deprecated/molecule/` (no git history yet).

## Amendment (2026-11-22)

- The pill read small next to other menu bar glyphs. Its SVGs now use a **20 × 18 pt** canvas
  (viewBox `0 0 20 18`) with an 18 × 12 pt glyph (was 16 × 10 in 18 × 18), same 1.5 pt stroke,
  still pixel-aligned. Height stays 18 pt; width follows the artwork (`MenuBarImages`). The mug
  is unchanged.
- While Keep Awake is off the status item sets `appearsDisabled`, so the system dims the glyph.
