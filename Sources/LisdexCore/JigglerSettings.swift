import Foundation

/// The mouse jiggler (spec mouse-jiggler, ADR 0024): off by default because it needs the
/// Accessibility permission. After the user has been idle for `idleThreshold`, Lisdex posts a
/// 0 px mouse move every `interval` while Keep Awake holds. Values are clamped to the ranges the
/// Settings sliders offer; decoding falls back per key.
public struct JigglerSettings: Codable, Equatable, Sendable {
  public static let `default` = JigglerSettings()
  public static let defaultIdleThreshold: TimeInterval = 60
  public static let defaultInterval: TimeInterval = 20
  /// Teams goes Away after about 5 minutes, so the longest wait stays well below that.
  public static let idleThresholdRange: ClosedRange<TimeInterval> = 30...240
  public static let idleThresholdStep: TimeInterval = 30
  public static let intervalRange: ClosedRange<TimeInterval> = 10...60
  public static let intervalStep: TimeInterval = 5

  public let isEnabled: Bool
  public let idleThreshold: TimeInterval
  public let interval: TimeInterval

  public init(
    isEnabled: Bool = false,
    idleThreshold: TimeInterval = JigglerSettings.defaultIdleThreshold,
    interval: TimeInterval = JigglerSettings.defaultInterval
  ) {
    self.isEnabled = isEnabled
    self.idleThreshold = Self.clamp(
      idleThreshold, to: Self.idleThresholdRange, fallback: Self.defaultIdleThreshold)
    self.interval = Self.clamp(interval, to: Self.intervalRange, fallback: Self.defaultInterval)
  }

  public func with(
    isEnabled: Bool? = nil, idleThreshold: TimeInterval? = nil, interval: TimeInterval? = nil
  ) -> JigglerSettings {
    JigglerSettings(
      isEnabled: isEnabled ?? self.isEnabled,
      idleThreshold: idleThreshold ?? self.idleThreshold,
      interval: interval ?? self.interval)
  }

  /// Slider value text: "30 s", "1 min", "1 min 30 s".
  public static func label(seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded())
    let minutes = total / 60
    let rest = total % 60
    switch (minutes, rest) {
    case (0, _): return "\(rest) s"
    case (_, 0): return "\(minutes) min"
    default: return "\(minutes) min \(rest) s"
    }
  }

  private enum CodingKeys: String, CodingKey {
    case isEnabled, idleThreshold, interval
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      isEnabled: (try? container.decodeIfPresent(Bool.self, forKey: .isEnabled)) ?? false,
      idleThreshold: (try? container.decodeIfPresent(TimeInterval.self, forKey: .idleThreshold))
        ?? Self.defaultIdleThreshold,
      interval: (try? container.decodeIfPresent(TimeInterval.self, forKey: .interval))
        ?? Self.defaultInterval)
  }

  private static func clamp(
    _ value: TimeInterval, to range: ClosedRange<TimeInterval>, fallback: TimeInterval
  ) -> TimeInterval {
    guard value.isFinite else { return fallback }
    return min(max(value, range.lowerBound), range.upperBound)
  }
}
