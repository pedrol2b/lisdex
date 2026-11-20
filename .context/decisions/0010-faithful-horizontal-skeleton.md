# 0010 — Default menu bar icon = full skeletal formula, standard horizontal depiction

- **Status:** Superseded by 0011 (full skeleton kept as the optional variant A)
- **Date:** 2026-11-19
- **Amends:** 0003, 0009 (default variant and variant A artwork)

## Context

ADR 0009 made the icon wider by rotating variant B 30°. Owner: better, but the identity must **match the molecule**. B is a fragment (no lysine chain), and a rotated drawing isn't how lisdexamfetamine is normally drawn. The usual reference depiction (PubChem / Wikipedia) is a horizontal zig-zag.

## Decision

- Variant **A (faithful) becomes the default** and is redrawn as the standard skeletal formula, generated from the SMILES `C[C@@H](Cc1ccccc1)NC(=O)[C@@H](N)CCCCN` by `scripts/lisdexamfetamine-skeleton.py`:
  - phenyl (pointy-top hexagon) → CH₂ → CH (methyl **down**) → NH → C (carbonyl O **down**) → Cα (NH₂ **up**) → (CH₂)₄ → NH₂;
  - **all 19 heavy atoms**, bond length 1, every backbone angle exactly 120° (the script asserts both);
  - heteroatom labels, stereo wedges, the C=O second line and the aromatic double bonds are omitted (unreadable at 16 pt, and the Figma identity omits them too).
- 16 pt tall → **51.84 × 16 pt**. Strokes 1.25 pt (inactive, outlined ring) / 1.6 pt (active, filled ring). Both states share the active frame.
- Variant **B (compact)** stays selectable: the rotated fragment from ADR 0009 (32.8 × 16 pt).
- The popover's Keep Awake tile always shows the compact molecule, because the 3.5:1 full formula is unreadable in a 30 pt square.
- The app icon (Figma A artwork) is unchanged.

## Consequences

- The menu bar shows the actual lisdexamfetamine structure, recognisable against the reference drawings.
- The status item is wider than Amphetamine's (~52 pt). Users who want it smaller can pick Compact in Settings (Phase 4).
- The SVG sources are generated: edit the script, not the SVG, for variant A.

## Alternatives considered

- 14 pt tall (45 pt wide): smaller, but thinner strokes. Owner preferred the bigger icon after ADR 0009.
- Rotated fragment as default (ADR 0009): not faithful to the molecule.
