# ADR 0023 — Build with only the Command Line Tools

- **Status:** Accepted (owner picked option A, 2026-11-23)
- **Date:** 2026-11-23

## Context

ADR 0005 says Lisdex builds from source with the Command Line Tools (Homebrew users often have
no Xcode). Checked 2026-11-23 on CLT 27.2 (Swift 6.4.2):

- `libSwiftUIMacros.dylib` ships only inside Xcode. `@Entry` (used since v1.0) needs it, so
  CLT-only builds of v1.0 and v1.1 fail.
- In the macOS 27 SDK `@State` is a SwiftUI macro too. With the macOS 26.5 SDK it is not.
- The CLT ship several SDKs (here 26, 26.5, 27, 27.2).

Options: fall back to an older SDK in the build script; document "Xcode required on macOS 27";
both.

## Decision

- Replace `@Entry` with a hand-written `EnvironmentKey`. No SwiftUI macros in Lisdex's sources
  (`@Observable` is fine: its plugin ships with the CLT).
- `scripts/build-app.sh`: if `SDKROOT` is unset, the default SDK is macOS 27 or later, and
  `libSwiftUIMacros.dylib` is in neither the platform nor the toolchain plugin directory, use
  the newest `MacOSX26*.sdk` next to the default SDK and print a line saying so. If there is
  none, stop with a message to install Xcode.

## Consequences

- CLT-only builds work again; Xcode builds are unchanged.
- The app still targets macOS 14, so building against the 26 SDK loses nothing.
- When Apple ships the plugin with the CLT, the fallback switches itself off. If a future CLT
  drops the 26 SDK before that, the build stops with a clear message.
- Avoid new SwiftUI macros (`@Entry`, `#Preview`, `@Previewable`) in app sources.
