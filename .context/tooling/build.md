# Build tooling

_Last updated 2026-11-19._

- **SwiftPM** only (tools 6.0, Swift 6 strict concurrency). **Swift Testing** for unit tests; `swift test --enable-code-coverage`.
- **App bundle:** `scripts/build-app.sh` (ADR 0001); version in `Support/Info.plist`.
- **Icons:** SVG → PDF/PNG/ICNS via a Swift export script + `iconutil` (see `evidence/2026-11-19-icon-export/`).
- **UI verification:** `agent-device` with `surface: menubar` snapshots the popover; right-click needs a posted CGEvent (same as Low Cortisol).
- **Power check:** `pmset -g assertions | grep -i lisdex`.
- **Formatting:** `swift format` (bundled with Swift 6), config `.swift-format` (defaults, 2-space indent like `.editorconfig`). Optional `lefthook.yml`: swift-format on staged files + conventional-commit check.
- **CI** (`.github/workflows/`, mirrors react-native-vision-camera-mlkit): `unit-tests.yml` (`swift test`), `build-app.yml` (`make app` + bundle/codesign checks), `swift-format.yml`, `sync-labels.yml` (from `.github/labels.yml`, filtered from the owner's labels gist + Lisdex areas), `stale.yml`. Actions pinned to SHAs. Unit tests and app build start passing once Phase 1 adds `Package.swift` / `Makefile`.
