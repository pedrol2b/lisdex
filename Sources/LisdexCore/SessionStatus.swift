import Foundation

/// The popover header: status pill, one line of detail, optional duration progress (0...1).
public struct SessionStatus: Equatable, Sendable {
  public enum Pill: String, Sendable {
    case inactive = "Inactive"
    case active = "Active"
    case waiting = "Waiting"
  }

  public let pill: Pill
  public let detail: String
  public let progress: Double?

  public init(pill: Pill, detail: String, progress: Double?) {
    self.pill = pill
    self.detail = detail
    self.progress = progress
  }

  public init(
    plan: SessionPlan, mode: KeepAwakeMode, session: Session?, schedule: Schedule, now: Date,
    calendar: Calendar, openApps: [String] = []
  ) {
    let clock = ClockText(calendar: calendar)
    switch (plan, session) {
    case (.holding, let session?) where session.origin == .focus:
      self.init(pill: .active, detail: "While a Focus is on.", progress: nil)
    case (.holding, let session?) where session.origin == .app:
      self.init(pill: .active, detail: Self.whileOpen(openApps), progress: nil)
    case (.holding(nil), let session?):
      let elapsed = now.timeIntervalSince(session.startedAt)
      let text = elapsed < 60 ? "less than a minute" : DurationText.short(elapsed)
      self.init(pill: .active, detail: "Awake for \(text).", progress: nil)
    case (.holding(let until?), let session?) where mode == .duration:
      let left = until.timeIntervalSince(now)
      let leftText =
        left < 60
        ? "\(Int(left.rounded(.up))) s" : DurationText.short((left / 60).rounded(.up) * 60)
      let total = until.timeIntervalSince(session.startedAt)
      let progress =
        total > 0 ? min(max(now.timeIntervalSince(session.startedAt) / total, 0), 1) : 1
      self.init(
        pill: .active, detail: "\(leftText) left · until \(clock.time(until))", progress: progress)
    case (.holding(let until?), _):
      let next = schedule.nextStart(after: until, calendar: calendar).map {
        " · next: \(clock.dayAndTime($0))"
      }
      self.init(pill: .active, detail: "Until \(clock.time(until))\(next ?? "")", progress: nil)
    case (.waiting(let next?), _):
      self.init(pill: .waiting, detail: "Waiting · next: \(clock.dayAndTime(next))", progress: nil)
    case (.waiting(nil), _):
      self.init(pill: .waiting, detail: "Pick at least one day.", progress: nil)
    default:
      self.init(pill: .inactive, detail: "Your Mac can sleep normally.", progress: nil)
    }
  }
}

extension SessionStatus {
  /// `openApps`: names of the running listed apps, in list order.
  fileprivate static func whileOpen(_ openApps: [String]) -> String {
    switch openApps.count {
    case 0: "While an app is open."
    case 1: "While \(openApps[0]) is open."
    default: "While \(openApps.count) apps are open."
    }
  }
}

/// "15 min", "1 h", "1 h 5 min" (minutes rounded down).
public enum DurationText {
  public static func short(_ interval: TimeInterval) -> String {
    let minutes = Int(interval / 60)
    let (hours, rest) = (minutes / 60, minutes % 60)
    switch (hours, rest) {
    case (0, _): return "\(rest) min"
    case (_, 0): return "\(hours) h"
    default: return "\(hours) h \(rest) min"
    }
  }

  /// Spelled-out form for VoiceOver: "1 hour", "1 hour 30 minutes", "45 minutes".
  public static func spoken(_ interval: TimeInterval) -> String {
    let minutes = Int(interval / 60)
    let (hours, rest) = (minutes / 60, minutes % 60)
    let parts = [
      hours > 0 ? plural(hours, "hour") : nil,
      rest > 0 || hours == 0 ? plural(rest, "minute") : nil,
    ]
    return parts.compactMap { $0 }.joined(separator: " ")
  }

  private static func plural(_ count: Int, _ unit: String) -> String {
    "\(count) \(unit)\(count == 1 ? "" : "s")"
  }
}

/// The duration chips in "For a Duration" mode.
public struct DurationPreset: Equatable, Sendable {
  public static let all = [15, 30, 60, 120].map { DurationPreset(seconds: TimeInterval($0 * 60)) }

  public let seconds: TimeInterval
  public var title: String { DurationText.short(seconds) }
}

/// Locale-aware clock formatting (`calendar.locale`, falling back to the current locale).
