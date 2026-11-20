import Foundation

/// A running Keep Awake session (the master switch is on). `nil` session = off.
public struct Session: Equatable, Sendable {
  public let startedAt: Date
  /// Wall-clock end for "For a Duration"; survives sleep because it is not a countdown.
  public let deadline: Date?

  public init(startedAt: Date, deadline: Date?) {
    self.startedAt = startedAt
    self.deadline = deadline
  }

  public static func start(mode: KeepAwakeMode, duration: TimeInterval, now: Date) -> Session {
    Session(startedAt: now, deadline: mode == .duration ? now.addingTimeInterval(duration) : nil)
  }
}

/// What should happen right now.
public enum SessionPlan: Equatable, Sendable {
  /// Keep Awake is off.
  case off
  /// Hold the Mac awake until the given time (`nil` = until switched off).
  case holding(until: Date?)
  /// On a Schedule, outside a window; the next window starts at `next` (`nil` = never).
  case waiting(next: Date?)
  /// The duration ran out: switch Keep Awake off.
  case expired

  public var holdsAwake: Bool {
    if case .holding = self { return true }
    return false
  }

  /// When the plan has to be recomputed.
  public var nextCheck: Date? {
    switch self {
    case .holding(let until): until
    case .waiting(let next): next
    case .off, .expired: nil
    }
  }
}

/// Pure decision logic: session + mode + schedule + now → plan.
public enum SessionPlanner {
  public static func plan(
    session: Session?, mode: KeepAwakeMode, schedule: Schedule, now: Date, calendar: Calendar
  ) -> SessionPlan {
    guard let session else { return .off }
    switch mode {
    case .indefinitely:
      return .holding(until: nil)
    case .duration:
      guard let deadline = session.deadline, now < deadline else { return .expired }
      return .holding(until: deadline)
    case .schedule:
      if let window = schedule.window(containing: now, calendar: calendar) {
        return .holding(until: window.end)
      }
      return .waiting(next: schedule.nextStart(after: now, calendar: calendar))
    }
  }
}
