# Mode badge on the menu bar icon — Phase 11 (1.3.0)

_Approved by owner 2026-11-24 (approach A: the badge shows how the current session ends)._

## Intent

See the activation mode at a glance: an optional small badge on the menu bar icon — ∞
indefinitely, a clock for a timed session, a calendar for a schedule. Design: Figma file
`iOdc61NkCgOdETvPC2vnn8`, frame 33:1825 "The activation mode, at a glance." (component set
33:1492, 24 variants).

## Goals / non-goals / anti-goals

- Goals: Settings → Appearance switch, **off by default**; badged glyphs for pill, mug and bulb,
  outlined (off / not holding) and filled (holding), from the Figma artwork.
- Non-goals: badges in the menu's icon tile or the Settings icon picker; a badge for the jiggler
  (Figma: "Mouse jiggle does not change the icon"); new modes.
- Anti-goals: the icon changing width when badges are on (the pill keeps the shipped 20 × 18 pt
  artwork — Figma updated 2026-11-24); a badge that disagrees with what's keeping the Mac awake.

## Approaches

- **Static badged glyphs exported from Figma SVGs (picked; only sensible way).** Same pipeline as
  every menu bar icon (`assets/menubar/*.svg` → `make icons` → PDFs, ADR 0003).
- Drawing the badge over the base icon at runtime — rejected: the 0.75 pt moat is cut out of the
  base artwork, and ADR 0003 keeps menu bar art in SVG sources.

## Design

**Which badge (approach A).**

| Keep Awake | Badge |
| --- | --- |
| Off | the selected mode's badge (outlined icon) |
| On, app or Focus session | ∞ |
| On, a link/action with its own length | clock if it has minutes, ∞ if until stopped |
| On, user session, mode Indefinitely | ∞ |
| On, user session, mode Duration (incl. Option-click quick menu) | clock |
| On, user session, mode Schedule (inside or waiting outside a window) | calendar |

Filled vs outlined stays as today: filled while the plan holds the Mac awake.

**Core (Foundation only, tested).**
- `MenuBarBadge` enum `indefinitely`, `duration`, `schedule`;
  `MenuBarBadge.resolve(session: Session?, mode: KeepAwakeMode) -> MenuBarBadge` per the table.
- `AppSettings.showsModeBadge: Bool` (key `showsModeBadge`, default `false`, tolerant decoding,
  `with(showsModeBadge:)`).
- `MenuBarIcon` gains `badge: MenuBarBadge?`; `resourceName` = `pill-active` (no badge) or
  `pill-duration-active` style (`<variant>-<badge>-<state>`); `accessibilityLabel` adds the mode
  when badged ("Lisdex — Keep Awake on, for a duration").

**Assets.** Badge: 9 pt circle, top-right, 0.75 pt moat (7 pt was unreadable; owner 2026-11-24). 18 SVGs `assets/menubar/<pill|mug|bulb>-<indefinitely|duration|schedule>-<active|inactive>.svg`
exported from the component set (pill 20 × 18, mug and bulb 18 × 18), rendered by
`scripts/export-icons.sh`, copied by `build-app.sh`.

**App.** `AppModel.menuBarIcon` passes the resolved badge when `showsModeBadge` is on. Settings →
Appearance, under "Menu bar icon": switch "Show the mode on the icon", caption "A small ∞, clock or
calendar shows how the current session ends." Binding in `AppModel+Bindings.swift`.

**Records.** ADR 0025 (mode badge, approach A); CHANGELOG Unreleased; README feature row; Appearance
screenshot retaken; `current.md`.

## Calls (mine — check these)

- While off, the badge shows the selected mode, so you see what a click would start.
- A schedule waiting outside its window keeps the calendar badge on the outlined icon.
- The switch lives under the icon picker, not in General.

## Rollout

Branch `feat/mode-badge`; owner checks the icons in light and dark menu bars and each session kind
(menu, Option-click, `lisdex://on?minutes=1`, an app trigger); merge locally; ship as 1.3.0 when
the owner says.

## Left to the builder

File split, export details (Figma SVG export vs. hand-cleaned paths), caption wording polish.
