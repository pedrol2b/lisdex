# 0009 — Horizontal, 16 pt-tall menu bar molecule

- **Status:** Superseded by 0011
- **Date:** 2026-11-19
- **Amends:** 0003 (status item size and layout)

## Context

On the owner's menu bar the Figma 22 × 22 pt status icon looked too small next to Amphetamine. The molecule only filled ~16 × 11 pt of the square canvas, with ~1 pt hairline strokes, and variant B runs diagonally, so it looked short and vertical.

## Decision

- Menu bar SVGs (`assets/menubar/status-*.svg`) keep the **original Figma path data** wrapped in `<g transform="rotate(θ)">` with a **tight viewBox** (stroke-inclusive bounding box), rendered **16 pt tall**:
  - **B (default): rotated 30° clockwise → 32.8 × 16 pt.** The ring sits left, the chain runs right, like a horizontal skeletal formula. Strokes ≈ 1.6 pt (inactive) / 2.1 pt (active).
  - **A: no rotation, cropped → 16.3 × 16 pt.** The lysine tail keeps it square at any angle.
- Inactive and active share **the same viewBox per variant** (the thicker active bounds), so the icon never shifts when toggled.
- `NSStatusItem` uses `variableLength`; `MenuBarImages` sizes each image to 16 pt height × its own aspect ratio.
- The 22 pt Figma-grid originals stay in `assets/menubar/figma-grid/` for reference. Rotation is a 2D rotation of the drawing only; connectivity is unchanged.
- `scripts/render-svg.swift` takes a height and keeps the SVG's aspect ratio (square outputs are byte-identical to before).

## Consequences

- The icon is now about as wide as Amphetamine's and readable at a glance.
- If the designer updates the Figma artwork, re-apply rotate + viewBox (or rework the Figma menu bar components at 16 pt height and wide format).

## Alternatives considered

- Keep 22 × 22 and only thicken strokes — still visually small and vertical.
- 20° rotation (29 × 16 pt) — reads less horizontally than 30°.
