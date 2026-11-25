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
| Option + either click (v1.1)  | Native menu "Keep Awake for…": 15 Minutes, 30 Minutes, 1 Hour, 2 Hours, Until I Stop, and Stop while on. A duration is remembered like a popover chip. |
| Global shortcuts (v1.1)       | Settings → Shortcuts: Toggle, Start Indefinitely, Start for a Duration (length on its row), Stop. None by default (ADR 0019). |
| Listed app opens (v1.2)       | Settings → Automation → Apps: when a listed app opens and Keep Awake is off, it turns on ("While Xcode is open."); when the last listed app quits it turns off, unless the user started it. Empty list by default (ADR 0020). |
| `lisdex://` link (v1.2)       | `on` (current mode), `on?minutes=N` (1–1440), `on?until=stopped`, `off`, `toggle`; anything else ignored. A user action, like a shortcut (ADR 0022). |
| Shortcuts / Focus (v1.2)      | Certificate-signed builds only: actions Turn Keep Awake On (minutes optional), Turn Keep Awake Off, Is Keep Awake On?; Focus filter "Keep Mac awake" holds while that Focus is on ("While a Focus is on.") (ADR 0022). |
| `⌘,` in popover               | Settings window. `⌘Q` quits (releases the assertion first).                                 |

The toggle click (right-click by default) in **For a Duration** mode restarts the last chosen duration. Right-click in **On a Schedule** mode toggles the master switch; when on, the schedule decides whether the Mac is actually held awake.

## Status icon

- Inactive = outlined, active = filled with the detail knocked out (`assets/menubar/`, ADR 0015).
- Rendered as `NSImage` template (`isTemplate = true`), 18 × 18 pt, identical canvas for both states, so macOS tints it for light/dark/tinted menu bars.
- **Pill** (capsule, 16 × 10 pt glyph) is the default and matches the app icon. **Coffee mug** (16 × 14 pt) and **Light bulb** (v1.1) are selectable in Settings → Appearance → Menu bar icon. An optional mode badge (∞ / clock / calendar, how the current session ends; off by default) is in the same section (ADR 0025, spec `menu-bar-mode-badge.md`). The app icon is always the pill.
- Accessibility label: "Lisdex — Keep Awake on/off".
- "Armed but idle" (schedule mode on, outside a window): inactive icon (v1). A dedicated third glyph is an open question.

## Menu (popover)

Redesigned by ADR 0027 (2026-11-25, design B). ~340 pt wide, dark material, accent = gold by
default. Top to bottom: status card · warning banners · mode list · footer.

```
┌──────────────────────────────────────────┐
│ ╭──────────────────────────────────────╮ │  status card, accent-tinted while on
│ │ Awake until 3:15 PM                  │ │  caption
│ │ 37 min left                          │ │  headline (large)
│ │ ▬▬▬▬▬▬▬▬────────────────             │ │  progress, timed sessions only
│ │ [            Turn Off              ] │ │  wide button = the Keep Awake switch
│ ╰──────────────────────────────────────╯ │
│ ╭ ⚠ Mouse jiggler is paused   [Allow…] ╮ │  banner per problem, accent-tinted
│ ╰   Lisdex needs Accessibility permission╯│
├──────────────────────────────────────────┤
│ ○ ∞ Indefinitely          until you stop │  radio rows; setting on the right
│ ● ◷ For a Duration                   1 h │
│   [15 min][30 min][ 1 h ][2 h][Custom…]  │  only the selected mode's controls
│ ○ ▦ On a Schedule                Mon–Fri │
├──────────────────────────────────────────┤
│  ⚙  Settings…                        ⌘,  │
│  ⓘ  About Lisdex                         │
│  ⏻  Quit Lisdex                     ⌘Q  │
└──────────────────────────────────────────┘
```

Card texts (`SessionStatus` caption / headline, Core, tested):

| Situation | Caption | Headline |
| --------- | ------- | -------- |
| Off | Keep Awake is off | Mac can sleep |
| On until stopped | Awake · until you stop | On for 1 h 12 min (Just started under a minute) |
| Timed (mode or a link/action with minutes) | Awake until 15:15 | 37 min left (45 s left in the last minute) + progress |
| Schedule, inside a window | Next: Tue 09:00 | Until 18:00 |
| Schedule, waiting | Schedule is on | Next: Tue 09:00 (Pick at least one day) |
| App / Focus session | Awake | While Xcode is open / While 2 apps are open / While a Focus is on |

- The card is tinted with the accent while holding, lighter while a schedule waits, plain when off.
- Banners: "Mouse jiggler is paused · Lisdex needs Accessibility permission · Allow…" (jiggler on,
  Keep Awake holding, permission missing) and "Start on login is waiting · Approve Lisdex in Login
  Items · Open…". Each disappears once fixed.
- Mode rows: Indefinitely "until you stop"; For a Duration the last length ("1 h"); On a Schedule
  the days that are on ("Mon–Fri", "Mon, Wed, Fri", "Every day", "No days"). Selecting a row
  never turns Keep Awake on. Duration chips start the timer; the schedule box has day pills plus
  one From–To, or the summary and Edit Hours… when days differ (opens Settings → Automation).
- Start on Login is in Settings → General only.

## Settings window (tabs)

Reorganised by ADR 0026 (2026-11-25): five tabs, one row pattern. Every group has a heading; labels are
sentence case; an explanation is one grey line under the row it explains, only where the effect
isn't obvious; a footer is only for a note about the whole group; no inline symbols in text.

- **General** — *Startup*: Start on login (+ approval row) · Turn on Keep Awake when Lisdex opens. *Menu bar icon*: Turn Keep Awake on or off with Right-click / Left-click (spec `click-behavior.md`). *Feedback*: Notify when a timed session ends · Play a sound when switched on or off · Sound.
- **Appearance** — *Menu bar icon*: pill / coffee mug / light bulb cards with both states · Show the session mode on the icon (ADR 0025). *Accent colour*: gold, orange, pink, purple, blue, mint, then a colour-wheel swatch that opens the system colour panel beside the window (custom colour, stored as `#RRGGBB`), then a hex field showing the current colour: a typed or pasted `#RRGGBB` applies at once, `#RGB` on Return; invalid text turns red and changes nothing; picking a colour elsewhere replaces the text and ends editing. A hex equal to a preset selects that preset.
- **Power** — *Display*: Keep the display awake (default **on**) · Except on battery (default off). *Battery*: Turn off below (off / 10 / 20 %). *Advanced*: Keep-awake engine — power assertions (IOKit, recommended) / `caffeinate`, with the ADR 0002 warning when `caffeinate` is selected.
- **Automation** — *Schedule*: day pills · Hours (one shared From–To) · Different hours per day (lists the days that are on, each with its own hours; ADR 0021). *Apps*: apps that keep the Mac awake while open; Add App… / ✕ (ADR 0020). *Chat apps*: mouse jiggler switch, Start after, Repeat every, Accessibility permission row (ADR 0024). The popover's "Edit Hours…" opens this tab.
- **Shortcuts** — *Global shortcuts*: one recorder per action, plus Duration under "Start for a duration" (ADR 0019).

## About

Standard macOS About panel (ADR 0028): icon, name, version + build, then the credits, one short
fact per line with no break inside a sentence:

```
Keeps your Mac awake.
GitHub · Report an issue · Sponsor        (repo · issues/new/choose · github.com/sponsors/pedrol2b)
Inspired by Amphetamine.
Named after lisdexamfetamine.
Not medical content.
MIT License
© 2026 Pedro Bueno                         (NSHumanReadableCopyright)
```

## Out of scope (v1)

Closed-lid (clamshell without power) mode, prebuilt/notarized binaries (ADR 0005), download/CPU triggers, App Store build. Candidates for v1.x. (Shortcuts actions and a Focus filter shipped in 1.2 for certificate-signed builds; ADR 0022.)

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
