# Current status

_Last updated 2026-11-22._

## Done

- 2026-11-23 **Phase 7.2 keyboard shortcuts** (owner tested and approved 2026-11-23; merged): Settings → Shortcuts tab, Carbon hot keys, recorder with validation. Core `KeyCombo`/`ShortcutSettings` + tests (80). Evidence `evidence/2026-11-23-keyboard-shortcuts/`.
- 2026-11-22 **Phase 7.1 click behavior**: Settings → General → Quick-Start a Session (right-click toggles by default, or left-click). Core `StatusItemClickBehavior` + tests (65). Spec `specs/click-behavior.md`, evidence `evidence/2026-11-22-click-behavior/`.
- 2026-11-22 Owner: post-1.0 roadmap split into Phase 7 (v1.1 controls), Phase 8 (v1.2 triggers), Phase 9 (v1.3 mouse jiggler). Keyboard shortcuts: one "Start for a duration" shortcut. Jiggler only while Keep Awake is on. (About showed 1.0.0 because the local `build/` app predated the version bump — rebuilt, not a bug.)
- 2026-11-19 Kickoff: `.context/` scaffold (mirrors Low Cortisol), spec + menu draft (`specs/lisdex-v1.md`), ADRs 0001–0004.
- 2026-11-19 Owner decisions: IOKit default + opt-in `caffeinate` engine with warning (ADR 0002 accepted); local-only builds, MIT on GitHub (ADR 0005 supersedes 0004); preferences as `settings.v1` JSON like Low Cortisol (ADR 0006); keep display awake by default.
- 2026-11-19 Name decided: **Lisdex** (short for lisdexamfetamine) — ADR 0007; docs and assets renamed.
- 2026-11-19 Bundle id `io.github.pedrol2b.lisdex`, repo `github.com/pedrol2b/lisdex` (to be created). Homebrew via own tap + source-build formula proposed (ADR 0008).
- 2026-11-19 Owner approved the menu (spec Accepted) and the Homebrew tap path (ADR 0008 Accepted). Project folder renamed to `lisdex`.
- 2026-11-19 `README.md` (origin story, name meaning, install via tap / source, why no signed binaries + call for contributions, Sponsor), `LICENSE` (MIT), `.github/FUNDING.yml`. README marks the app as in development; install commands go live at v1.0.
- 2026-11-19 Open-source scaffolding ported from react-native-vision-camera-mlkit and adapted: CODE_OF_CONDUCT (verbatim), CONTRIBUTING, SECURITY, CHANGELOG, LICENSE (Pedro Bueno), FUNDING (copied), issue templates (bug / build error / feature + config), `labels.yml` (owner's gist, minus platform/technology/irrelevant areas, + power/scheduling/menu bar/settings/distribution), workflows, `.editorconfig`, `.swift-format`, `lefthook.yml`, `.gitignore`. Homebrew: separate `pedrol2b/homebrew-tap` repo confirmed.
- 2026-11-19 Icon assets exported from Figma iteration 02 into `assets/` (menu bar A/B × inactive/active; app icon `.icns` + appiconset + masters). See `evidence/2026-11-19-icon-export/`.

- 2026-11-19 **Phase 1 skeleton** — SwiftPM package (`LisdexCore` + `Lisdex` + tests), `Support/Info.plist`, `scripts/build-app.sh`, `scripts/export-icons.sh` (`make icons`), `Makefile` (build/test/lint/format/app/run/install/icons). Status item shows the template molecule (variant B), left-click popover (header + status pill, Keep Awake switch with molecule tile, mode picker, About, Quit), right-click toggles and keeps the mode. No power assertion yet (Phase 2). See `evidence/2026-11-19-phase-1/`.

- 2026-11-19 Owner check of Phase 1: popover, Keep Awake switch, mode picker and right-click toggle work. Feedback: menu bar molecule too small → rotated/cropped 16 pt-tall horizontal icon (ADR 0009); variant B now 32.8 × 16 pt.
- 2026-11-19 Owner: the identity must match the molecule → default icon is now the full skeletal formula in the standard horizontal depiction (all 19 heavy atoms, generated from SMILES), 51.84 × 16 pt (ADR 0010). Compact rotated fragment kept as variant B.
- 2026-11-19 Owner: full skeleton too long → menu bar default is the standard-orientation fragment (ring → Cα, ≈ 31 × 16 pt), full molecule kept as an option; app icon stays Figma A (ADR 0011, supersedes 0009/0010).
- 2026-11-19 Owner: icon a bit small, app icon has no padding → menu bar 18 pt with bolder strokes (B 34.5 × 18 pt); app icon re-exported from new Figma macOS-grid components (Refinement 03, ADR 0012).
- 2026-11-19 Owner: match Amphetamine size, more app-icon padding, About text on separate lines → measured both icons (18 pt is the status bar ceiling; kept the standard drawing with 2 pt strokes), Figma tiles rescaled (A glyph ≈ 51% of tile), About credits split into lines (ADR 0012 updated).
- 2026-11-19 Owner confirmed the icons and About panel. **Phase 1 closed.**
- 2026-11-19 **Phase 2 code** — Core: `KeepAwakeEngine`, `AppSettings` (immutable, tolerant decoding), `PreferencesStore` (`settings.v1`), `PowerRequest`, `PowerCoordinator` (24 tests). App: `IOKitAssertion`, `CaffeinateProcess` (pid-tied, restart ×3 then off), `AppModel` persists settings and drives power; launches inactive. Leftover "Vyvanse" mentions in spec/ADRs/overview renamed. See `evidence/2026-11-19-phase-2/`.
- 2026-11-19 Phase 2 verified on the owner's Mac: IOKit assertions on/off, caffeinate child on/off, restart after kill, settings load from `settings.v1`. **Phase 2 closed.**
- 2026-11-19 **Phase 3 code** — Core: `Schedule` (+ `Weekday`, `TimeOfDay`, overnight windows), `Session`, `SessionPlanner`/`SessionPlan`, `SessionStatus` (header text, progress), `DurationPreset`; `AppSettings` gains `duration` and `schedule` (44 tests). App: `SessionClock` (one timer + wake/clock/time-zone/day observers), `AppModel.reconcile()`, live header, `DurationPanel` (15 min / 30 min / 1 h / 2 h / Custom, progress bar), inline `ScheduleCard`. ADR 0013.
- 2026-11-20 Owner checked the Duration and Schedule popovers (layout OK). Logs confirm the restart-before-release on mode switches and the schedule end at 18:00 local. **Phase 3 closed** (expiry timing in `evidence/2026-11-20-phase-3/`).
- 2026-11-20 Owner checked Settings / Start on Login / accents / variants: fine. **Phase 4 closed.** 60 s expiry ended within 0.2 s, assertions released. Core coverage 96 %.
- 2026-11-20 **Phase 5 hardening**: Swift review (no HIGH) + energy/VoiceOver audit; fixes and accepted items in `evidence/2026-11-20-phase-5/`. 51 tests, coverage 96 %.
- 2026-11-20 Owner confirmed the toggle sound plays and the popover opens/closes normally. **Phase 5 closed.**
- 2026-11-22 **v1.0.1**: menu bar icon dimmed while inactive (`appearsDisabled`), pill glyph enlarged to 18 × 12 pt on a 20 × 18 canvas (ADR 0015 amendment). Tagged; release workflow drafts the release and bumps the tap.
- 2026-11-20 **Public.** Both repos public; `TAP_DEPLOY_KEY` set; release workflow re-run for v1.0.0 all green; `brew install pedrol2b/tap/lisdex` from the public tap built 1.0.0 in 12 s and `brew test` passed. **Phase 6 closed.**
- 2026-11-20 **v1.0.0 release**: version 1.0.0, CHANGELOG, README screenshots (`make screenshots`, launch arg `-LisdexScreenshot`), banner removed, release pipeline (ADR 0018), repo descriptions/topics. Popover no longer focuses the first time field.
- 2026-11-20 **Phase 6 prep**: repos created (private). Formula in `~/Developer/public/homebrew-tap` passes install/test/audit from a local tap; Start on Login repair after upgrades (ADR 0017). 61 tests. See `evidence/2026-11-20-phase-6/`.
- 2026-11-20 Toggle sound (ADR 0016): user on/off plays a system sound (default Pop); Settings → General → Sound toggles it and picks Pop/Tink/Glass/Bottle/Purr/Morse. 56 tests.
- 2026-11-20 Pill + coffee-mug assets landed from Figma (node 10:254): SVGs in `assets/`, `make icons`, variants renamed `.pill`/`.mug` (old values fall back to the pill), molecule files in `assets/deprecated/molecule/`. 52 tests.
- 2026-11-20 Owner: icon direction changes to a pill (app + menu bar) with a coffee-mug menu bar variant; molecule deprecated (ADR 0015). Assets handled in a separate session.
- 2026-11-20 **Phase 4 code** — Core: `PowerSource`, `BatteryThreshold`, `BatteryCutoff`, `AccentChoice`; `AppSettings` gains activateOnLaunch / notifyOnSessionEnd / allowDisplaySleepOnBattery / batteryStopThreshold / accent (49 tests). App: Settings window (General / Power / Appearance), `LoginItem` (SMAppService), `Notifier`, `PowerSourceMonitor`, accent via environment, popover Start on Login + Settings… rows. ADR 0014.

## Roadmap

| Phase | Scope | Done when |
| ----- | ----- | --------- |
| **0. Design sign-off** ✅ | Menu (4 states) + settings layout approved 2026-11-19. | Spec status → Accepted. |
| **1. Skeleton** ✅ | SwiftPM package, `build-app.sh`, `Info.plist` (`LSUIElement`, icon), `Makefile`, status item with molecule icon, left-click popover / right-click toggle, `Log`. | `make run` shows icon, no Dock tile; icon flips on right-click. |
| **2. Keep-awake core** ✅ | `LisdexCore`: `AppSettings` + `PreferencesStore` (ADR 0006), `KeepAwakeMode`, `SessionPlanner` (pure: settings + now → hold?, until when). `KeepAwakeBackend` with IOKit + caffeinate engines (ADR 0002). Indefinite mode end-to-end. | `pmset -g assertions` check passes; Core tests green. |
| **3. Duration + Schedule** ✅ | Duration chips + custom, wall-clock deadline, expiry; schedule model (days + window), `Scheduler` tick (30 s) + wake/clock-change observers; schedule card + editor. | Acceptance 3–4 pass incl. sleep/wake. |
| **4. Settings & polish** ✅ | Settings window (General/Power/Appearance), icon variant switch, accent colors, Start on Login (`SMAppService`), notifications, battery threshold, About. Popover matches Low Cortisol style. | Acceptance 6–8; screenshots in evidence. |
| **5. Hardening** ✅ | Code review (swift-reviewer), concurrency audit, ≥ 80 % Core coverage, energy check (no busy timers), VoiceOver labels. | Review HIGHs fixed. |
| **6. Publish v1.0** ✅ | Public GitHub repo, README screenshots + remove "in development" banner, CONTRIBUTING, issue templates, optional `swift test` CI. Local ad-hoc builds (ADR 0005) + Homebrew tap formula building from source (ADR 0008). | A fresh clone builds with `make install`; `brew install pedrol2b/tap/lisdex` works on a clean Mac. |
| **7. v1.1 — controls** | Swap clicks setting (left toggles / right opens popover, or the reverse); global keyboard shortcuts in Settings (Toggle, Start indefinitely, Start for a duration — one, length picked on its row, Stop; none assigned by default); Option-click quick menu (15 m / 30 m / 1 h / 2 h / Until I stop); light bulb menu bar icon variant (Figma node 10:254, alongside pill and mug). | — |
| **8. v1.2 — triggers** | Keep awake while app X runs (app picker, `NSWorkspace` launch/quit); per-day schedule windows; Shortcuts / AppIntents (reuse the shortcut actions). | — |
| **9. v1.3 — mouse jiggler** | Nudge the cursor 2 px and back after an idle threshold (default 60 s), repeat every jiggle interval (default 20 s), stop on any real input incl. held keys/buttons. Runs **only while Keep Awake is holding**. Settings: idle threshold + jiggle interval sliders (no polling-interval setting: one timer computed from system idle time). Needs Accessibility (post-event) permission — new ADR; spike first: TCC grant across ad-hoc rebuilds / `brew upgrade`, and whether synthetic moves reset HID idle time. | — |

## Next

1. Phase 7 (v1.1), smallest first: ~~swap clicks~~ ✅ → ~~keyboard shortcuts~~ ✅ → Option-click quick menu → light bulb icon.
2. Phase 8 (v1.2): app-running trigger, per-day schedule windows, Shortcuts/AppIntents.
3. Phase 9 (v1.3): mouse jiggler (spike the permission + idle-time questions first).

## Open questions

- **Schedule mode, outside a window:** show a third "armed" icon state, or keep inactive icon? (v1: inactive.)
- **Start on Login vs. Activate on launch:** spec keeps them as two settings.

## Name discussion (2026-11-19)

"Vyvanse" (and "Elvanse") are Takeda trademarks. Non-commercial/MIT lowers the risk but doesn't remove it: trademark rights can be enforced against confusing non-commercial use, and GitHub acts on trademark complaints. Precedent: Apple flagged *Amphetamine* in 2021 for drug references (reversed after public pushback). Amphetamine uses a **generic** drug name, not a brand. The safer equivalent for us is the generic name: **Lisdex** (from lisdexamfetamine). It matches the molecule icon and has no notable GitHub/app conflicts (checked 2026-11-19). **Decided 2026-11-19: Lisdex** (ADR 0007).

## README / repo copy to keep

> Why does this exist? My company laptop blocks Amphetamine from the App Store, so I built my own.

> **Lisdex** is short for _lisdexamfetamine_, the molecule in the menu bar icon (PubChem CID 11597698).
