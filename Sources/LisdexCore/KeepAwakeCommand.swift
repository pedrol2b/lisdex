import Foundation

/// How long a "turn on" from a link or Shortcuts action lasts.
public enum TurnOnLength: Equatable, Sendable {
  /// Whatever mode Lisdex is in, like the switch.
  case currentMode
  case untilStopped
  case minutes(Int)
}

/// What a `lisdex://` link or a Shortcuts action asks for (spec shortcuts-focus). Commands only
/// switch Keep Awake; they never change other settings.
public enum KeepAwakeCommand: Equatable, Sendable {
  case turnOn(TurnOnLength)
  case turnOff
  case toggle

  public static let scheme = "lisdex"
  public static let maxMinutes = 1440

  /// `lisdex://on`, `lisdex://on?minutes=90`, `lisdex://on?until=stopped`, `lisdex://off`,
  /// `lisdex://toggle`. Anything else → `nil`.
  public init?(url: URL) {
    guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
      parts.scheme?.lowercased() == Self.scheme,
      let host = parts.host?.lowercased()
    else { return nil }
    let query = Dictionary(
      (parts.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") }
    ) { first, _ in first }
    switch host {
    case "off": self = .turnOff
    case "toggle": self = .toggle
    case "on":
      guard let length = Self.length(query) else { return nil }
      self = .turnOn(length)
    default: return nil
    }
  }

  private static func length(_ query: [String: String]) -> TurnOnLength? {
    if let text = query["minutes"] {
      guard let minutes = Int(text), (1...maxMinutes).contains(minutes) else { return nil }
      return .minutes(minutes)
    }
    if let until = query["until"] {
      return until.lowercased() == "stopped" ? .untilStopped : nil
    }
    return .currentMode
  }
}
