# 0008 — Homebrew: own tap with a build-from-source formula (no Apple Developer account)

- **Status:** Accepted (owner, 2026-11-19; implement in Phase 6)
- **Date:** 2026-11-19
- **Amends:** 0005 (which excluded Homebrew)

## Context

Owner wants Homebrew distribution without a paid Apple Developer account. The official `homebrew/cask` now requires casks to pass Gatekeeper (signed + notarized), and Homebrew removed `--no-quarantine` (4.7 / 5.0). Unsigned casks get disabled. So a **cask** that ships a prebuilt `.app` is not viable, whether official or in a personal tap: users would see "app is damaged".

## Decision

- Own tap repo `pedrol2b/homebrew-tap` with a **formula** `lisdex.rb` that downloads the tagged source tarball from `github.com/pedrol2b/lisdex`, builds with `swift build -c release` + `scripts/build-app.sh`, ad-hoc signs, and installs `Lisdex.app` into the keg (`prefix`).
- Because the app is built on the user's Mac it isn't quarantined, so Gatekeeper doesn't block it. No Apple account is needed.
- `caveats` tell users to run `ln -sf $(brew --prefix)/opt/lisdex/Lisdex.app ~/Applications/` (or a `lisdex-install` helper) so Spotlight and Login Items find it.
- Install: `brew install pedrol2b/tap/lisdex`. Requires Xcode Command Line Tools (Swift 6).
- `homebrew-core` isn't a target: it doesn't take GUI-app formulae of this kind and needs notability.

## Consequences

- Each release = tag + bump formula `url`/`sha256` (can be automated with a GitHub Action later).
- Builds take ~1 min on install; no bottles (prebuilt binaries would reintroduce quarantine/signing issues).
- Start on Login (`SMAppService.mainApp`) works from the keg path but breaks if the keg path changes on upgrade. The app re-registers on launch when enabled (Phase 4 must handle this).

## Alternatives considered

- Cask in own tap with an unsigned app — blocked by Gatekeeper; users would need `xattr -dr com.apple.quarantine`, not acceptable.
- Official cask — needs Developer ID + notarization (paid account).
