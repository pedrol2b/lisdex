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
