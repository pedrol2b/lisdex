import Foundation

/// Times and days in the user's clock format (12 h or 24 h from the locale).
struct ClockText {
  let calendar: Calendar

  func time(_ date: Date) -> String { format(date, template: "jmm") }
  func dayAndTime(_ date: Date) -> String { "\(format(date, template: "EEE")) \(time(date))" }

  /// A wall-clock time, formatted as it would be on any day.
  func time(_ time: TimeOfDay) -> String {
    let day = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
    let date =
      calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day) ?? day
    return self.time(date)
  }

  private func format(_ date: Date, template: String) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = calendar.locale ?? .current
    formatter.setLocalizedDateFormatFromTemplate(template)
    return formatter.string(from: date)
  }
}
