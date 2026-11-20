# 0004 — Distribution: MIT, Developer ID–signed + notarized DMG, Homebrew cask

- **Status:** Superseded by 0005
- **Date:** 2026-11-19

## Context

Goal is a public open-source release usable on stock Macs. Gatekeeper blocks unsigned apps downloaded from the internet; managed Macs may additionally block anything outside allow-lists — we must respect those policies, not bypass them.

## Decision

- License **MIT**. Public GitHub repo.
- Release artifact: universal (arm64 + x86_64) `Vyvanse.app` signed with **Developer ID Application** + hardened runtime, **notarized** with `notarytool`, stapled, shipped in a DMG/ZIP on GitHub Releases.
- Install paths: GitHub Releases download and a **Homebrew cask** (own tap first, `homebrew/cask` once notable).
- Updates: **Sparkle 2** (EdDSA-signed appcast on GitHub Pages) in v1.1; v1.0 just links to Releases.
- CI: GitHub Actions on `macos-latest` — `swift test` on PRs; tag `v*` → build, sign, notarize, release (secrets in GH Actions, never in repo).

## Consequences

- Requires an Apple Developer Program membership (US$99/yr) for signing/notarization.
- Building from source stays possible for anyone (`make app`, ad-hoc signed).

## Alternatives considered

- Mac App Store — sandbox is fine for IOKit assertions, but review friction, and the name/trademark question (see status) would surface there first.
- Unsigned releases — users must bypass Gatekeeper; not acceptable for a public tool.
