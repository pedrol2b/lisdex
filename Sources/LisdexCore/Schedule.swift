import Foundation

/// A day of the week. Raw values match `Calendar` weekday numbers (Sunday = 1).
public enum Weekday: Int, Codable, CaseIterable, Sendable {
  case sunday = 1
  case monday, tuesday, wednesday, thursday, friday, saturday

  /// Monday first, as in the schedule card.
  public static let displayOrder: [Weekday] = [
    .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
  ]

  public var letter: String {
    switch self {
    case .sunday, .saturday: "S"
    case .monday: "M"
    case .tuesday, .thursday: "T"
    case .wednesday: "W"
    case .friday: "F"
    }
  }
}

/// Wall-clock time within a day, stored as minutes since midnight (0...1439).
public struct TimeOfDay: Codable, Comparable, Hashable, Sendable {
  public static let minutesPerDay = 24 * 60

  public let minutes: Int

  public init(hour: Int, minute: Int) {
    self.minutes = min(max(hour * 60 + minute, 0), Self.minutesPerDay - 1)
  }

  public var hour: Int { minutes / 60 }
  public var minute: Int { minutes % 60 }

  public init(from decoder: Decoder) throws {
    let minutes = try decoder.singleValueContainer().decode(Int.self)
    guard (0..<Self.minutesPerDay).contains(minutes) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "minutes out of range: \(minutes)"))
    }
    self.minutes = minutes
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(minutes)
  }

  public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool { lhs.minutes < rhs.minutes }
}

/// When "On a Schedule" holds the Mac awake: one window, the same on every selected day (v1).
/// A window whose end is before its start runs overnight and belongs to the day it starts on.
/// No days, or start == end, means the schedule never holds.
public struct Schedule: Codable, Equatable, Sendable {
  public static let `default` = Schedule(
    days: [.monday, .tuesday, .wednesday, .thursday, .friday],
    start: TimeOfDay(hour: 9, minute: 0),
    end: TimeOfDay(hour: 18, minute: 0)
  )

  public let days: Set<Weekday>
  public let start: TimeOfDay
  public let end: TimeOfDay

  public init(days: Set<Weekday>, start: TimeOfDay, end: TimeOfDay) {
    self.days = days
    self.start = start
    self.end = end
  }

  public func toggling(_ day: Weekday) -> Schedule {
    Schedule(days: days.symmetricDifference([day]), start: start, end: end)
  }

  public func with(start: TimeOfDay? = nil, end: TimeOfDay? = nil) -> Schedule {
    Schedule(days: days, start: start ?? self.start, end: end ?? self.end)
  }

  /// The window `date` falls in (start inclusive, end exclusive), if any.
  public func window(containing date: Date, calendar: Calendar) -> DateInterval? {
    let today = calendar.startOfDay(for: date)
    // A window that started yesterday can still be running (overnight).
    for offset in [0, -1] {
      guard let day = calendar.date(byAdding: .day, value: offset, to: today),
        let window = window(startingOn: day, calendar: calendar),
        window.start <= date, date < window.end
      else { continue }
      return window
    }
    return nil
  }

  /// The first window start strictly after `date`, within the next week.
  public func nextStart(after date: Date, calendar: Calendar) -> Date? {
    let today = calendar.startOfDay(for: date)
    for offset in 0...7 {
      guard let day = calendar.date(byAdding: .day, value: offset, to: today),
        let window = window(startingOn: day, calendar: calendar),
        window.start > date
      else { continue }
      return window.start
    }
    return nil
  }

  private func window(startingOn day: Date, calendar: Calendar) -> DateInterval? {
    guard start != end,
      let weekday = Weekday(rawValue: calendar.component(.weekday, from: day)),
      days.contains(weekday),
      let endDay = calendar.date(byAdding: .day, value: end > start ? 0 : 1, to: day),
      let startDate = calendar.date(
        bySettingHour: start.hour, minute: start.minute, second: 0, of: day),
      let endDate = calendar.date(
        bySettingHour: end.hour, minute: end.minute, second: 0, of: endDay),
      endDate > startDate
    else { return nil }
    return DateInterval(start: startDate, end: endDate)
  }
}
