/// How Keep Awake decides *when* to hold the Mac awake. The selected mode is kept
/// while Keep Awake is off, so switching it back on resumes the same behaviour.
public enum KeepAwakeMode: String, Codable, CaseIterable, Sendable {
  case indefinitely
  case duration
  case schedule

  public var title: String {
    switch self {
    case .indefinitely: "Indefinitely"
    case .duration: "For a Duration"
    case .schedule: "On a Schedule"
    }
  }

  /// Base name of the 16 pt template PDF for the menu's mode row (`assets/modes/`, ADR 0029).
  public var symbolResourceName: String { "mode-\(rawValue)" }

  /// SF Symbol used when the bundled symbol is missing (`swift run` outside the .app).
  public var symbolName: String {
    switch self {
    case .indefinitely: "infinity"
    case .duration: "clock"
    case .schedule: "calendar"
    }
  }
}

/// The user's Keep Awake intent: the master switch plus the selected mode.
/// Immutable: every change returns a new value.
public struct KeepAwakeState: Codable, Equatable, Sendable {
  public let isOn: Bool
  public let mode: KeepAwakeMode

  public init(isOn: Bool = false, mode: KeepAwakeMode = .indefinitely) {
    self.isOn = isOn
    self.mode = mode
  }

  /// Right-click behaviour: flip on/off, keep the mode.
  public func toggled() -> KeepAwakeState {
    with(isOn: !isOn)
  }

  public func with(isOn: Bool) -> KeepAwakeState {
    KeepAwakeState(isOn: isOn, mode: mode)
  }

  public func with(mode: KeepAwakeMode) -> KeepAwakeState {
    KeepAwakeState(isOn: isOn, mode: mode)
  }
}
