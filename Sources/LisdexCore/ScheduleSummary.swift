import Foundation

extension Schedule {
  /// One line for the popover: "Mon–Thu 09:00–18:00 · Fri 09:00–14:00". Days that are on, Monday
  /// first; consecutive days with the same hours share a group; a day that's off ends a group.
  public func summary(calendar: Calendar) -> String {
    let clock = ClockText(calendar: calendar)
    let groups = groupsOfSameHours()
    guard !groups.isEmpty else { return "No days" }
    return groups.map { group in
      let name = { (day: Weekday) in calendar.shortWeekdaySymbols[day.rawValue - 1] }
      let label =
        group.first == group.last
        ? name(group.first) : "\(name(group.first))–\(name(group.last))"
      let hours = hours(for: group.first)
      return "\(label) \(clock.time(hours.start))–\(clock.time(hours.end))"
    }
    .joined(separator: " · ")
  }

  /// Just the days for the popover's mode row: "Mon–Fri", "Mon, Wed, Fri", "Every day", "No days".
  /// Consecutive days that are on form a range, whatever their hours.
  public func daysSummary(calendar: Calendar) -> String {
    if days.isEmpty { return "No days" }
    if days.count == Weekday.allCases.count { return "Every day" }
    let name = { (day: Weekday) in calendar.shortWeekdaySymbols[day.rawValue - 1] }
    var runs: [(first: Weekday, last: Weekday)] = []
    var previous: Weekday?
    for day in Weekday.displayOrder {
      defer { previous = days.contains(day) ? day : nil }
      guard days.contains(day) else { continue }
      if previous != nil, let run = runs.last {
        runs[runs.count - 1] = (run.first, day)
      } else {
        runs.append((day, day))
      }
    }
    return runs.map { $0.first == $0.last ? name($0.first) : "\(name($0.first))–\(name($0.last))" }
      .joined(separator: ", ")
  }

  private func groupsOfSameHours() -> [(first: Weekday, last: Weekday)] {
    var groups: [(first: Weekday, last: Weekday)] = []
    var previous: Weekday?
    for day in Weekday.displayOrder {
      defer { previous = days.contains(day) ? day : nil }
      guard days.contains(day) else { continue }
      if let previous, let current = groups.last, hours(for: previous) == hours(for: day) {
        groups[groups.count - 1] = (current.first, day)
      } else {
        groups.append((day, day))
      }
    }
    return groups
  }
}
