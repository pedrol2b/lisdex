# Shortcuts actions, Focus filter and lisdex:// links — Phase 8.3

_Approved by owner 2026-11-23 (Approach 2)._

## Intent

Drive Lisdex from Focus modes without touching it: Work Focus on → Mac stays awake; Focus off → it can sleep. Native Shortcuts actions and a Focus filter where the build allows them, `lisdex://` links for every build.

## Findings (spike, 2026-11-23)

- `swift build` with `-emit-const-values` + `xcrun appintentsmetadataprocessor` produces `Metadata.appintents`; macOS indexes it and the action shows up in Shortcuts.
- Running an action needs a **team-signed** app: ad-hoc signed → "LinkDaemon.ProcessRegistry.Errors error 0"; Apple Development certificate → `perform()` runs. A free Apple ID certificate is enough.
- LaunchServices won't index an app under `/private/tmp`; two registered bundles with the same ID confuse indexing (test from one place).

## Goals / non-goals / anti-goals

- Goals: Focus filter "Keep Mac awake"; actions Turn On / Turn Off / Is Keep Awake On?; `lisdex://` links for builds without a certificate; README section on both.
- Non-goals: Siri phrases (App Shortcuts) and localisation; per-Focus mode or duration; signing releases (ADR 0005 stands).
- Anti-goals: actions that show up but fail (ad-hoc builds must not ship the metadata); a link from a web page silently changing settings; breaking `make app` / Homebrew builds without Xcode.

## Approaches (owner picked 2, 2026-11-23)

1. Native only, when built with a certificate.
2. **Native when built with a certificate, plus `lisdex://` links for everyone (picked).**
3. Developer ID signing for releases — paid account, supersedes ADR 0005.

## Design

**Commands (Core, tested)** — `KeepAwakeCommand`: `.turnOn(TurnOnLength)`, `.turnOff`, `.toggle`, where `TurnOnLength` = `.untilStopped` / `.minutes(Int)` / `.currentMode`. `KeepAwakeCommand.init?(url: URL)`:
- `lisdex://on` → `.turnOn(.currentMode)`; `lisdex://on?minutes=90` → `.turnOn(.minutes(90))` (1…1440, else nil); `lisdex://on?until=stopped` → `.turnOn(.untilStopped)`; `lisdex://off`; `lisdex://toggle`. Anything else → nil (logged, ignored).
- Links only switch Keep Awake; they never change settings.

**Focus (Core, tested)** — `Session.Origin` gains `.focus`; the planner holds a focus session like an app session. `FocusRules.decide(focusKeepsAwake: Bool, session:, batteryCutoff:)`:
- filter on, Keep Awake off, not below the battery cutoff → start a focus session;
- filter off (Focus ended), session is a focus session → off;
- else nothing (a user or app session is never touched; manual off wins until the next Focus start).
- Status line: "While a Focus is on."

**App**
- `Support/Info.plist`: `CFBundleURLTypes` scheme `lisdex`; `AppDelegate` `application(_:open:)` → `AppModel.run(_ command:)` (same paths as the keyboard shortcuts: user sessions, toggle sound).
- `Sources/Lisdex/Intents/`: `TurnOnIntent` (parameter "For", optional minutes; none = until stopped), `TurnOffIntent`, `IsKeepAwakeOnIntent` (returns Bool), `KeepAwakeFocusFilter: SetFocusFilterIntent` (parameter "Keep Mac awake", default on). Intents call `AppModel` on the main actor; `openAppWhenRun = false`.
- `scripts/build-app.sh`: when `CODESIGN_IDENTITY` is set **and** `xcrun --find appintentsmetadataprocessor` succeeds → build with const-values flags and run the processor into `Contents/Resources`; otherwise skip with one line ("Shortcuts actions: skipped (ad-hoc signature)"). Ad-hoc builds never carry the metadata.
- README: "Shortcuts and Focus" section — links table for everyone; native actions need `CODESIGN_IDENTITY="Apple Development: …" make app`.

**Records** — ADR 0022 (team signing required for App Intents; links fallback); `lisdex-v1.md` interactions; CHANGELOG.

## Calls (mine — check these)

- A link or action turning Keep Awake on is a **user** session (deliberate), like a keyboard shortcut; a Focus filter starting it is a **focus** session (ends with the Focus).
- `lisdex://on` with no parameters uses the current mode (like the switch); "Turn On" action without minutes means until stopped.
- No confirmation for links: they only switch Keep Awake, the same as one click on the menu bar.

## Rollout

Branch `feat/shortcuts-focus`; owner tests with a certificate-signed `make app` (Focus filter in System Settings → Focus, a Shortcuts action, a link); merge locally, no push until Phase 9 is done.

## Left to the builder

File split, exact action titles/descriptions, logging, how the build script finds the const-values file.
