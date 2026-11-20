# 0005 — Open source on GitHub, local-only builds (no App Store, no notarized releases)

- **Status:** Accepted (owner, 2026-11-19)
- **Date:** 2026-11-19
- **Supersedes:** 0004

## Context

The project is a non-commercial MIT open-source app. Owner does not want App Store distribution or paid signing; builds are local, as with Low Cortisol.

## Decision

- **MIT** license, public GitHub repository with the source.
- Users **build from source**: `make app` / `make install` produce an **ad-hoc signed** `Vyvanse.app` in `build/` and copy it to `~/Applications`. Locally built apps carry no quarantine flag, so Gatekeeper doesn't block them.
- No Developer ID, notarization, DMG, Homebrew cask or Sparkle for now. GitHub Releases, if used, are source tags + changelog only.
- CI (optional, later): GitHub Actions `swift test` on PRs.

## Consequences

- No Apple Developer account or secrets needed.
- Prebuilt binaries aren't offered; README must make "build from source" a 3-command path (Xcode CLT required).
- On managed Macs, MDM policy may still block locally built apps. We respect that, and the README says so.

## Alternatives considered

- Developer ID + notarized DMG + Homebrew (ADR 0004) — needs a paid account; revisit if people ask for binaries.
