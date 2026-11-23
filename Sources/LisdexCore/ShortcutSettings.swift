import Foundation

/// Global keyboard shortcuts (ADR 0019): at most one combo per action, plus the length the
/// "Start for a Duration" shortcut runs for. Stored by action name in `settings.v1`; decoding
/// drops a bad or unknown entry instead of losing the rest.
public struct ShortcutSettings: Codable, Equatable, Sendable {
  public static let `default` = ShortcutSettings()
  public static let defaultDuration: TimeInterval = 3600

  public let combos: [ShortcutAction: KeyCombo]
  public let durationSeconds: TimeInterval

  public init(
    combos: [ShortcutAction: KeyCombo] = [:],
    durationSeconds: TimeInterval = ShortcutSettings.defaultDuration
  ) {
    self.combos = combos
    self.durationSeconds =
      durationSeconds.isFinite && durationSeconds > 0 ? durationSeconds : Self.defaultDuration
  }

  /// A copy with `combo` assigned to `action` (`nil` clears it).
  public func with(_ combo: KeyCombo?, for action: ShortcutAction) -> ShortcutSettings {
    var next = combos
    next[action] = combo
    return ShortcutSettings(combos: next, durationSeconds: durationSeconds)
  }

  public func with(durationSeconds: TimeInterval) -> ShortcutSettings {
    ShortcutSettings(combos: combos, durationSeconds: durationSeconds)
  }

  private enum CodingKeys: String, CodingKey {
    case combos, durationSeconds
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let stored = try? container.nestedContainer(keyedBy: ShortcutAction.self, forKey: .combos)
    let pairs = ShortcutAction.allCases.compactMap { action in
      (try? stored?.decodeIfPresent(KeyCombo.self, forKey: action)).flatMap { $0 }
        .map { (action, $0) }
    }
    let duration = try? container.decodeIfPresent(TimeInterval.self, forKey: .durationSeconds)
    self.init(
      combos: Dictionary(uniqueKeysWithValues: pairs),
      durationSeconds: duration ?? Self.defaultDuration)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    var stored = container.nestedContainer(keyedBy: ShortcutAction.self, forKey: .combos)
    for (action, combo) in combos { try stored.encode(combo, forKey: action) }
    try container.encode(durationSeconds, forKey: .durationSeconds)
  }
}
