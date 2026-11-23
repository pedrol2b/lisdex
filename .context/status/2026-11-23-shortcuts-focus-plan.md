# Shortcuts, Focus filter and lisdex:// Links Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lisdex can be driven from Focus modes and Shortcuts: `lisdex://` links in every build, native actions and a Focus filter in certificate-signed builds.

**Architecture:** Core gains `KeepAwakeCommand` (URL parsing) and focus sessions (`Session.Origin.focus`, `FocusRules`). The app routes links and App Intents to `AppModel.run(_:)` / `AppModel.focusChanged(keepsAwake:)`; intents reach the model through a main-actor bridge. `build-app.sh` adds App Intents metadata only when signing with a real identity.

**Tech Stack:** Swift 6 SwiftPM, AppIntents (macOS 14+), `xcrun appintentsmetadataprocessor`.

**Spec:** `.context/specs/shortcuts-focus.md`

## Global Constraints

- Core is Foundation-only with tests; app layer is I/O and UI. Swift 6.3 must compile it (`Bindable(model).x`, no method-reference `Binding`).
- Links accepted: `lisdex://on`, `lisdex://on?minutes=N` (1…1440), `lisdex://on?until=stopped`, `lisdex://off`, `lisdex://toggle`; anything else ignored and logged.
- Link/action turn-on = user session; Focus filter turn-on = focus session ending with the Focus; manual off wins until the next Focus start; battery cutoff comes first.
- Status line for a focus session: "While a Focus is on."
- Ad-hoc builds never carry `Metadata.appintents`; build script line when skipped: `Shortcuts actions: skipped (ad-hoc signature)` (or `… (appintentsmetadataprocessor not found)`).
- Don't push. Branch `feat/shortcuts-focus`.

## Review Focus

1. Focus ends while an app session or user session holds → nothing changes. → test in Task 2.
2. A link "on" while an app/focus session holds → becomes a user session (later Focus end / app quit leaves it on). → test in Task 2 (`Session` rule) + manual check Task 3.
3. Malformed links (`lisdex://on?minutes=0`, `minutes=abc`, `lisdex://sleep`, other scheme) → ignored. → test in Task 1.
4. Focus filter perform on deactivation arrives with the parameter unset → treated as "not keeping awake". → owner check (needs a Focus); code path in Task 3.
5. `make app` with no `CODESIGN_IDENTITY` → same bundle as today, no metadata. → check in Task 4.

---

### Task 1: `KeepAwakeCommand`

**Files:** Create `Sources/LisdexCore/KeepAwakeCommand.swift`; Test `Tests/LisdexCoreTests/KeepAwakeCommandTests.swift`.

**Interfaces — Produces:**
- `public enum TurnOnLength: Equatable, Sendable { case currentMode, untilStopped, minutes(Int) }`
- `public enum KeepAwakeCommand: Equatable, Sendable { case turnOn(TurnOnLength), turnOff, toggle; public init?(url: URL); public static let scheme = "lisdex"; public static let maxMinutes = 1440 }`

- [ ] **Step 1: Tests** — `on` → `.turnOn(.currentMode)`; `on?minutes=90` → `.minutes(90)`; `on?until=stopped` → `.untilStopped`; `off`, `toggle`; `LISDEX://ON` (case-insensitive scheme and host) → `.turnOn(.currentMode)`; nil for `on?minutes=0`, `on?minutes=1441`, `on?minutes=abc`, `on?until=later`, `lisdex://sleep`, `https://on`, `lisdex:` (no host).
- [ ] **Step 2: Run** `swift test --filter KeepAwakeCommandTests` → compile FAIL.
- [ ] **Step 3: Implement** with `URLComponents`.
- [ ] **Step 4: Run** `make test` → pass. **Step 5: Commit** `feat: lisdex:// link commands`

### Task 2: Focus sessions

**Files:** Modify `Sources/LisdexCore/SessionPlanner.swift`, `Sources/LisdexCore/SessionStatus.swift`; Create `Sources/LisdexCore/FocusRules.swift`; Tests `SessionPlannerTests`, `SessionStatusTests`, new `FocusRulesTests`.

**Interfaces — Produces:**
- `Session.Origin.focus`; `Session.startedByFocus(now:)`; `Session.isUsers: Bool` (`origin == .user`).
- Planner: any non-user session → `.holding(until: nil)`.
- `public enum FocusAction { case none, startFocusSession, endSession }`; `FocusRules.decide(keepsAwake: Bool, session: Session?, batteryCutoff: Bool = false) -> FocusAction`.
- Status: `(.holding, session?) where origin == .focus` → "While a Focus is on.".

- [ ] **Step 1: Tests** — `FocusRulesTests`: on + no session → start; on + below cutoff → none; on + any session (user/app/focus) → none; off + focus session → end; off + user session → none; off + app session → none; off + nil → none. Planner: focus session holds in every mode outside schedule windows. Status: "While a Focus is on.". `isUsers` true only for `.user`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4:** `make test` pass. **Step 5: Commit** `feat: focus sessions in core`

### Task 3: App wiring — links, intents, Focus filter

**Files:** Modify `Support/Info.plist` (`CFBundleURLTypes`: name `io.github.pedrol2b.lisdex`, scheme `lisdex`), `Sources/Lisdex/AppDelegate.swift` (`application(_:open:)`, set `IntentBridge.model`), `Sources/Lisdex/AppModel.swift`; Create `Sources/Lisdex/Intents/IntentBridge.swift`, `KeepAwakeIntents.swift`, `KeepAwakeFocusFilter.swift`.

**Interfaces:**
- Consumes: Task 1 `KeepAwakeCommand`, Task 2 `FocusRules`, `Session.startedByFocus`, `isUsers`.
- Produces: `AppModel.run(_ command: KeepAwakeCommand)` — `.turnOn(.currentMode)`: if off or not the user's session → `setOn(true, feedback: true)`; `.untilStopped` → `startIndefinitely()`; `.minutes(m)` → `startDuration(m * 60)`; `.turnOff` → `setOn(false, feedback: true)`; `.toggle` → `toggle()`. `AppModel.focusChanged(keepsAwake: Bool)` → `FocusRules.decide`, silent like the app trigger. `startIndefinitely` uses `!(session?.isUsers ?? false)` in place of `origin == .app`.
- `@MainActor enum IntentBridge { static weak var model: AppModel? }`; intents throw a user-facing error "Lisdex isn't ready yet." if nil.
- Intents: `TurnOnKeepAwakeIntent` (title "Turn Keep Awake On", `@Parameter(title: "Minutes") var minutes: Int?`, `inclusiveRange: (1, 1440)`; nil → `.untilStopped`), `TurnOffKeepAwakeIntent` ("Turn Keep Awake Off"), `IsKeepAwakeOnIntent` ("Is Keep Awake On?", `ReturnsValue<Bool>`). All `openAppWhenRun = false`, `@MainActor perform`.
- `KeepAwakeFocusFilter: SetFocusFilterIntent` — title "Keep Mac Awake"; `@Parameter(title: "Keep Mac awake") var keepAwake: Bool?` (no default, so an ended Focus arrives unset); `perform` → `focusChanged(keepsAwake: keepAwake ?? false)`; `displayRepresentation` "Keep Mac awake" / "Let Mac sleep".

- [ ] **Step 1:** Implement; `swift build` clean, `make lint` clean, `make test` pass.
- [ ] **Step 2: Verify links** (ad-hoc `make app`, relaunch): `open "lisdex://on?minutes=5"` → `pmset -g assertions` shows Lisdex, popover "For a Duration"; `open lisdex://off` → no assertion; `open "lisdex://on?minutes=0"` → log "Ignored link", nothing changes; `open lisdex://toggle` twice → on, off.
- [ ] **Step 3: Commit** `feat: lisdex:// links, Shortcuts actions and a Focus filter`

### Task 4: Build script metadata step

**Files:** Modify `scripts/build-app.sh`; Create `scripts/appintents-protocols.json`.

- [ ] **Step 1:** When `CODESIGN_IDENTITY` is set and the processor exists: build with `-Xswiftc -emit-const-values -Xswiftc -Xfrontend -Xswiftc -const-gather-protocols-file -Xswiftc -Xfrontend -Xswiftc <json>` (both `swift build` calls), collect `*.swiftconstvalues` newer than a marker file, write source/const lists to a temp dir, run `appintentsmetadataprocessor` (module Lisdex, platform macOS, deployment 14.0, triple `$(uname -m)-apple-macos14.0`, SDK from `xcrun --show-sdk-path`, Xcode build from `xcodebuild -version`) into `Contents/Resources` before signing. Otherwise print the skip line.
- [ ] **Step 2: Verify** `make app` → skip line, no `Metadata.appintents`. `CODESIGN_IDENTITY="<Apple Development id>" make app` → `Metadata.appintents/extract.actionsdata` lists `TurnOnKeepAwakeIntent`, `TurnOffKeepAwakeIntent`, `IsKeepAwakeOnIntent`, `KeepAwakeFocusFilter`; app launches; linkd log "Registered process". Rebuild ad-hoc afterwards.
- [ ] **Step 3: Commit** `build: App Intents metadata for certificate-signed builds`

### Task 5: Records

ADR 0022; `lisdex-v1.md` interactions; README "Shortcuts and Focus" section; CHANGELOG Added; `current.md` (Done + roadmap row); spec marked approved; evidence README. `make test` pass. Commit `docs: Shortcuts, Focus filter and links`.
