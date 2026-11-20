# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/pedrol2b/lisdex/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/pedrol2b/lisdex/releases/tag/v1.0.0
