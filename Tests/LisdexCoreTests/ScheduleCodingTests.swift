import Foundation
import Testing

@testable import LisdexCore

@Suite("Schedule coding")
struct ScheduleCodingTests {
  private func t(_ hour: Int, _ minute: Int = 0) -> TimeOfDay {
    TimeOfDay(hour: hour, minute: minute)
  }
  private func decode(_ json: String) throws -> Schedule {
    try JSONDecoder().decode(Schedule.self, from: Data(json.utf8))
  }
  private func object(_ schedule: Schedule) throws -> [String: Any] {
    let data = try JSONEncoder().encode(schedule)
    return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  @Test("per-day hours survive a round trip")
  func roundTrip() throws {
    let schedule = Schedule.default.with(hours: DayHours(start: t(9), end: t(14)), for: .friday)
    let data = try JSONEncoder().encode(schedule)

    #expect(try JSONDecoder().decode(Schedule.self, from: data) == schedule)
  }

  @Test("a v1.1 schedule gives every day its hours")
  func legacyShape() throws {
    let schedule = try decode(#"{"days":[2,6],"start":600,"end":960}"#)

    #expect(schedule.days == [.monday, .friday])
    for day in Weekday.allCases {
      #expect(schedule.hours(for: day) == DayHours(start: t(10), end: t(16)))
    }
  }

  @Test("the v1.1 start and end are still written, from the first day that's on")
  func writesLegacyFields() throws {
    let fridayOnly = Schedule(
      days: [.friday], hours: [.friday: DayHours(start: t(9), end: t(14))])
    let none = Schedule(days: [], hours: [.monday: DayHours(start: t(7), end: t(8))])

    let friday = try object(fridayOnly)
    #expect(friday["start"] as? Int == 540)
    #expect(friday["end"] as? Int == 840)
    let empty = try object(none)
    #expect(empty["start"] as? Int == 420)
    #expect(empty["end"] as? Int == 480)
  }

  @Test("a bad day falls back to the v1.1 hours; the other days are kept")
  func badDayFallsBack() throws {
    let schedule = try decode(
      #"{"days":[2,6],"start":600,"end":960,"hours":{"6":{"start":-1,"end":840},"2":{"start":600,"end":700}}}"#
    )

    #expect(schedule.hours(for: .friday) == DayHours(start: t(10), end: t(16)))
    #expect(schedule.hours(for: .monday) == DayHours(start: t(10), end: t(11, 40)))
  }

  @Test("per-day hours without the v1.1 fields: other days get 09:00–18:00")
  func hoursWithoutLegacy() throws {
    let schedule = try decode(#"{"days":[2],"hours":{"2":{"start":600,"end":700}}}"#)

    #expect(schedule.hours(for: .monday) == DayHours(start: t(10), end: t(11, 40)))
    #expect(schedule.hours(for: .tuesday) == .workday)
  }

  @Test("a bad day with no usable v1.1 hours falls back to 09:00–18:00")
  func badDayAndBadLegacy() throws {
    let schedule = try decode(
      #"{"days":[2,6],"start":-5,"end":960,"hours":{"6":{"start":-1,"end":840},"2":{"start":600,"end":700}}}"#
    )

    #expect(schedule.hours(for: .friday) == .workday)
    #expect(schedule.hours(for: .monday) == DayHours(start: t(10), end: t(11, 40)))
  }
}
