import Foundation

/// Fixed calendar for deterministic date tests: Gregorian, UTC, en_GB (24 h clock).
/// 2026-11-16 is a Monday.
enum TestClock {
  static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    calendar.locale = Locale(identifier: "en_GB")
    return calendar
  }()

  /// `"2026-11-16 09:00"` (UTC) → Date.
  static func at(_ text: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let full = text.count == 16 ? text + ":00" : text
    return formatter.date(from: full)!
  }
}
