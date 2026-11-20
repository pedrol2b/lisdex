/// What should be held right now to keep the Mac awake. `nil` (no request) means sleep normally.
public struct PowerRequest: Equatable, Sendable {
  public let engine: KeepAwakeEngine
  /// Also prevent idle display sleep, not only idle system sleep.
  public let keepsDisplayAwake: Bool
  /// Shown by `pmset -g assertions` (IOKit engine).
  public let reason: String

  public init(engine: KeepAwakeEngine, keepsDisplayAwake: Bool, reason: String) {
    self.engine = engine
    self.keepsDisplayAwake = keepsDisplayAwake
    self.reason = reason
  }

  /// The request implied by a plan; `nil` unless the plan holds the Mac awake.
  /// On battery, "Allow display sleep on battery" lets the display sleep.
  public init?(plan: SessionPlan, settings: AppSettings, power: PowerSource = .mains) {
    guard plan.holdsAwake else { return nil }
    let displaySleepAllowed = power.isOnBattery && settings.allowDisplaySleepOnBattery
    self.init(
      engine: settings.engine,
      keepsDisplayAwake: settings.keepDisplayAwake && !displaySleepAllowed,
      reason: "Lisdex: \(settings.mode.title)"
    )
  }

  /// `/usr/bin/caffeinate` arguments; `-w` makes it exit as soon as `pid` (Lisdex) exits.
  public func caffeinateArguments(watching pid: Int32) -> [String] {
    ["-i"] + (keepsDisplayAwake ? ["-d"] : []) + ["-w", String(pid)]
  }
}
