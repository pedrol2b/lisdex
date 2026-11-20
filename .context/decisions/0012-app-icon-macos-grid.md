# 0012 — App icon on the macOS grid (Figma "Refinement 03"); menu bar icon 18 pt

- **Status:** Accepted (owner, 2026-11-19)
- **Date:** 2026-11-19
- **Amends:** 0003 (app icon export), 0011 (menu bar size)

## Context

- Owner noticed the app icon had no padding (About panel). Cause: the Figma masters are **full-bleed** (the whole 1024 square becomes the icon shape, as Icon Composer expects). The first export shrank only the *background* to Apple's 824 px rounded tile and left the artwork at full scale, so the molecule ran to the tile edges.
- The 16 pt menu bar fragment still looked small next to Amphetamine.

## Decision

- New Figma section **"Refinement 03 / macOS export"** (`7:205`) in the identity file (`sources/figma-identity.md`):
  - `app-a-macos / 1024 grid` (`7:207`) and `app-b-optical-macos / 1024 grid` (`7:217`): 1024 canvas, **824 px tile at 100 px margin, r = 185.4, corner smoothing 0.6**, containing an instance of the full-bleed master, centred on the glyph's visual centre. Owner asked for more padding twice: final scale **0.66 of the master for A (glyph ≈ 51% of the tile)** and **0.74 for B-optical (≈ 60%, legible at 16/32 px)**.
  - The four generated menu bar molecules (ADR 0011) as components, so the file mirrors what ships.
- `assets/app-icon/source/app-a-macos.svg` and `app-b-optical-macos.svg` are those Figma exports (only the board/page preview rects removed). `scripts/export-icons.sh` renders the icon set from them without extra masking: B-optical for 16/32 px, A for 64 px and up. The full-bleed masters stay for a future Icon Composer `.icon`.
- Menu bar molecules are **18 pt tall**, strokes **1.6 / 2.0 pt** (Amphetamine-like weight): B ≈ 34.3 × 18 pt (default), A ≈ 57.4 × 18 pt.
- **macOS scales status item images taller than ~18 pt down** (measured: a 20 pt image drew at 18 px tall on a 1× display), so 18 pt is the ceiling. Measured on the owner's bar: Amphetamine 31 × 15 px with a 15 px hexagon; Lisdex 38 × 18 px with a ~13 px hexagon (the α-NH₂ stub uses the top third). Owner chose to keep the standard drawing over a zig-zag-NH₂ variant (hexagon 15 pt, but 48 × 15 pt).
- About panel: copyright line is just "© 2026 Pedro Bueno" (`Support/Info.plist`); license, the name's meaning and the repo link are separate centred lines in the credits (`Sources/Lisdex/AboutPanel.swift`).

## Consequences

- App icon matches Apple's macOS grid; Finder/About/Spotlight show the intended padding.
- When the designer changes a master in Figma, the grid components update automatically (instances); re-export both SVGs and run `make icons`.

## Alternatives considered

- Fix only in code (scale the artwork in `render-svg`): works, but leaves Figma without a grid-compliant source. Owner asked for the Figma rework.
