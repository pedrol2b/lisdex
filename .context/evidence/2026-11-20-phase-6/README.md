# Phase 6 — Homebrew formula and publish prep (2026-11-20)

## Formula (`pedrol2b/homebrew-tap/Formula/lisdex.rb`)

Tested from a throw-away local tap with a `file://` tarball of the working tree (the GitHub
repo is still private, so the real tag URL can't be fetched yet):

| Check | Result |
| --- | --- |
| `brew install --build-from-source` | Built in 17 s, `Cellar/lisdex/1.0.0`, 14 files, 2.1 MB |
| `brew test` | `Lisdex` executable, `pill-active.pdf` present, `codesign --verify` passes |
| `brew audit --strict` | Clean after shortening `desc` and using `assert_path_exists` |
| Signature / quarantine | `Signature=adhoc`, no `com.apple.quarantine` xattr |

`build-app.sh` now accepts `SWIFT_BUILD_FLAGS`; the formula passes `--disable-sandbox`
because SwiftPM's own sandbox can't nest inside Homebrew's.

**Pitfalls for the next formula test.** `HOMEBREW_NO_INSTALL_FROM_API=1` clones `homebrew/core`
(1.5 GB). `brew tap-new` switches on developer mode. `brew uninstall` autoremoves orphaned
dependencies (it removed the owner's `python@3.14`, which was reinstalled and re-marked as a
dependency). After the test the owner's tap list, developer mode and formulae matched the
state before it.

## Start on Login after upgrades (ADR 0017)

`AppSettings.startOnLoginPath` remembers where Start on Login was enabled. At launch,
`LoginItemRepair` re-registers only if the app moved and macOS no longer reports it enabled.

## Release checklist (when going public)

1. Push `main`, tag `v1.0.0`, create the GitHub release.
2. `curl -L https://github.com/pedrol2b/lisdex/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256`
   → set `sha256` in the formula, push the tap.
3. Make both repos public, then on a clean Mac: `brew install pedrol2b/tap/lisdex`.
4. README: add screenshots, remove the "in development" banner.

## Privacy scan

No secrets, tokens or local paths. The only personal data is the contact email in
`CODE_OF_CONDUCT.md`, which is intentional. `.context/sources/figma-identity.md` links the
Figma file.

## First CI run

The first push failed on Unit Tests and Build App: Swift 6.3.3 (Xcode 26.6 on `macos-latest`)
crashed in IRGen on the reabstraction thunk for `@MainActor` Bool setters passed to
`Binding(get:set:)` (`@isolated(any) @Sendable`). Local Swift 6.4.2 compiled the same code fine.
Reproduced locally with `DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/...`, fixed with
key-path bindings (`AppModel+Bindings.swift`), then verified on 6.3.3 (release build + 61 tests)
and 6.4.2. Sync Labels needed `contents: read` while the repo is private. All workflows green
on `main`.
