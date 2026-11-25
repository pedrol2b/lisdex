# ADR 0029 — Menu bar icon family: Capsule, Molecule, Coffee (supersedes ADR 0015's icon set)

- **Status:** Accepted (owner approved the plan and the running build, 2026-11-25)
- **Date:** 2026-11-25

## Context

The owner redrew the menu bar icons in Figma (file `iOdc61NkCgOdETvPC2vnn8`, page `50:2093`
"Menu Bar Icons — Redesign", export frames) and asked for them in the app, plus an app-icon
switch in Settings (Figma has a capsule and a molecule app icon).

An app-icon switch can't reach Finder safely: Lisdex has no Dock tile, and writing a custom icon
into the bundle breaks the ad-hoc signature (and with it the Accessibility grant). The owner
chose to keep the Capsule as the only app icon.

## Decision

- Menu bar choices (Settings → Appearance → Menu bar icon): **Capsule** (default), **Molecule**,
  **Coffee**. The light bulb is retired; the old pill and mug artwork is removed.
- 24 SVGs from the Figma export frames in `assets/menubar/`:
  `{capsule,molecule,coffee}-{inactive,active}` and `<variant>-{indefinitely,duration,schedule}-<state>`.
  Canvases: capsule 18 × 18, coffee 20 × 18, molecule 32 × 18 pt (height 18, width follows the
  artwork). The Figma frame background rect and layer ids are stripped; files are black on
  transparent only. Template PDFs + PNGs via `make icons` (ADR 0003).
- Mode badges ship as drawn: the 9 pt overlay at the top-right (ADR 0025). The Figma handoff
  lists the overlay as an open trade-off; the 31 × 18 side-badge layout is the fallback if the
  owner finds it hard to read in the real menu bar.
- Saved choices carry over (`MenuBarIconVariant(storedName:)`): `pill` and `bulb` → Capsule,
  `mug` → Coffee. The retired `minimal`/`faithful` (old molecule names) and unknown values fall
  back to Capsule, not the new Molecule. New choices are saved under the new names.
- The menu's mode rows use the new 16 pt ∞ / clock / calendar symbols (`assets/modes/*.svg` →
  `mode-<mode>.pdf`, template), with the SF Symbols as fallback for the bare binary.
- App icon unchanged (capsule pill, ADR 0015).

## Consequences

- `MenuBarAssetTests` checks every variant × state × badge and every mode symbol has its files.
- Real menu bar crispness and badge legibility were the owner's runtime check (approved 2026-11-25).
- `assets/deprecated/molecule/` holds the old molecule (ADR 0009–0012); the new Molecule is a
  separate drawing.
