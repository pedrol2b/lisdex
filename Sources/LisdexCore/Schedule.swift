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

/// One day's window. An end before the start runs overnight; start == end never holds.
public struct DayHours: Codable, Hashable, Sendable {
  public static let workday = DayHours(
    start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 18, minute: 0))

  public let start: TimeOfDay
  public let end: TimeOfDay

  public init(start: TimeOfDay, end: TimeOfDay) {
    self.start = start
    self.end = end
  }

  public var isOvernight: Bool { end < start }
}

/// When "On a Schedule" holds the Mac awake: the days that are on, each with its own hours.
/// Hours are kept for all seven days, so a day switched off keeps them for when it's back on.
/// A window belongs to the day it starts on. No days means the schedule never holds.
public struct Schedule: Equatable, Sendable {
  public static let `default` = Schedule(
    days: [.monday, .tuesday, .wednesday, .thursday, .friday],
    start: DayHours.workday.start, end: DayHours.workday.end)

  private static let daysPerWeek = 7

  public let days: Set<Weekday>
  private let hoursByDay: [Weekday: DayHours]

  /// Days missing from `hours` get `fallback`.
  public init(days: Set<Weekday>, hours: [Weekday: DayHours], fallback: DayHours = .workday) {
    self.days = days
    self.hoursByDay = Dictionary(
      uniqueKeysWithValues: Weekday.allCases.map { ($0, hours[$0] ?? fallback) })
  }

  /// Every day the same hours.
  public init(days: Set<Weekday>, start: TimeOfDay, end: TimeOfDay) {
    self.init(days: days, hours: [:], fallback: DayHours(start: start, end: end))
  }

  public func hours(for day: Weekday) -> DayHours { hoursByDay[day] ?? .workday }

  /// The hours every day that's on shares (all seven days when none is on), or `nil` if they differ.
  public var sharedHours: DayHours? {
    let counted = days.isEmpty ? Set(Weekday.allCases) : days
    let distinct = Set(counted.map(hours(for:)))
    return distinct.count == 1 ? distinct.first : nil
  }

  public func toggling(_ day: Weekday) -> Schedule {
    Schedule(days: days.symmetricDifference([day]), hours: hoursByDay)
  }

  public func with(hours: DayHours, for day: Weekday) -> Schedule {
    Schedule(days: days, hours: hoursByDay.merging([day: hours]) { _, new in new })
  }

  public func withAllHours(_ hours: DayHours) -> Schedule {
    Schedule(days: days, hours: [:], fallback: hours)
  }

  /// Every day gets the hours of the first day that's on (Monday first; Monday when none is on),
  /// the same day the v1.1 `start`/`end` come from. Settings → "Different hours per day" off.
  public func unifyingHours() -> Schedule {
    withAllHours(hours(for: firstDayOn))
  }

  /// The first day that's on, Monday first; Monday when none is.
  var firstDayOn: Weekday { Weekday.displayOrder.first(where: days.contains) ?? .monday }

  /// The popover's shared From/To: the days that are on, plus any day that's off still at the
  /// old shared hours, get `hours`; a day that's off with its own hours keeps them.
  public func withSharedHours(_ hours: DayHours) -> Schedule {
    let old = sharedHours
    let changed = Weekday.allCases.filter { days.contains($0) || self.hours(for: $0) == old }
    return Schedule(
      days: days,
      hours: hoursByDay.merging(changed.map { ($0, hours) }) { _, new in new })
  }

  /// The window `date` falls in (start inclusive, end exclusive), if any. Windows that overlap or
  /// touch hold as one, so the end is that of the last window in the run.
  public func window(containing date: Date, calendar: Calendar) -> DateInterval? {
    let today = calendar.startOfDay(for: date)
    // Yesterday's window can still be running (overnight); a run can chain through the week.
    let windows = (-1...Self.daysPerWeek).compactMap { offset in
      calendar.date(byAdding: .day, value: offset, to: today).flatMap {
        window(startingOn: $0, calendar: calendar)
      }
    }
    guard let first = windows.firstIndex(where: { $0.start <= date && date < $0.end }) else {
      return nil
    }
    var end = windows[first].end
    for next in windows[(first + 1)...] where next.start <= end {
      end = max(end, next.end)
    }
    return DateInterval(start: windows[first].start, end: end)
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
    guard let weekday = Weekday(rawValue: calendar.component(.weekday, from: day)),
      days.contains(weekday)
    else { return nil }
    let hours = hours(for: weekday)
    guard hours.start != hours.end,
      let endDay = calendar.date(byAdding: .day, value: hours.isOvernight ? 1 : 0, to: day),
      let startDate = calendar.date(
        bySettingHour: hours.start.hour, minute: hours.start.minute, second: 0, of: day),
      let endDate = calendar.date(
        bySettingHour: hours.end.hour, minute: hours.end.minute, second: 0, of: endDay),
      endDate > startDate
    else { return nil }
    return DateInterval(start: startDate, end: endDate)
  }
}

/// JSON: `days`, per-day `hours` keyed by weekday number, plus the v1.1 `start`/`end` (the first
/// day that's on, Monday first) so a downgrade keeps a sensible schedule. Decoding a day: its own
/// valid hours, else the v1.1 hours, else 09:00–18:00. Neither kind of hours present → error.
extension Schedule: Codable {
  private enum CodingKeys: String, CodingKey { case days, start, end, hours }

  /// A per-day entry that may be invalid; an invalid one decodes to `nil` instead of failing.
  private struct LossyDayHours: Decodable {
    let value: DayHours?
    init(from decoder: Decoder) throws { value = try? DayHours(from: decoder) }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let days = try container.decode(Set<Weekday>.self, forKey: .days)
    let legacy: DayHours? =
      if let start = try? container.decode(TimeOfDay.self, forKey: .start),
        let end = try? container.decode(TimeOfDay.self, forKey: .end)
      {
        DayHours(start: start, end: end)
      } else {
        nil
      }
    let entries =
      (try? container.decodeIfPresent([String: LossyDayHours].self, forKey: .hours)) ?? nil
    var hours: [Weekday: DayHours] = [:]
    for (key, entry) in entries ?? [:] {
      guard let raw = Int(key), let day = Weekday(rawValue: raw), let value = entry.value
      else { continue }
      hours[day] = value
    }
    guard legacy != nil || !hours.isEmpty else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: container.codingPath, debugDescription: "schedule has no valid hours"))
    }
    self.init(days: days, hours: hours, fallback: legacy ?? .workday)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(days, forKey: .days)
    try container.encode(hours(for: firstDayOn).start, forKey: .start)
    try container.encode(hours(for: firstDayOn).end, forKey: .end)
    let perDay = Dictionary(
      uniqueKeysWithValues: Weekday.allCases.map { (String($0.rawValue), hours(for: $0)) })
    try container.encode(perDay, forKey: .hours)
  }
}
