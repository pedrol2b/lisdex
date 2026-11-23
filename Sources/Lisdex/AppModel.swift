import Foundation
import LisdexCore
import Observation

/// Single source of truth for the app layer. Views and the status item observe it.
///
/// Every change goes through `reconcile()`: settings are saved (ADR 0006), `SessionPlanner`
/// decides what to do now, `PowerCoordinator` holds or releases (ADR 0002), and `SessionClock`
/// is armed for the plan's next check.
@Observable
@MainActor
final class AppModel {
  private(set) var settings: AppSettings
  /// The running Keep Awake session; `nil` = Keep Awake off.
  private(set) var session: Session?
  /// The plan from the last reconcile. Stored (not computed) so the status icon re-renders
  /// when time alone changes it, e.g. a schedule window opening.
  private(set) var currentPlan = SessionPlan.off
  private(set) var powerSource = PowerSource.mains
  /// Start on Login, read back from macOS.
  private(set) var loginItem = LoginItem.state
  /// Settings → Shortcuts is capturing a combo: global hot keys are paused meanwhile.
  var isRecordingShortcut = false
  /// Shortcuts macOS refused to register because another app holds the combo.
  private(set) var shortcutsInUseElsewhere: Set<ShortcutAction> = []
  /// Bundle IDs of running apps, kept for the app trigger. Apps already open when Lisdex starts
  /// are recorded but never start a session (spec app-trigger).
  private(set) var runningApps: Set<String>

  @ObservationIgnored private let store: PreferencesStore
  @ObservationIgnored private let calendar: Calendar
  @ObservationIgnored private var coordinator: PowerCoordinator!
  @ObservationIgnored private var clock: SessionClock!
  @ObservationIgnored private var powerMonitor: PowerSourceMonitor!
  @ObservationIgnored private var appWatcher: AppWatcher!

  init(store: PreferencesStore = PreferencesStore(), calendar: Calendar = .autoupdatingCurrent) {
    self.store = store
    self.calendar = calendar
    let (settings, error) = store.loadSettings()
    if let error {
      Log.app.error(
        "Settings unreadable, using defaults: \(error.localizedDescription, privacy: .public)")
    }
    self.settings = settings
    self.runningApps = AppWatcher.runningBundleIDs()
    self.coordinator = PowerCoordinator { [weak self] request in
      try Self.acquire(request) { self?.engineGaveUp() }
    }
    self.clock = SessionClock { [weak self] in self?.reconcile() }
    self.powerMonitor = PowerSourceMonitor { [weak self] source in
      self?.powerSourceChanged(to: source)
    }
    self.powerSource = powerMonitor.current
    self.appWatcher = AppWatcher(
      onLaunch: { [weak self] bundleID in self?.appLaunched(bundleID) },
      onRunningChange: { [weak self] running in self?.runningAppsChanged(running) })
  }

  /// Called once the app has launched: repairs Start on Login after the app moved (ADR 0017),
  /// then honours "Activate Keep Awake when Lisdex launches".
  func start() {
    repairLoginItemIfMoved()
    if settings.activateOnLaunch { setOn(true) } else { reconcile() }
  }

  var isOn: Bool { session != nil }

  var state: KeepAwakeState { KeepAwakeState(isOn: isOn, mode: settings.mode) }

  var menuBarIcon: MenuBarIcon {
    MenuBarIcon(variant: settings.iconVariant, isActive: currentPlan.holdsAwake)
  }

  func plan(at now: Date) -> SessionPlan {
    SessionPlanner.plan(
      session: session, mode: settings.mode, schedule: settings.schedule, now: now,
      calendar: calendar)
  }

  func status(at now: Date) -> SessionStatus {
    SessionStatus(
      plan: plan(at: now), mode: settings.mode, session: session, schedule: settings.schedule,
      now: now,
      calendar: calendar, openApps: openTriggerApps)
  }

  /// Names of the listed apps running now, in list order (popover detail).
  var openTriggerApps: [String] {
    settings.appTriggers.apps.filter { runningApps.contains($0.bundleID) }.map(\.name)
  }

  // MARK: - Intents

  /// Right-click on the status item: flip on/off, keep the selected mode. In Duration mode
  /// switching on restarts the last chosen duration.
  func toggle() { setOn(!isOn, feedback: true) }

  /// The popover's Keep Awake switch: a user action, so it plays the toggle sound.
  /// SwiftUI can re-send the switch's current value (first click on a freshly opened popover);
  /// that must not restart the session, or an app session would quietly become the user's.
  func switchOn(_ isOn: Bool) {
    guard isOn != self.isOn else { return }
    setOn(isOn, feedback: true)
  }

  /// `feedback`: the user flipped the switch, so play the toggle sound once it took effect.
  /// Programmatic changes (expiry, battery cutoff, mode restarts) stay silent.
  func setOn(_ isOn: Bool, feedback: Bool = false) {
    let wasOn = self.isOn
    session =
      isOn ? Session.start(mode: settings.mode, duration: settings.duration, now: .now) : nil
    reconcile()
    if feedback, self.isOn == isOn, wasOn != isOn, let sound = settings.feedbackSound {
      SoundPlayer.play(sound)
    }
  }

  /// Changing mode while on starts a fresh session in the new mode.
  func setMode(_ mode: KeepAwakeMode) {
    guard mode != settings.mode else { return }
    update(settings.with(mode: mode))
    if isOn { setOn(true) } else { reconcile() }
  }

  /// A duration chip: remember it and (re)start the timer.
  func startDuration(_ seconds: TimeInterval) {
    update(settings.with(mode: .duration, duration: seconds))
    setOn(true, feedback: true)
  }

  func setSchedule(_ schedule: Schedule) {
    update(settings.with(schedule: schedule))
    reconcile()
  }

  func setIconVariant(_ variant: MenuBarIconVariant) { update(settings.with(iconVariant: variant)) }

  func setEngine(_ engine: KeepAwakeEngine) {
    update(settings.with(engine: engine))
    reconcile()
  }

  func setKeepDisplayAwake(_ keep: Bool) {
    update(settings.with(keepDisplayAwake: keep))
    reconcile()
  }

  func setActivateOnLaunch(_ on: Bool) { update(settings.with(activateOnLaunch: on)) }

  func setNotifyOnSessionEnd(_ on: Bool) { update(settings.with(notifyOnSessionEnd: on)) }

  func setAllowDisplaySleepOnBattery(_ allow: Bool) {
    update(settings.with(allowDisplaySleepOnBattery: allow))
    reconcile()
  }

  func setBatteryStopThreshold(_ threshold: BatteryThreshold) {
    update(settings.with(batteryStopThreshold: threshold))
    reconcile()
  }

  func setAccent(_ accent: AccentChoice) { update(settings.with(accent: accent)) }

  func setClickBehavior(_ behavior: StatusItemClickBehavior) {
    update(settings.with(clickBehavior: behavior))
  }

  func setPlaysToggleSound(_ on: Bool) {
    update(settings.with(playsToggleSound: on))
    if let sound = settings.feedbackSound { SoundPlayer.play(sound) }
  }

  /// Choosing a sound previews it.
  func setToggleSound(_ sound: ToggleSound) {
    update(settings.with(toggleSound: sound))
    SoundPlayer.play(sound)
  }

  // MARK: Keyboard shortcuts (ADR 0019)

  /// A global shortcut fired. Each action is a user action, so it plays the toggle sound.
  func perform(_ action: ShortcutAction) {
    Log.app.notice("Shortcut \(action.rawValue, privacy: .public)")
    switch action {
    case .toggle: toggle()
    case .startIndefinitely: startIndefinitely()
    case .startDuration: startDuration(settings.shortcuts.durationSeconds)
    case .stop: setOn(false, feedback: true)
    }
  }

  /// Switch to Indefinitely and turn on (shortcut, quick menu).
  func startIndefinitely() {
    setMode(.indefinitely)  // restarts the session if it was already on
    // Off, or on because an app or a Focus started it: start a session of the user's own.
    if !isOn || !(session?.isUsers ?? false) { setOn(true, feedback: true) }
  }

  // MARK: Links and Shortcuts actions (spec shortcuts-focus)

  /// A `lisdex://` link or a Shortcuts action: a user action, like a keyboard shortcut.
  func run(_ command: KeepAwakeCommand) {
    Log.app.notice("Command \(String(describing: command), privacy: .public)")
    switch command {
    case .turnOn(.currentMode):
      if !isOn || !(session?.isUsers ?? false) { setOn(true, feedback: true) }
    case .turnOn(.untilStopped): startIndefinitely()
    case .turnOn(.minutes(let minutes)): startDuration(TimeInterval(minutes) * 60)
    case .turnOff: setOn(false, feedback: true)
    case .toggle: toggle()
    }
  }

  /// Lisdex's Focus filter changed: a Focus with "Keep Mac awake" started (`true`) or the Focus
  /// ended (`false`). Programmatic like the app trigger: no sound, no notification.
  func focusChanged(keepsAwake: Bool) {
    let action = FocusRules.decide(
      keepsAwake: keepsAwake, session: session,
      batteryCutoff: BatteryCutoff.shouldStop(settings: settings, power: powerSource))
    switch action {
    case .none:
      return
    case .startFocusSession:
      Log.app.notice("A Focus started; Keep Awake on")
      session = .startedByFocus(now: .now)
    case .endSession:
      Log.app.notice("The Focus ended; Keep Awake off")
      session = nil
    }
    reconcile()
  }

  // MARK: App trigger (spec app-trigger)

  func addAppTrigger(_ app: AppTrigger) {
    update(settings.with(appTriggers: settings.appTriggers.adding(app)))
    handle(.runningChanged(running: runningApps))
  }

  func removeAppTrigger(bundleID: String) {
    update(settings.with(appTriggers: settings.appTriggers.removing(bundleID: bundleID)))
    handle(.runningChanged(running: runningApps))
  }

  private func appLaunched(_ bundleID: String) {
    runningApps.insert(bundleID)
    handle(.launched(bundleID: bundleID))
  }

  private func runningAppsChanged(_ running: Set<String>) {
    runningApps = running
    handle(.runningChanged(running: running))
  }

  /// App-driven on/off is programmatic: no toggle sound, no notification.
  private func handle(_ event: AppTriggerEvent) {
    let action = AppTriggerRules.decide(
      event, session: session, triggers: settings.appTriggers,
      batteryCutoff: BatteryCutoff.shouldStop(settings: settings, power: powerSource))
    switch action {
    case .none:
      return
    case .startAppSession:
      Log.app.notice("A listed app opened; Keep Awake on")
      session = .startedByApp(now: .now)
    case .endSession:
      Log.app.notice("No listed app open; Keep Awake off")
      session = nil
    }
    reconcile()
  }

  func setShortcut(_ combo: KeyCombo?, for action: ShortcutAction) {
    update(settings.with(shortcuts: settings.shortcuts.with(combo, for: action)))
  }

  func setShortcutDuration(_ seconds: TimeInterval) {
    update(settings.with(shortcuts: settings.shortcuts.with(durationSeconds: seconds)))
  }

  func reportUnavailableShortcuts(_ actions: Set<ShortcutAction>) {
    guard actions != shortcutsInUseElsewhere else { return }
    shortcutsInUseElsewhere = actions
  }

  func setStartOnLogin(_ enabled: Bool) {
    do {
      try LoginItem.set(enabled)
      update(settings.with(startOnLoginPath: .some(enabled ? Bundle.main.bundlePath : nil)))
    } catch {
      Log.app.error("Start on Login change failed: \(error.localizedDescription, privacy: .public)")
      Notifier.post(
        title: "Start on Login unchanged",
        body: "macOS refused the change. You can set it in System Settings → Login Items.")
    }
    refreshLoginItem()
  }

  /// Re-reads Start on Login (the user may have changed it in System Settings).
  func refreshLoginItem() { loginItem = LoginItem.state }

  private func repairLoginItemIfMoved() {
    let current = Bundle.main.bundlePath
    guard
      LoginItemRepair.shouldReRegister(
        savedPath: settings.startOnLoginPath, currentPath: current,
        isEnabled: LoginItem.state != .off)
    else { return }
    do {
      try LoginItem.set(true)
      update(settings.with(startOnLoginPath: .some(current)))
      Log.app.notice("Start on Login re-registered after the app moved")
    } catch {
      Log.app.error(
        "Start on Login repair failed: \(error.localizedDescription, privacy: .public)")
    }
    refreshLoginItem()
  }

  /// Called from `applicationWillTerminate`: release whatever is held.
  func shutdown() {
    session = nil
    currentPlan = .off
    clock.schedule(at: nil)
    try? coordinator.apply(nil)
  }

  // MARK: - Reconcile

  private func reconcile() {
    let now = Date.now
    var plan = plan(at: now)
    if plan == .expired {
      Log.app.notice("Duration ended; Keep Awake off")
      session = nil
      plan = .off
      if settings.notifyOnSessionEnd {
        Notifier.post(title: "Lisdex session ended", body: "Your Mac can sleep normally again.")
      }
    }
    if session != nil, BatteryCutoff.shouldStop(settings: settings, power: powerSource) {
      let level = powerSource.batteryPercent.map { "\($0) %" } ?? "low"
      Log.app.notice("Battery at \(level, privacy: .public); Keep Awake off")
      session = nil
      plan = .off
      Notifier.post(
        title: "Keep Awake stopped", body: "Battery is at \(level), so your Mac can sleep again.")
    }
    do {
      try coordinator.apply(PowerRequest(plan: plan, settings: settings, power: powerSource))
    } catch {
      Log.power.error("Keep Awake failed to start: \(String(describing: error), privacy: .public)")
      try? coordinator.apply(nil)
      session = nil
      plan = .off
      Notifier.post(
        title: "Keep Awake couldn't start",
        body: "macOS refused the request, so your Mac can sleep normally.")
    }
    currentPlan = plan
    clock.schedule(at: plan.nextCheck)
    Log.app.notice(
      "Plan \(String(describing: plan), privacy: .public), mode \(self.settings.mode.rawValue, privacy: .public), engine \(self.settings.engine.rawValue, privacy: .public)"
    )
  }

  private func update(_ next: AppSettings) {
    guard next != settings else { return }
    settings = next
    do {
      try store.save(next)
    } catch {
      Log.app.error("Settings not saved: \(error.localizedDescription, privacy: .public)")
    }
  }

  /// The engine supervising caffeinate gave up: reflect reality in the UI and say why.
  private func engineGaveUp() {
    Log.power.error("Keep Awake engine stopped; turning Keep Awake off")
    setOn(false)
    Notifier.post(
      title: "Keep Awake stopped", body: "caffeinate kept exiting, so your Mac can sleep normally.")
  }

  /// Battery level ticks every percent; only re-plan when the change can matter.
  private func powerSourceChanged(to source: PowerSource) {
    let previous = powerSource
    powerSource = source
    let matters =
      previous.isOnBattery != source.isOnBattery
      || (session != nil && settings.batteryStopThreshold != .off)
    if matters { reconcile() }
  }

  private static func acquire(
    _ request: PowerRequest, onGiveUp: @escaping @MainActor () -> Void
  ) throws -> any PowerHold {
    switch request.engine {
    case .iokit: try IOKitAssertion(request)
    case .caffeinate: try CaffeinateProcess(request, onGiveUp: onGiveUp)
    }
  }
}
