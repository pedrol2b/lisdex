import Foundation

/// A running Keep Awake session (the master switch is on). `nil` session = off.
public struct Session: Equatable, Sendable {
  /// Who started the session: the user, an app from Settings → Apps opening (spec app-trigger),
  /// or a Focus with Lisdex's Focus filter (spec shortcuts-focus).
  public enum Origin: Equatable, Sendable {
    case user
    case app
    case focus
  }

  public let startedAt: Date
  /// Wall-clock end for "For a Duration"; survives sleep because it is not a countdown.
  public let deadline: Date?
  public let origin: Origin
  /// A link or Shortcuts action set its own length (`deadline`, or none = until stopped), which
  /// beats the selected mode without changing it (spec shortcuts-focus, review fix).
  public let hasFixedLength: Bool

  public init(
    startedAt: Date, deadline: Date?, origin: Origin = .user, hasFixedLength: Bool = false
  ) {
    self.startedAt = startedAt
    self.deadline = deadline
    self.origin = origin
    self.hasFixedLength = hasFixedLength
  }

  /// A link or action with its own length: `minutes`, or until stopped when `nil`.
  public static func fixed(minutes: Int?, now: Date) -> Session {
    Session(
      startedAt: now, deadline: minutes.map { now.addingTimeInterval(TimeInterval($0) * 60) },
      hasFixedLength: true)
  }

  public static func start(mode: KeepAwakeMode, duration: TimeInterval, now: Date) -> Session {
    Session(startedAt: now, deadline: mode == .duration ? now.addingTimeInterval(duration) : nil)
  }

  /// A listed app opened: hold until it quits, whatever the mode.
  public static func startedByApp(now: Date) -> Session {
    Session(startedAt: now, deadline: nil, origin: .app)
  }

  /// A Focus with "Keep Mac awake" started: hold until it ends, whatever the mode.
  public static func startedByFocus(now: Date) -> Session {
    Session(startedAt: now, deadline: nil, origin: .focus)
  }

  /// The user started it (switch, shortcut, link, action); app and Focus sessions end on their own.
  public var isUsers: Bool { origin == .user }
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
    if !session.isUsers { return .holding(until: nil) }
    if session.hasFixedLength {
      guard let deadline = session.deadline else { return .holding(until: nil) }
      return now < deadline ? .holding(until: deadline) : .expired
    }
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
