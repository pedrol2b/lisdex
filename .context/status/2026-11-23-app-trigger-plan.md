# App Trigger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Keep Awake turns on when an app from the user's list opens, and off when the last listed app quits — only if an app turned it on.

**Architecture:** A `Session` remembers who started it (`.user` / `.app`). The planner always holds an app session. The pure `AppTriggerRules` in Core turns workspace events into "start", "end" or "nothing". `AppWatcher` (NSWorkspace) feeds `AppModel`. A new Settings → Apps tab edits `AppSettings.appTriggers`.

**Tech Stack:** Swift 6, SwiftPM, Swift Testing, AppKit (`NSWorkspace`, `NSOpenPanel`), SwiftUI.

**Spec:** `.context/specs/app-trigger.md`

## Global Constraints

- The app list is empty by default. The user picks every app.
- Only a launch seen while Lisdex is running starts a session. Apps already open when Lisdex starts do nothing.
- Lisdex never ends a `.user` session because an app quit.
- Any deliberate user start (switch, mode change, duration chip, quick menu, shortcut) makes the session `.user`.
- The battery cutoff and display setting apply unchanged. App-driven on/off plays no sound and posts no notification.
- Popover detail is `While <Name> is open.` for one listed app running, `While <N> apps are open.` for more, and `While an app is open.` as a fallback.
- No permission prompt. No new dependency.
- Swift 6.3: use `Bindable(model).x` bindings and never `Binding(get:set:)`. Use `Log`, never `print`.
- Branch `feat/app-trigger` is not merged until the owner has tested it.

## Review Focus

1. Two listed apps open, one quits: Keep Awake stays on. Test in Task 3.
2. Duration mode with an app session: no deadline, so the planner must not return `.expired`. Test in Task 1.
3. The user switched off while VS Code runs, then VS Code quits: stays off. Then Xcode opens: turns on. Test in Task 3.
4. Quick menu "Indefinitely" while an app session runs in Indefinitely mode becomes a user session (today `startIndefinitely` does nothing when already on). Manual check in Task 5.
5. `appTriggers` JSON with garbage, duplicates or an empty bundle ID: bad entries are dropped and other settings kept. Test in Task 2.

---

### Task 1: Session origin and planner

**Files:**
- Modify: `Sources/LisdexCore/SessionPlanner.swift`
- Test: `Tests/LisdexCoreTests/SessionPlannerTests.swift`

**Interfaces:**
- Produces:
  - `Session.Origin` (`enum Origin: Equatable, Sendable { case user, app }`)
  - `Session.origin: Origin`
  - `Session.init(startedAt: Date, deadline: Date?, origin: Origin = .user)`
  - `static func Session.startedByApp(now: Date) -> Session` (deadline nil, origin `.app`)
  - `Session.start(mode:duration:now:)` is unchanged and returns `.user`.

- [ ] **Step 1: Write failing tests** in `SessionPlannerTests`:
  - `"an app session holds in every mode"`: for each of `[.indefinitely, .duration, .schedule]`, `plan(Session.startedByApp(now: monday10), mode, at: monday10) == .holding(until: nil)`. Use a schedule whose window excludes monday10 if the helper takes one, otherwise the default.
  - `"user sessions start with origin user"`: `Session.start(mode: .duration, duration: 1800, now: monday10).origin == .user` and `Session.startedByApp(now: monday10).origin == .app`.
- [ ] **Step 2:** Run `swift test --filter SessionPlanner`. Expected: compile FAIL (no `startedByApp`).
- [ ] **Step 3:** Implement. In `SessionPlanner.plan`, after `guard let session`, add `if session.origin == .app { return .holding(until: nil) }`.
- [ ] **Step 4:** Run `swift test --filter SessionPlanner`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: sessions remember whether an app started them`.

### Task 2: App list in settings

**Files:**
- Create: `Sources/LisdexCore/AppTriggers.swift`
- Modify: `Sources/LisdexCore/AppSettings.swift` (field, init param, `with`, CodingKeys, decoding)
- Test: `Tests/LisdexCoreTests/AppTriggersTests.swift`

**Interfaces:**
- Produces:
  - `struct AppTrigger: Codable, Hashable, Sendable { let bundleID: String; let name: String }`
  - `struct AppTriggers: Codable, Equatable, Sendable` with:
    - `static let empty`
    - `let apps: [AppTrigger]` (list order = insertion order)
    - `init(_ apps: [AppTrigger])`, which drops empty bundle IDs and duplicate bundle IDs (first one wins)
    - `func adding(_ app: AppTrigger) -> AppTriggers` (no-op if already listed)
    - `func removing(bundleID: String) -> AppTriggers`
    - `func contains(bundleID: String) -> Bool`
    - `var bundleIDs: Set<String>`
  - Encodes as a plain JSON array. Decoding is lossy per element: a bad element is skipped.
  - `AppSettings.appTriggers: AppTriggers` (default `.empty`) and `with(appTriggers:)`. A missing or garbage key decodes to `.empty`.

- [ ] **Step 1: Write failing tests** (`@Suite("AppTriggers")`):
  - `"empty by default"`: `AppSettings.default.appTriggers.apps.isEmpty`.
  - `"adding and removing return new lists; duplicates ignored"`: with `xcode = AppTrigger(bundleID: "com.apple.dt.Xcode", name: "Xcode")`, check `.empty.adding(xcode).adding(xcode).apps == [xcode]`, check `.removing(bundleID:)` gives an empty list, and check the original is still empty.
  - `"round-trips inside AppSettings"`.
  - `"garbage loads as empty, keeping the rest"`: `{"appTriggers":"x","accent":"mint"}` gives `appTriggers == .empty` and accent `.mint`. A v1.1 JSON with no key gives `.empty`.
  - `"bad, blank and duplicate entries are dropped"`: `{"appTriggers":[{"bundleID":"a","name":"A"},{"bundleID":5},{"bundleID":"","name":"B"},{"bundleID":"a","name":"A2"}]}` gives `apps == [AppTrigger(bundleID: "a", name: "A")]`.
- [ ] **Step 2:** Run `swift test --filter AppTriggers`. Expected: compile FAIL.
- [ ] **Step 3:** Implement. For the lossy decode, use an unkeyed container and loop with `try? decode(AppTrigger.self)`. On failure, skip the element by decoding a throwaway `Decodable` struct with an empty `init(from:)`.
- [ ] **Step 4:** Run `swift test`. Expected: all PASS.
- [ ] **Step 5:** Commit `feat: app list for the app trigger in settings`.

### Task 3: Trigger rules

**Files:**
- Create: `Sources/LisdexCore/AppTriggerRules.swift`
- Test: `Tests/LisdexCoreTests/AppTriggerRulesTests.swift`

**Interfaces:**
- Consumes: `Session.origin`, `AppTriggers`.
- Produces:
  - `enum AppTriggerEvent: Equatable, Sendable { case launched(bundleID: String); case runningChanged(running: Set<String>) }`. `runningChanged` is sent after an app quits and after the list is edited, carrying all running bundle IDs.
  - `enum AppTriggerAction: Equatable, Sendable { case none, startAppSession, endSession }`
  - `enum AppTriggerRules { static func decide(_ event: AppTriggerEvent, session: Session?, triggers: AppTriggers) -> AppTriggerAction }`
  - The rules:
    - `launched(id)` with `id` listed and `session == nil` gives `.startAppSession`.
    - `runningChanged(r)` with `session?.origin == .app` and `r ∩ triggers.bundleIDs` empty gives `.endSession`.
    - Everything else gives `.none`.

- [ ] **Step 1: Write failing tests** (`@Suite("AppTriggerRules")`, with Xcode and VS Code `com.microsoft.VSCode` listed):
  - `"a listed app opening turns Keep Awake on"`
  - `"an unlisted app opening does nothing"`
  - `"opening while already on does nothing"`, for both a user and an app session
  - `"the last listed app quitting ends an app session"`: `runningChanged(["com.other"])` gives `.endSession`
  - `"quitting one of two listed apps keeps it on"`: `runningChanged(["com.microsoft.VSCode"])` gives `.none`
  - `"a user session is never ended by apps"`
  - `"after a manual off, quitting does nothing and the next listed launch turns it on"`: session nil, `runningChanged([])` gives `.none`, and `launched(Xcode)` gives `.startAppSession`
  - `"removing the running app from the list ends the app session"`: triggers without Xcode, `runningChanged(["com.apple.dt.Xcode"])` gives `.endSession`
- [ ] **Step 2:** Run `swift test --filter AppTriggerRules`. Expected: compile FAIL.
- [ ] **Step 3:** Implement `decide`.
- [ ] **Step 4:** Run `swift test --filter AppTriggerRules`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: app trigger rules`.

### Task 4: Popover detail for app sessions

**Files:**
- Modify: `Sources/LisdexCore/SessionStatus.swift`
- Test: `Tests/LisdexCoreTests/SessionStatusTests.swift`

**Interfaces:**
- Produces: `SessionStatus.init(plan:mode:session:schedule:now:calendar:openApps: [String] = [])`. `openApps` holds the names of the running listed apps, in list order.

- [ ] **Step 1: Write failing tests:**
  - `"an app session names the app"`: `.holding(until: nil)` with an app session and `openApps ["Xcode"]` gives `SessionStatus(pill: .active, detail: "While Xcode is open.", progress: nil)`.
  - With two apps the detail is `"While 2 apps are open."`.
  - With an empty list the detail is `"While an app is open."`.
- [ ] **Step 2:** Run `swift test --filter SessionStatus`. Expected: FAIL.
- [ ] **Step 3:** Implement. Add a case before `(.holding(nil), let session?)` matching `session.origin == .app`.
- [ ] **Step 4:** Run `swift test`. Expected: all PASS.
- [ ] **Step 5:** Commit `feat: popover says which app keeps the Mac awake`.

### Task 5: Watch apps and wire AppModel

**Files:**
- Create: `Sources/Lisdex/System/AppWatcher.swift`
- Modify: `Sources/Lisdex/AppModel.swift`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces:
  - `@MainActor final class AppWatcher` with:
    - `init(onLaunch: @escaping @MainActor (String) -> Void, onRunningChange: @escaping @MainActor (Set<String>) -> Void)`
    - `static func runningBundleIDs() -> Set<String>`
    - Observes `NSWorkspace.didLaunchApplicationNotification` and `didTerminateApplicationNotification` on the workspace notification center (queue `.main`, `MainActor.assumeIsolated`). Reads the bundle ID from `NSWorkspace.applicationUserInfoKey`. Removes its observers in `deinit` (store tokens; use `isolated deinit` or `nonisolated(unsafe)` tokens, whichever compiles on 6.3).
  - In `AppModel`:
    - `private(set) var runningApps: Set<String>`, seeded from `AppWatcher.runningBundleIDs()` in `init`. It never triggers on its own.
    - `var openTriggerApps: [String]`: names of listed apps in `runningApps`, in list order.
    - `func addAppTrigger(_ app: AppTrigger)`
    - `func removeAppTrigger(bundleID: String)`. Both save, then `handle(.runningChanged(running: runningApps))`.
    - `private func handle(_ event: AppTriggerEvent)`. It switches over `AppTriggerRules.decide`:
      - `.startAppSession`: `session = .startedByApp(now: .now)`, then reconcile.
      - `.endSession`: `session = nil`, then reconcile.
      - Both log via `Log.app.notice`.
    - `status(at:)` passes `openApps: openTriggerApps`.
  - `startIndefinitely()`: after `setMode(.indefinitely)`, start the session when `!isOn || session?.origin == .app` (Review Focus 4).

- [ ] **Step 1:** Implement both files. Run `make app`. Expected: build succeeds with no new warnings.
- [ ] **Step 2: Manual check.**
  1. Quit the running Lisdex and open `build/Lisdex.app`.
  2. With `setkey.py`, set `appTriggers` to `[{"bundleID":"com.apple.TextEdit","name":"TextEdit"}]`, then relaunch Lisdex.
  3. Open TextEdit. Expected: the icon fills and the popover says "While TextEdit is open."
  4. Quit TextEdit. Expected: the icon goes back to outlined.
  5. Open TextEdit, switch off in the popover, then quit and reopen TextEdit. Expected: it turns on again.
  6. With TextEdit open, use the quick menu "Indefinitely", then quit TextEdit. Expected: it stays on.
  7. `pmset -g assertions` shows the Lisdex assertion only while it is held.
- [ ] **Step 3:** Run `swift test`. Expected: all PASS. Commit `feat: listed apps opening and quitting drive Keep Awake`.

### Task 6: Settings → Apps tab

**Files:**
- Create: `Sources/Lisdex/Settings/AppTriggerSettingsView.swift`
- Modify: `Sources/Lisdex/Settings/SettingsView.swift` (`SettingsTab.apps`, tab item `Label("Apps", systemImage: "app.badge")` after Shortcuts, header comment)

**Interfaces:**
- Consumes: `AppModel.addAppTrigger`, `removeAppTrigger(bundleID:)`, `settings.appTriggers`.
- Produces: `struct AppTriggerSettingsView: View { let model: AppModel }`.
  - A Form section titled "Keep awake while these apps are open". Each row shows the app icon (`NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` → `icon(forFile:)`, or the generic app icon if not found) and its name.
  - Rows are selectable. Below the list are `+` / `−` buttons.
  - `+` opens an `NSOpenPanel` with `allowedContentTypes = [.application]`, `directoryURL` /Applications and single selection. The bundle ID comes from `Bundle(url:)?.bundleIdentifier`, and the name from `FileManager.default.displayName(atPath:)` without `.app`. An app without a bundle ID logs and is not added.
  - When the list is empty, show the caption: "Add an app and Lisdex keeps your Mac awake while it's open."

- [ ] **Step 1:** Implement. Run `make app`. Expected: the build succeeds.
- [ ] **Step 2: Manual check.**
  1. Relaunch, open Settings → Apps. Expected: the empty state shows.
  2. Add TextEdit with +. Expected: the row shows the icon and name, and `settings.v1` contains it.
  3. Open TextEdit. Expected: Keep Awake turns on.
  4. Remove TextEdit with − while it is open. Expected: Keep Awake turns off.
  5. Take a screenshot of the tab in dark and light mode, with the accent applied, into `.context/evidence/2026-11-23-app-trigger/`.
- [ ] **Step 3:** Commit `feat: Settings → Apps tab to pick trigger apps`.

### Task 7: Records

**Files:**
- Create: `.context/decisions/0020-app-trigger.md`
- Create: `.context/evidence/2026-11-23-app-trigger/README.md`
- Modify:
  - `.context/specs/lisdex-v1.md` (interactions + Settings tabs)
  - `.context/status/current.md` (Phase 8.1 entry)
  - `CHANGELOG.md` ([Unreleased] → Added)
  - `README.md` (one feature line)

- [ ] **Step 1:** Write ADR 0020. Cover the context, the A/B/C options, the decision (an app flips the switch, with session origin) and the consequences (owner's rules 1–3, no trigger at Lisdex launch, empty list).
- [ ] **Step 2:** Update the other docs. Run `make lint && swift test`. Expected: clean, all PASS.
- [ ] **Step 3:** Commit `docs: app trigger ADR, spec and status`.
