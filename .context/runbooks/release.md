# Release (local builds — ADR 0005)

_2026-11-19._

1. `make test`; bump `CFBundleShortVersionString` / `CFBundleVersion` in `Support/Info.plist`; update `CHANGELOG.md`.
2. `make install` → ad-hoc signed `build/Lisdex.app` copied to `~/Applications`; `codesign --verify build/Lisdex.app`.
3. Smoke test: toggle on → `pmset -g assertions | grep -i lisdex`; toggle off → gone; repeat with the caffeinate engine.
4. Tag `vX.Y.Z`, push; GitHub Release = changelog only (no binaries).
