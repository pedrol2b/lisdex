/// The optional mode badge on the menu bar icon (spec menu-bar-mode-badge, ADR 0025): how the
/// current session ends — ∞ until stopped, a clock for a timed session, a calendar for a schedule.
public enum MenuBarBadge: String, CaseIterable, Sendable {
  case indefinitely
  case duration
  case schedule

  /// Approach A: a running session shows how it ends; while off, the selected mode shows what a
  /// click would start. App and Focus sessions hold until they end; a link or action with its
  /// own length beats the selected mode.
  public static func resolve(session: Session?, mode: KeepAwakeMode) -> MenuBarBadge {
    guard let session else { return MenuBarBadge(mode) }
    if !session.isUsers { return .indefinitely }
    if session.hasFixedLength { return session.deadline == nil ? .indefinitely : .duration }
    return MenuBarBadge(mode)
  }

  /// Appended to the status item's VoiceOver label.
  public var spokenName: String {
    switch self {
    case .indefinitely: "indefinitely"
    case .duration: "for a duration"
    case .schedule: "on a schedule"
    }
  }

  private init(_ mode: KeepAwakeMode) {
    switch mode {
    case .indefinitely: self = .indefinitely
    case .duration: self = .duration
    case .schedule: self = .schedule
    }
  }
}
