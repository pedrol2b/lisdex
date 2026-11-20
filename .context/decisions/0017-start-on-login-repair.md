# ADR 0017 — Repair Start on Login after the app moves

- **Status:** Accepted
- **Date:** 2026-11-20
- **Amends:** 0006 (macOS stays the source of truth), 0008 (upgrade consequence)

## Context

`SMAppService.mainApp` registers the current bundle path. `brew upgrade` installs the app in
a new keg (`Cellar/lisdex/<version>/`), so the registration can point at a deleted bundle.

## Decision

- When the user switches Start on Login on in Lisdex, store the bundle path
  (`AppSettings.startOnLoginPath`). Clear it when they switch it off.
- At launch, re-register only if a path is stored, it differs from the current bundle path,
  and macOS doesn't report the item enabled (`LoginItemRepair.shouldReRegister`, tested).
- The toggle still shows the state read from macOS. If the user turns it off in System
  Settings without the app moving, Lisdex leaves it off.

## Consequences

Users who enabled Start on Login before this change have no stored path and won't be
repaired until they toggle it once.
