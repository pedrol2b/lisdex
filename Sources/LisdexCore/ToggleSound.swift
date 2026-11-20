/// The sound played when the user switches Keep Awake on or off (ADR 0016). Each case is a
/// macOS system sound (`/System/Library/Sounds`), so nothing is bundled.
public enum ToggleSound: String, Codable, CaseIterable, Sendable {
  case pop, tink, glass, bottle, purr, morse

  public static let `default` = ToggleSound.pop

  /// The `NSSound` name, e.g. "Pop".
  public var systemName: String { rawValue.capitalized }

  public var title: String { systemName }
}

extension AppSettings {
  /// The sound to play for a user toggle, or `nil` when feedback sounds are off.
  public var feedbackSound: ToggleSound? { playsToggleSound ? toggleSound : nil }
}
