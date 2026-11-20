# Runbook — Releasing Lisdex

## One-time setup: tap deploy key (owner)

```sh
ssh-keygen -t ed25519 -N "" -C "lisdex-release-workflow" -f /tmp/lisdex-tap-key
gh repo deploy-key add /tmp/lisdex-tap-key.pub --repo pedrol2b/homebrew-tap --allow-write \
  --title "lisdex release workflow (writes Formula/lisdex.rb)"
gh secret set TAP_DEPLOY_KEY --repo pedrol2b/lisdex < /tmp/lisdex-tap-key
rm /tmp/lisdex-tap-key /tmp/lisdex-tap-key.pub
```

## Each release

1. `make test`, then a local smoke test with `make install`:
   - toggle Keep Awake on and check `pmset -g assertions | grep -i lisdex`;
   - toggle it off and check the assertion is gone;
   - repeat with the caffeinate engine.
2. `Support/Info.plist`: set `CFBundleShortVersionString` to `X.Y.Z` (bump `CFBundleVersion` too).
3. `CHANGELOG.md`: move `[Unreleased]` items under `## [X.Y.Z] - YYYY-MM-DD` and update the
   links at the bottom.
4. Commit, then `git tag -a vX.Y.Z -m "Lisdex X.Y.Z" && git push origin main vX.Y.Z`.
5. Watch **Actions → Release**. When it's green:
   - review and publish the draft release;
   - check the tap commit "lisdex X.Y.Z".
6. Smoke test: `brew update && brew upgrade lisdex` (or `brew install pedrol2b/tap/lisdex`).

To re-run for an existing tag: **Actions → Release → Run workflow** with the tag.
