# ADR 0027 — Menu redesign: status card, warning banners, mode list

- **Status:** Accepted (owner picked design B and approved the build, 2026-11-25)
- **Date:** 2026-11-25

## Context

After the Settings rework (ADR 0026) the owner asked for the same treatment of the popover, with
no strong opinions. The old popover repeated itself — "Lisdex" title, an Active pill and the Keep
Awake switch all said the same thing — kept the status line in the header away from the switch,
showed Start on Login (a set-once setting, also in Settings → General), and gave Settings, About
and Quit three full rows.

Compared in the browser against screenshots of the current menu (`.superpowers/brainstorm/`, not
committed):

- **A. Tidy** — same layout, status moved onto the switch row, header/pill/Start on Login removed,
  footer squeezed to one line. Safer.
- **B. Status card + mode list** (picked) — a card with a big headline and one wide On/Off
  button; modes as radio rows with their setting on the right.
- Footer: three rows (picked) vs one row of labelled buttons vs icon + word links. The owner
  found the squeezed footer ("Settings… ⌘," next to two bare icons) unclear.
- Warnings: a line inside the card (makes Keep Awake look broken) vs a banner under it (picked).

## Decision

- Layout and texts as in spec `lisdex-v1.md` "Menu (popover)".
- `SessionStatus` replaces `detail` with `caption` + `headline` (Core, tested); `pill` stays as
  the card's tint state. `Schedule.daysSummary` gives the mode row's short day list ("Mon–Fri").
- The Turn On / Turn Off button calls `switchOn`, so toggle sounds and sessions behave as the old
  switch did. Choosing a mode row never turns Keep Awake on.
- Banners use the accent (owner, 2026-11-25), not system orange; the ⚠ symbol and the wording mark
  them as warnings. The jiggler's Allow… first asks macOS to list Lisdex, then opens the pane.
- No icon in the card: the owner tried it without the menu bar glyph and found it cleaner
  (2026-11-25); the status item already shows it.
- Start on Login leaves the popover; its "waiting for approval" state becomes a banner.
- Removed: `ModePicker`, `ToggleRow`, `IconTile`, the header and status pill.

## Consequences

- With an orange or gold accent the banner and the active card share a colour; if banners get
  overlooked, the fallback is an orange ⚠ icon only.
- README popover screenshots retaken.
