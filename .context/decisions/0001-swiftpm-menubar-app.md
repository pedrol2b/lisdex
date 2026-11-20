# 0001 — SwiftPM package + script-built .app, AppKit status item with SwiftUI popover

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

Same shape as the owner's Low Cortisol app: menu bar only, distinct left/right click, rich popover, fast unit tests, diff-friendly for agents and open-source contributors.

## Decision

- **Swift Package** (`Package.swift`, tools 6.0, Swift 6 mode) with `VyvanseCore` (Foundation only) + `Vyvanse` executable + `VyvanseCoreTests` (Swift Testing). No `.xcodeproj`.
- `scripts/build-app.sh` assembles `build/Vyvanse.app` with `Support/Info.plist` (`LSUIElement = true`, `CFBundleIconFile`) and signs it (ad-hoc locally, Developer ID in release — ADR 0004).
- **AppKit `NSStatusItem`** (not `MenuBarExtra`, which can't distinguish right-click) with a SwiftUI view in a `.transient` `NSPopover`.
- Minimum **macOS 14** (`@Observable`, `SMAppService`, SVG-capable `NSImage`).

## Consequences

- `swift build` is the only toolchain dependency; plain-text project.
- Asset catalog compilation (if ever needed) must be scripted (`actool`) — today we ship `.icns` + PDF templates instead.

## Alternatives considered

- Xcode project — merge-unfriendly `pbxproj`, no benefit for one target.
- SwiftUI `MenuBarExtra` — no right-click hook.
