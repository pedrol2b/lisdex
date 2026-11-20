/// Snapshot of where the Mac gets power from.
public struct PowerSource: Equatable, Sendable {
  /// Desktops and Macs on the charger report `false`.
  public let isOnBattery: Bool
  /// 0...100, or `nil` when there is no internal battery.
  public let batteryPercent: Int?

  public static let mains = PowerSource(isOnBattery: false, batteryPercent: nil)

  public init(isOnBattery: Bool, batteryPercent: Int?) {
    self.isOnBattery = isOnBattery
    self.batteryPercent = batteryPercent
  }
}

/// Settings → Power → "Stop below battery".
public enum BatteryThreshold: String, Codable, CaseIterable, Sendable {
  case off
  case below10
  case below20

  public var percent: Int? {
    switch self {
    case .off: nil
    case .below10: 10
    case .below20: 20
    }
  }

  public var title: String { percent.map { "\($0) %" } ?? "Off" }
}

/// Turns Keep Awake off when running on battery at or below the chosen threshold.
public enum BatteryCutoff {
  public static func shouldStop(settings: AppSettings, power: PowerSource) -> Bool {
    guard power.isOnBattery, let limit = settings.batteryStopThreshold.percent,
      let level = power.batteryPercent
    else { return false }
    return level <= limit
  }
}

/// Accent colour presets (Settings → Appearance). Stored by name; `rgb` is 0xRRGGBB.
public enum AccentChoice: String, Codable, CaseIterable, Sendable {
  case gold, orange, pink, purple, blue, mint

  public static let `default` = AccentChoice.gold

  public var rgb: UInt32 {
    switch self {
    case .gold: 0xF4C85B
    case .orange: 0xFF9F43
    case .pink: 0xFF6B9D
    case .purple: 0xA78BFA
    case .blue: 0x5AA9FF
    case .mint: 0x4FD1A5
    }
  }

  public var title: String { rawValue.capitalized }
}
