# ADR 0025 — Mode badge on the menu bar icon: static glyphs, badge = how the session ends

- **Status:** Accepted (owner approved spec `menu-bar-mode-badge.md`, 2026-11-24)
- **Date:** 2026-11-24

## Context

The owner drew badged menu bar icons in Figma (file `iOdc61NkCgOdETvPC2vnn8`, frame 33:1825,
component set 33:1492): pill, coffee mug and light bulb with an ∞, clock or calendar badge, in
the outlined and filled states. The badge is cut out of the base artwork with a 0.75 pt moat, so
it adapts to light, dark and highlighted menu bars. Many sessions don't follow the selected mode
(Option-click quick menu, `lisdex://on?minutes=`, Shortcuts, app and Focus sessions).

## Decision

- Optional: Settings → Appearance → "Show the mode on the icon", off by default
  (`AppSettings.showsModeBadge`; settings without the key read as off).
- The badge shows **how the current session ends** (approach A): a running session's badge comes
  from the session (app/Focus and until-stopped links → ∞, a link/action with minutes → clock,
  otherwise the selected mode); while off, the selected mode. `MenuBarBadge.resolve` (Core, tested).
- 18 static template glyphs in `assets/menubar/<variant>-<badge>-<state>.svg`, exported from the
  component set and rendered by `make icons` (ADR 0003). The pill keeps the shipped 20 × 18 pt
  artwork in every variant (Figma updated 2026-11-24), so turning badges on never changes the
  icon's width; mug and bulb stay 18 × 18.
- The menu's icon tile and the Settings icon picker stay unbadged; the jiggler never changes the
  icon. VoiceOver: "Lisdex — Keep Awake on, for a duration".

## Rejected

- Drawing the badge over the base icon at runtime: the moat is cut out of the base, and ADR 0003
  keeps menu bar art in SVG sources.
- Badge = selected mode always (approach B): a 15-minute quick-menu session would show ∞.

## Consequences

New badges or icon variants need SVGs for every state; `MenuBarAssetTests` fails if one is
missing, if a badged canvas differs from the plain one, or if art isn't black + alpha.
