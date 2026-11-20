# ADR 0018 — Release pipeline

- **Status:** Accepted
- **Date:** 2026-11-20

## Decision

Pushing a tag `vX.Y.Z` runs `.github/workflows/release.yml`. The workflow can also be re-run
manually for an existing tag.

1. **verify (macOS):**
   - The tag must match `CFBundleShortVersionString`, and `CHANGELOG.md` must have a
     `[X.Y.Z]` section.
   - Runs `swift test`, then `make app` and `codesign --verify`.
2. **release:**
   - Creates a **draft** GitHub release titled "Lisdex X.Y.Z".
   - The notes are the CHANGELOG section plus the install commands.
   - No binaries are attached: an ad-hoc signed download would be quarantined
     (ADR 0005/0008).
   - A maintainer reviews the draft and publishes it.
3. **homebrew:**
   - Downloads `archive/refs/tags/vX.Y.Z.tar.gz`, authenticated so it also works while the
     repo is private.
   - Sets the formula's `url` and `sha256` in `pedrol2b/homebrew-tap` and pushes as
     `github-actions[bot]`.

The tap is written with an **SSH deploy key** (write access to `homebrew-tap` only), stored
as the `TAP_DEPLOY_KEY` Actions secret in `pedrol2b/lisdex`. This is narrower than a personal
access token. Setup: `.context/runbooks/release.md`.

## Consequences

- A release is three steps: bump the version and CHANGELOG, tag, then publish the draft.
- The formula is updated as soon as the tag passes verification, before the draft is
  published. The tag already exists, so `brew upgrade` works immediately.
