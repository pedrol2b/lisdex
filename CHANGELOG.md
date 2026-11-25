# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Molecule menu bar icon (Settings → Appearance).
- Settings → Appearance → Accent colour: a colour-wheel swatch picks any colour, and a hex field
  shows the current colour and takes a typed or pasted one.

### Changed

- New menu bar icons: Capsule (default), Molecule and Coffee, each with the mode badges. The light
  bulb is gone; a saved pill or light bulb becomes the Capsule and a saved coffee mug the Coffee.
- The menu's mode rows use new ∞, clock and calendar symbols.
- Settings reorganised into General, Appearance, Power, Automation and Shortcuts. Schedule, Apps
  and the chat-apps jiggler are now under Automation; every group has a heading and explanations
  sit under the setting they explain.
- Settings → Automation → Schedule: pick the days and one set of hours; turn on "Different hours
  per day" to set each day separately.

- The menu is redesigned: a status card says whether the Mac is awake and until when, with one
  Turn On / Turn Off button; the modes are a list showing each mode's setting; problems show as a
  banner with a button that fixes them. Start on Login moved to Settings → General.
- About Lisdex: a tagline, links to GitHub, issues and sponsoring, and short credits.

### Fixed

- Settings → Automation → Chat apps: granting Accessibility permission now shows up within a few
  seconds instead of only after relaunching Lisdex.

## [1.3.0] - 2026-11-24

### Added

- Settings → Appearance → Show the mode on the icon: a small ∞, clock or calendar on the menu bar
  icon shows how the current session ends. Off by default.

## [1.2.0] - 2026-11-24

### Added

- Settings → Apps: pick apps that keep your Mac awake while they are open. Keep Awake turns
  on when one opens and off when the last one quits, unless you started it yourself. The
  list starts empty.
- Settings → Schedule: give each day its own hours, e.g. a short Friday. When the hours differ,
  the menu shows a summary and an Edit Hours… button. Schedules from 1.1 carry over.
- `lisdex://` links (`on`, `on?minutes=90`, `on?until=stopped`, `off`, `toggle`) for Shortcuts
  automations, e.g. when a Focus turns on.
- Builds signed with a certificate (`CODESIGN_IDENTITY=… make app`) add Shortcuts actions (Turn
  Keep Awake On/Off, Is Keep Awake On?) and a Focus filter that keeps the Mac awake while a
  Focus is on.
- Settings → Power → Chat apps: an optional mouse jiggler keeps Teams and Slack from marking
  you Away while Keep Awake is on. After you've been idle (1 min by default) Lisdex posts a
  mouse move that doesn't move the cursor, every 20 s, until you touch the Mac. Off by
  default; needs the Accessibility permission.

### Fixed

- Clicking the Keep Awake switch right after opening the menu no longer restarts the session.
- Building with only the Command Line Tools (e.g. `brew install` without Xcode) works again: no
  more `@Entry` macro, and on macOS 27 the build falls back to the tools' macOS 26 SDK because
  their macOS 27 SDK needs a SwiftUI macro plugin that only Xcode ships.

## [1.1.0] - 2026-11-23

### Added

- Settings → General → Quick-Start a Session: choose whether right-click (default) or
  left-click toggles Keep Awake; the other click opens the menu.
- Global keyboard shortcuts in a new Settings → Shortcuts tab: Toggle Keep Awake, Start
  Indefinitely, Start for a Duration (length picked on its row) and Stop. None are set by
  default; combos macOS reserves or another app already holds are flagged.
- Option-click (either button) on the menu bar icon opens a quick menu: 15 Minutes,
  30 Minutes, 1 Hour, 2 Hours, Until I Stop, and Stop while Keep Awake is on.
- Light bulb menu bar icon, alongside the pill and the coffee mug (Settings → Appearance).

### Changed

- The shortcut field uses the accent colour chosen in Settings → Appearance.

## [1.0.1] - 2026-11-22

### Changed

- The menu bar icon is dimmed while Keep Awake is off.
- The menu bar pill icon is slightly larger (18 × 12 pt glyph, was 16 × 10).

## [1.0.0] - 2026-11-20

### Added

- Menu bar app with no Dock icon: left-click opens the menu, right-click toggles Keep Awake.
- Keep Awake modes: indefinitely, for a duration (15 min to 2 h or custom) and on a schedule
  (days + one time window, overnight allowed). Handles sleep/wake and clock or time zone changes.
- Two keep-awake engines: macOS power assertions (default) and `/usr/bin/caffeinate`,
  never left running after quit or crash.
- Settings window: start on login (repaired after the app moves), activate on launch,
  notifications, keep the display awake, display sleep and auto-stop on battery,
  toggle sound (Pop, Tink, Glass, Bottle, Purr, Morse), accent colours.
- Pill app icon and pill or coffee-mug menu bar icon (outlined when off, filled when on).
- VoiceOver labels for every control.
- Homebrew tap formula that builds from source: `brew install pedrol2b/tap/lisdex`.
- Open-source scaffolding: README, license, code of conduct, contributing guide, security
  policy, issue templates, labels and CI workflows (tests, format, build, release).

[Unreleased]: https://github.com/pedrol2b/lisdex/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/pedrol2b/lisdex/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/pedrol2b/lisdex/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/pedrol2b/lisdex/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/pedrol2b/lisdex/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/pedrol2b/lisdex/releases/tag/v1.0.0
