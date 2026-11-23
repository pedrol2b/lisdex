# Lisdex v1 — product spec

_Drafted 2026-11-19. Status: **Accepted** (owner approved the menu, 2026-11-19)._

## Problem

Managed Macs often block installing apps (the owner's company laptop blocks Amphetamine from the App Store — so the owner built their own). Lisdex is a small, auditable, open-source menu bar app that does one thing: **prevent macOS from sleeping**, with three ways to control *when*.

## Principles

- One responsibility. Indefinitely / For a Duration / On a Schedule are just _modes_ of the same keep-awake behaviour.
- Native and quiet: no Dock icon (`LSUIElement`), template menu bar icon, dark rounded popover in the Low Cortisol style, yellow default accent.
- Simple by design: every feature must be explainable in one line in the menu.

## Interactions

| Input                         | Result                                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------- |
| Left-click status icon        | Open / close the popover (default), or toggle when Settings → General → Quick-Start a Session is "Left click" (v1.1). |
| Right-click / Control-click   | Toggle Keep Awake on/off **without changing the selected mode** (off pauses, on resumes) (default), or open the popover when swapped (v1.1). |
| Option + left-click (v1.1)    | Small native `NSMenu` of quick durations (15 m, 30 m, 1 h, 2 h, Until I stop).               |
| Global shortcuts (v1.1)       | Settings → Shortcuts: Toggle, Start Indefinitely, Start for a Duration (length on its row), Stop. None by default (ADR 0019). |
| `⌘,` in popover               | Settings window. `⌘Q` quits (releases the assertion first).                                 |

The toggle click (right-click by default) in **For a Duration** mode restarts the last chosen duration. Right-click in **On a Schedule** mode toggles the master switch; when on, the schedule decides whether the Mac is actually held awake.

## Status icon

- Inactive = outlined, active = filled with the detail knocked out (`assets/menubar/`, ADR 0015).
- Rendered as `NSImage` template (`isTemplate = true`), 18 × 18 pt, identical canvas for both states, so macOS tints it for light/dark/tinted menu bars.
- **Pill** (capsule, 16 × 10 pt glyph) is the default and matches the app icon. **Coffee mug** (16 × 14 pt) is selectable in Settings → Appearance → Menu bar icon. The app icon is always the pill.
- Accessibility label: "Lisdex — Keep Awake on/off".
- "Armed but idle" (schedule mode on, outside a window): inactive icon (v1). A dedicated third glyph is an open question.

## Menu (popover) — draft

~340 pt wide, dark material, 12 pt corner sections, SF Pro, accent = yellow by default. Rows use the Low Cortisol row component (icon tile · title · subtitle · trailing control).

### State 1 — Inactive

```
┌──────────────────────────────────────────┐
│ Lisdex                      ○ Inactive  │  header: name + status pill (grey)
│ Your Mac can sleep normally.             │
├──────────────────────────────────────────┤
│ [⬡] Keep Awake                     [ ○ ] │  master toggle
│     Prevent your Mac from sleeping.      │
├──────────────────────────────────────────┤
│ MODE                                     │
│ ┌────────────┬────────────┬────────────┐ │  segmented, 3 options
│ │ ∞ Indefin. │ ◷ Duration │ ▦ Schedule │ │  (selection kept while off)
│ └────────────┴────────────┴────────────┘ │
├──────────────────────────────────────────┤
│ [⌂] Start on Login                 [ ○ ] │
│     Launch Lisdex when you log in.      │
├──────────────────────────────────────────┤
│  ⚙  Settings…                        ⌘,  │
│  ⓘ  About Lisdex                     ›  │
│  ⏻  Quit Lisdex                     ⌘Q  │
└──────────────────────────────────────────┘
```

### State 2 — Active, Indefinitely

```
│ Lisdex                       ● Active   │  yellow pill
│ Awake for 1 h 12 min.                    │  elapsed since session start
├──────────────────────────────────────────┤
│ [⬢] Keep Awake                     [ ● ] │
│     Prevent your Mac from sleeping.      │
├──────────────────────────────────────────┤
│ MODE   [∞ Indefinitely]  Duration  Sched │
├──────────────────────────────────────────┤
│ … Start on Login / Settings / About / Quit
```

### State 3 — Active, For a Duration

```
│ Lisdex                       ● Active   │
│ 42 min left · until 12:30                │  countdown (updates every minute; seconds < 1 min)
├──────────────────────────────────────────┤
│ [⬢] Keep Awake                     [ ● ] │
├──────────────────────────────────────────┤
│ MODE   Indefinitely  [◷ Duration]  Sched │
│ ┌─────┬─────┬─────┬─────┬──────────────┐ │  duration chips, shown only in this mode
│ │15 m │30 m │[1 h]│ 2 h │ Custom…      │ │  picking a chip (re)starts the timer
│ └─────┴─────┴─────┴─────┴──────────────┘ │
│ ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▁▁▁▁▁▁▁▁▁▁▁▁▁▁  │  thin progress bar (accent)
├──────────────────────────────────────────┤
│ … Start on Login / Settings / About / Quit
```

When the timer ends: release the assertion, switch Keep Awake off, keep mode = Duration, optional notification ("Lisdex session ended").

### State 4 — Active, On a Schedule

```
│ Lisdex                ● Active · Sched. │  pill: "Active" inside a window,
│ Until 18:00 · next: Mon 09:00            │        "Waiting" (grey-yellow) outside
├──────────────────────────────────────────┤
│ [⬢] Keep Awake                     [ ● ] │
├──────────────────────────────────────────┤
│ MODE   Indefinitely  Duration  [▦ Sched] │
│ ┌──────────────────────────────────────┐ │  schedule card, shown only in this mode
│ │ ▦ Schedule                     Edit  │ │
│ │  M  T  W  T  F  S  S                 │ │  day pills (on = accent)
│ │  ●  ●  ●  ●  ●  ○  ○                 │ │
│ │  09:00 – 18:00                       │ │  v1: one window, same for selected days
│ └──────────────────────────────────────┘ │
├──────────────────────────────────────────┤
│ … Start on Login / Settings / About / Quit
```

Changes vs. the first AI mock (`sources/design-menu-draft-2026-11-19.md`): removed the separate _Quick Duration_ section (merged into Duration mode), schedule card only visible in schedule mode, Accent Color moved to Settings.

## Settings window (tabs)

- **General** — Start on Login · Activate Keep Awake when Lisdex launches · Notify when a timed session ends.
- **Power** — Keep the display awake (default **on**) · Allow display sleep on battery (default off) · Stop below battery % (off / 10 / 20 %) · **Keep-awake engine**: macOS power assertions (IOKit, recommended) / `caffeinate`, with the warning text from ADR 0002 shown when `caffeinate` is selected.
- **Appearance** — Menu bar icon variant (B Minimal / A Faithful, live preview of both states) · Accent color (yellow, orange, pink, purple, blue, mint, custom).
- **Schedule** — full editor (per-day windows in v1.1).

## About

Version + build, GitHub link, license (MIT), "Inspired by Amphetamine", disclaimer that the name and pill are a visual reference, not medical content.

## Out of scope (v1)

Closed-lid (clamshell without power) mode, prebuilt/notarized binaries (ADR 0005), per-app triggers ("keep awake while X runs"), download/CPU triggers, Shortcuts/AppIntents, App Store build. Candidates for v1.x.

## Acceptance criteria

1. With Keep Awake on (Indefinitely), `pmset -g assertions` lists a Lisdex assertion (`PreventUserIdleSystemSleep`, plus `PreventUserIdleDisplaySleep` when "Keep display awake" is on); off → none.
2. Right-click toggles on/off and never changes the selected mode.
3. Duration: assertion released within 1 s of expiry; survives sleep/wake (uses wall-clock deadline, not a monotonic countdown that pauses).
4. Schedule: entering/leaving a window takes effect within 30 s, including after wake and timezone/clock changes.
5. Quit, crash or `kill -9` never leaves the Mac held awake, with either engine (IOKit assertions die with the process; `caffeinate -w <pid>` exits with it).
10. Switching engine while active causes no sleep gap and leaves exactly one Lisdex-owned assertion set.
11. All preferences survive relaunch; old/corrupt `settings.v1` data falls back to defaults without crashing (ADR 0006).
6. Start on Login registers via `SMAppService.mainApp` and reflects the real status (incl. "requires approval").
7. Icon variant change in Settings updates the status item immediately and persists.
8. No Dock icon, no window on launch.
9. Core logic ≥ 80 % line coverage.
