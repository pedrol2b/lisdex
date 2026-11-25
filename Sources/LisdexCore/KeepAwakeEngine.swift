/// How Lisdex keeps the Mac awake (ADR 0002). IOKit is the default; `caffeinate` is opt-in.
public enum KeepAwakeEngine: String, Codable, CaseIterable, Sendable {
  /// macOS power assertions held inside the app; cleared by macOS if Lisdex quits or crashes.
  case iokit
  /// `/usr/bin/caffeinate` as a child process tied to Lisdex's pid.
  case caffeinate

  public var title: String {
    switch self {
    case .iokit: "Power assertions"
    case .caffeinate: "caffeinate"
    }
  }
}
