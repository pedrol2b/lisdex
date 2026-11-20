# 0003 — Molecule status icon: template images, two selectable variants

- **Status:** Accepted — menu bar artwork, size and default superseded by 0011 (app icon part still current)
- **Date:** 2026-11-19

## Context

Owner designed iteration 02 of the identity in Figma (`sources/figma-identity.md`): variant **A** (chemically faithful, includes lysine tail) and **B** (minimal fragment, recommended for the menu bar), each with inactive (outlined) and active (filled ring, heavier bonds) states, on a shared 22 pt grid. Owner wants the variant switchable in Settings.

## Decision

- SVG sources in `assets/menubar/` use `currentColor` (no backgrounds). Runtime uses the generated vector **PDFs** loaded as `NSImage` with `isTemplate = true`, size 22×22 pt. PNG @1x/2x/3x kept for docs/README.
- `MenuBarIconVariant` enum (`.minimal` = B default, `.faithful` = A) persisted in settings; the status item swaps images in place (same alignment rect).
- App icon: A artwork for ≥ 64 px, B-optical artwork for 16/32 px slots (designer recommendation), masked to the macOS 824 px rounded-rect grid → `assets/app-icon/Vyvanse.icns`. Full-bleed masters + foreground SVGs kept for a future Icon Composer `.icon`.
- Exports are regenerated from SVG; PNGs are never edited by hand.

## Consequences

- macOS tints icons for light/dark/tinted menu bars automatically; accent color does not apply to the status icon (intentional, HIG).
- Alternate *app* icons are not offered: an `LSUIElement` app has no Dock tile, so it would only affect Finder.

## Alternatives considered

- Colored (yellow) active icon — breaks template tinting and HIG; could be an opt-in later.
- SF Symbol custom symbol — more work, no real gain at a single size.
