import Foundation

/// Everything Lisdex persists (ADR 0006). Decoding tolerates missing keys and unknown enum
/// values, so new settings can be added without wiping a user's existing configuration.
/// Immutable: change it with `with(...)`, which returns a new value.
///
/// Keep Awake's on/off switch is deliberately not stored: Lisdex launches inactive.
public struct AppSettings: Codable, Equatable, Sendable {
  public static let `default` = AppSettings()

  /// The selected mode, kept while Keep Awake is off.
  public let mode: KeepAwakeMode
  public let engine: KeepAwakeEngine
  public let keepDisplayAwake: Bool
  public let iconVariant: MenuBarIconVariant
  /// Last chosen "For a Duration" length, in seconds (right-click restarts it).
  public let duration: TimeInterval
  public let schedule: Schedule
  /// Turn Keep Awake on when Lisdex launches (otherwise it always launches inactive).
  public let activateOnLaunch: Bool
  public let notifyOnSessionEnd: Bool
  /// On battery, let the display sleep even though the system is kept awake.
  public let allowDisplaySleepOnBattery: Bool
  public let batteryStopThreshold: BatteryThreshold
  public let accent: AccentChoice
  /// Play a short sound when the user switches Keep Awake on or off (like Amphetamine).
  public let playsToggleSound: Bool
  public let toggleSound: ToggleSound
  /// Which status-item click toggles Keep Awake (the other opens the popover).
  public let clickBehavior: StatusItemClickBehavior
  /// Global keyboard shortcuts (ADR 0019). None by default.
  public let shortcuts: ShortcutSettings
  /// Apps that keep the Mac awake while open (spec app-trigger). Empty by default.
  public let appTriggers: AppTriggers
  /// Bundle path where the user turned Start on Login on, `nil` when off (ADR 0017). macOS
  /// still owns the on/off truth; this only detects that the app moved since.
  public let startOnLoginPath: String?

  public init(
    mode: KeepAwakeMode = .indefinitely,
    engine: KeepAwakeEngine = .iokit,
    keepDisplayAwake: Bool = true,
    iconVariant: MenuBarIconVariant = .default,
    duration: TimeInterval = 3600,
    schedule: Schedule = .default,
    activateOnLaunch: Bool = false,
    notifyOnSessionEnd: Bool = true,
    allowDisplaySleepOnBattery: Bool = false,
    batteryStopThreshold: BatteryThreshold = .off,
    accent: AccentChoice = .default,
    playsToggleSound: Bool = true,
    toggleSound: ToggleSound = .default,
    clickBehavior: StatusItemClickBehavior = .default,
    shortcuts: ShortcutSettings = .default,
    appTriggers: AppTriggers = .empty,
    startOnLoginPath: String? = nil
  ) {
    self.mode = mode
    self.engine = engine
    self.keepDisplayAwake = keepDisplayAwake
    self.iconVariant = iconVariant
    self.duration = duration
    self.schedule = schedule
    self.activateOnLaunch = activateOnLaunch
    self.notifyOnSessionEnd = notifyOnSessionEnd
    self.allowDisplaySleepOnBattery = allowDisplaySleepOnBattery
    self.batteryStopThreshold = batteryStopThreshold
    self.accent = accent
    self.playsToggleSound = playsToggleSound
    self.toggleSound = toggleSound
    self.clickBehavior = clickBehavior
    self.shortcuts = shortcuts
    self.appTriggers = appTriggers
    self.startOnLoginPath = startOnLoginPath
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let fallback = AppSettings.default
    mode = (try? container.decodeIfPresent(KeepAwakeMode.self, forKey: .mode)) ?? fallback.mode
    engine =
      (try? container.decodeIfPresent(KeepAwakeEngine.self, forKey: .engine)) ?? fallback.engine
    keepDisplayAwake =
      try container.decodeIfPresent(Bool.self, forKey: .keepDisplayAwake)
      ?? fallback.keepDisplayAwake
    iconVariant =
      (try? container.decodeIfPresent(MenuBarIconVariant.self, forKey: .iconVariant))
      ?? fallback.iconVariant
    let duration =
      try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? fallback.duration
    self.duration = duration.isFinite && duration > 0 ? duration : fallback.duration
    schedule =
      (try? container.decodeIfPresent(Schedule.self, forKey: .schedule)) ?? fallback.schedule
    activateOnLaunch =
      try container.decodeIfPresent(Bool.self, forKey: .activateOnLaunch)
      ?? fallback.activateOnLaunch
    notifyOnSessionEnd =
      try container.decodeIfPresent(Bool.self, forKey: .notifyOnSessionEnd)
      ?? fallback.notifyOnSessionEnd
    allowDisplaySleepOnBattery =
      try container.decodeIfPresent(Bool.self, forKey: .allowDisplaySleepOnBattery)
      ?? fallback.allowDisplaySleepOnBattery
    batteryStopThreshold =
      (try? container.decodeIfPresent(BatteryThreshold.self, forKey: .batteryStopThreshold))
      ?? fallback.batteryStopThreshold
    accent = (try? container.decodeIfPresent(AccentChoice.self, forKey: .accent)) ?? fallback.accent
    playsToggleSound =
      try container.decodeIfPresent(Bool.self, forKey: .playsToggleSound)
      ?? fallback.playsToggleSound
    toggleSound =
      (try? container.decodeIfPresent(ToggleSound.self, forKey: .toggleSound))
      ?? fallback.toggleSound
    clickBehavior =
      (try? container.decodeIfPresent(StatusItemClickBehavior.self, forKey: .clickBehavior))
      ?? fallback.clickBehavior
    shortcuts =
      (try? container.decodeIfPresent(ShortcutSettings.self, forKey: .shortcuts))
      ?? fallback.shortcuts
    appTriggers =
      (try? container.decodeIfPresent(AppTriggers.self, forKey: .appTriggers))
      ?? fallback.appTriggers
    startOnLoginPath = try? container.decodeIfPresent(String.self, forKey: .startOnLoginPath)
  }

  /// A copy with the given fields replaced.
  public func with(
    mode: KeepAwakeMode? = nil,
    engine: KeepAwakeEngine? = nil,
    keepDisplayAwake: Bool? = nil,
    iconVariant: MenuBarIconVariant? = nil,
    duration: TimeInterval? = nil,
    schedule: Schedule? = nil,
    activateOnLaunch: Bool? = nil,
    notifyOnSessionEnd: Bool? = nil,
    allowDisplaySleepOnBattery: Bool? = nil,
    batteryStopThreshold: BatteryThreshold? = nil,
    accent: AccentChoice? = nil,
    playsToggleSound: Bool? = nil,
    toggleSound: ToggleSound? = nil,
    clickBehavior: StatusItemClickBehavior? = nil,
    shortcuts: ShortcutSettings? = nil,
    appTriggers: AppTriggers? = nil,
    startOnLoginPath: String?? = nil
  ) -> AppSettings {
    AppSettings(
      mode: mode ?? self.mode,
      engine: engine ?? self.engine,
      keepDisplayAwake: keepDisplayAwake ?? self.keepDisplayAwake,
      iconVariant: iconVariant ?? self.iconVariant,
      duration: duration ?? self.duration,
      schedule: schedule ?? self.schedule,
      activateOnLaunch: activateOnLaunch ?? self.activateOnLaunch,
      notifyOnSessionEnd: notifyOnSessionEnd ?? self.notifyOnSessionEnd,
      allowDisplaySleepOnBattery: allowDisplaySleepOnBattery ?? self.allowDisplaySleepOnBattery,
      batteryStopThreshold: batteryStopThreshold ?? self.batteryStopThreshold,
      accent: accent ?? self.accent,
      playsToggleSound: playsToggleSound ?? self.playsToggleSound,
      toggleSound: toggleSound ?? self.toggleSound,
      clickBehavior: clickBehavior ?? self.clickBehavior,
      shortcuts: shortcuts ?? self.shortcuts,
      appTriggers: appTriggers ?? self.appTriggers,
      startOnLoginPath: startOnLoginPath ?? self.startOnLoginPath
    )
  }
}
