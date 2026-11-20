# Phase 1 — skeleton — 2026-11-19

## Automated (passed)

- `make test`: 10 Swift Testing tests in 2 suites (`KeepAwakeState`, `MenuBarIcon`), written first (red), then implemented (green).
- `make lint`: `swift format lint --strict` clean on `Package.swift`, `Sources`, `Tests`, `scripts`.
- `swift build`: no warnings in Swift 6 language mode.
- `make app`: `build/Lisdex.app` contains `Lisdex.icns` + 4 status PDFs; `LSUIElement = true`; `codesign --verify` ok (ad-hoc).
- `make run`: process running, no Dock icon; outlined molecule (variant B, inactive) visible in the menu bar; `Lisdex launched` logged under `io.github.pedrol2b.lisdex`.
- `make icons`: PNG and ICNS exports are byte-identical across runs; the 4 PDFs differ only by their embedded creation timestamp.

## Not automatable here

- The agent's shell lacks Accessibility / post-event permission (`CGPreflightPostEventAccess() == false`), so synthetic clicks are dropped.
- `agent-device` refuses secondary clicks on the menu bar; its primary click showed the popover's menu item appear and disappear (the `.transient` popover closes when the helper takes focus).
- → Left-click popover and right-click toggle need a **manual owner check** (see `status/current.md`).

## Gotchas found

- `Logger.info` isn't persisted, so `log show` doesn't see it. State changes now log at `.notice`.
- In zsh, `log` is a builtin. Use `/usr/bin/log show --predicate 'subsystem == "io.github.pedrol2b.lisdex"'`.

## Owner check + icon resize (2026-11-19)

- Owner verified in the real menu bar: left-click popover, Keep Awake switch, mode picker and right-click toggle all work. The molecule tile follows the state.
- Feedback "icon too short vs Amphetamine" → ADR 0009. Candidates compared at 2× on a dark strip: current (≈16 × 11 visible), B 0° (23 × 16), B 20° (29 × 16), **B 30° (33 × 16, chosen)**, A cropped (16 × 16). Rebuilt app: horizontal molecule visible in the menu bar; both B states export at 66 × 32 px @2x (no shift on toggle).

## Faithful skeleton (ADR 0010)

- `scripts/lisdexamfetamine-skeleton.py` asserts 19 heavy atoms and all backbone angles = 120°. Candidates compared at 2× on a dark strip: faithful 14 pt (45 × 14), **16 pt (52 × 16, chosen)**, 16 pt with C=O double line (rejected: smudges at this size), rotated B (33 × 16).
- Rebuilt app: the full molecule is visible in the menu bar and matches the PubChem/Wikipedia horizontal depiction. Both states export at 104 × 32 px @2x.

## Fragment (ADR 0011)

- Concepts compared (menu bar at 2× + 256 px app icons): fragment 31 × 16, folded full 20 × 16, full horizontal 52 × 16; app icons: Figma A, fragment, folded. Owner chose the fragment for the menu bar and kept Figma A for the app icon.
- `scripts/lisdexamfetamine-skeleton.py` generates both variants: B 14 heavy atoms (30.70 × 16 pt), A 19 heavy atoms (51.48 × 16 pt), all angles 120°. Rebuilt app shows the fragment in the menu bar. Exports: B 61 × 32 px, A 103 × 32 px @2x, identical per state.

## App icon padding + 18 pt (ADR 0012)

- Figma: section `7:205` created via MCP; screenshot shows both grid icons with the designer's padding and the four menu bar components. Exported SVGs differ from the Figma export only by the two removed preview rects.
- `make icons`: icon set rendered from the grid sources. Contact sheet at 256/128/64/32/16 px shows padding at every size (B-optical at 16/32). Rebuilt app: 18 pt fragment in the menu bar. 10 tests pass, lint clean.

## Size match + more padding + About (2026-11-19)

- Pixel measurements from `screencapture` of the owner's 1× menu bar (flattened on black, 15% threshold): Amphetamine 31 × 15 px (hexagon 14 × 15); Lisdex 38 × 18 px (hexagon ~13). A 20 pt image rendered at 18 px, so the status bar caps image height. Stayed at 18 pt with 1.6 / 2.0 pt strokes.
- Figma `7:209` / `7:219` rescaled (A 0.66, B-optical 0.74, centred on the glyph's visual centre); re-exported and `make icons`; contact sheet shows clear padding at 256–16 px.
- About credits rebuilt as three centred lines; the panel itself needs the owner's click check (synthetic clicks are blocked for the agent).
