# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Settings → Apps: pick apps that keep your Mac awake while they are open. Keep Awake turns
  on when one opens and off when the last one quits, unless you started it yourself. The
  list starts empty.
- Settings → Schedule: give each day its own hours, e.g. a short Friday. When the hours differ,
  the menu shows a summary and an Edit Hours… button. Schedules from 1.1 carry over.

### Fixed

- Clicking the Keep Awake switch right after opening the menu no longer restarts the session.

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

[Unreleased]: https://github.com/pedrol2b/lisdex/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/pedrol2b/lisdex/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/pedrol2b/lisdex/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/pedrol2b/lisdex/releases/tag/v1.0.0
