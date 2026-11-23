import Foundation
import Testing

@testable import LisdexCore

@Suite("Schedule")
struct ScheduleTests {
  private let calendar = TestClock.calendar
  private let workdays = Schedule.default  // Mon–Fri 09:00–18:00

  @Test("default is weekdays 09:00–18:00")
  func defaultSchedule() {
    #expect(workdays.days == [.monday, .tuesday, .wednesday, .thursday, .friday])
    for day in Weekday.allCases {
      #expect(workdays.hours(for: day) == DayHours(start: t(9), end: t(18)))
    }
  }

  @Test("days are listed Monday first, with one-letter symbols")
  func displayOrder() {
    #expect(Weekday.displayOrder.first == .monday)
    #expect(Weekday.displayOrder.last == .sunday)
    #expect(Weekday.displayOrder.map(\.letter).joined() == "MTWTFSS")
  }

  @Test("inside a window → that window")
  func insideWindow() {
    let window = workdays.window(containing: TestClock.at("2026-11-16 10:00"), calendar: calendar)

    #expect(
      window
        == DateInterval(
          start: TestClock.at("2026-11-16 09:00"), end: TestClock.at("2026-11-16 18:00")))
  }

  @Test("the end is exclusive and the next start skips the weekend")
  func endExclusiveAndWeekend() {
    let fridayEnd = TestClock.at("2026-11-20 18:00")

    #expect(workdays.window(containing: fridayEnd, calendar: calendar) == nil)
    #expect(
      workdays.nextStart(after: fridayEnd, calendar: calendar) == TestClock.at("2026-11-23 09:00"))
  }

  @Test("before today's window → today's start")
  func beforeWindow() {
    let early = TestClock.at("2026-11-16 08:00")

    #expect(workdays.window(containing: early, calendar: calendar) == nil)
    #expect(
      workdays.nextStart(after: early, calendar: calendar) == TestClock.at("2026-11-16 09:00"))
  }

  @Test("overnight windows belong to the day they start on")
  func overnight() {
    let nights = Schedule(
      days: [.friday], start: TimeOfDay(hour: 22, minute: 0), end: TimeOfDay(hour: 6, minute: 0))
    let expected = DateInterval(
      start: TestClock.at("2026-11-20 22:00"), end: TestClock.at("2026-11-21 06:00"))

    #expect(
      nights.window(containing: TestClock.at("2026-11-20 23:00"), calendar: calendar) == expected)
    #expect(
      nights.window(containing: TestClock.at("2026-11-21 02:00"), calendar: calendar) == expected)
    #expect(nights.window(containing: TestClock.at("2026-11-21 23:00"), calendar: calendar) == nil)
  }

  @Test("no days, or start == end, never holds")
  func neverActive() {
    let noDays = Schedule(days: [], start: t(9), end: t(18))
    let empty = Schedule(days: workdays.days, start: t(9), end: t(9))
    let monday = TestClock.at("2026-11-16 10:00")

    for schedule in [noDays, empty] {
      #expect(schedule.window(containing: monday, calendar: calendar) == nil)
      #expect(schedule.nextStart(after: monday, calendar: calendar) == nil)
    }
  }

  @Test("toggling a day returns a new schedule")
  func togglingDay() {
    let withSaturday = workdays.toggling(.saturday)

    #expect(withSaturday.days.contains(.saturday))
    #expect(withSaturday.toggling(.saturday) == workdays)
    #expect(workdays.days.contains(.saturday) == false)
  }

  @Test("TimeOfDay rejects out-of-range minutes when decoding")
  func timeOfDayValidation() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(TimeOfDay.self, from: Data("1440".utf8))
    }
    #expect(TimeOfDay(hour: 23, minute: 59).minutes == 1439)
  }

  // MARK: - Per-day hours

  private func t(_ hour: Int, _ minute: Int = 0) -> TimeOfDay {
    TimeOfDay(hour: hour, minute: minute)
  }
  private func window(_ start: String, _ end: String) -> DateInterval {
    DateInterval(start: TestClock.at(start), end: TestClock.at(end))
  }

  @Test("each day uses its own hours")
  func perDayWindow() {
    let shortFriday = workdays.with(hours: DayHours(start: t(9), end: t(14)), for: .friday)

    #expect(
      shortFriday.window(containing: TestClock.at("2026-11-20 10:00"), calendar: calendar)
        == window("2026-11-20 09:00", "2026-11-20 14:00"))
    #expect(
      shortFriday.window(containing: TestClock.at("2026-11-20 15:00"), calendar: calendar) == nil)
    #expect(
      shortFriday.nextStart(after: TestClock.at("2026-11-20 15:00"), calendar: calendar)
        == TestClock.at("2026-11-23 09:00"))
    #expect(
      shortFriday.window(containing: TestClock.at("2026-11-16 17:00"), calendar: calendar)
        == window("2026-11-16 09:00", "2026-11-16 18:00"))
  }

  @Test("an overnight window uses the hours of the day it starts on")
  func overnightUsesStartDayHours() {
    let schedule = Schedule(
      days: [.friday, .saturday],
      hours: [
        .friday: DayHours(start: t(22), end: t(6)), .saturday: DayHours(start: t(10), end: t(12)),
      ])

    #expect(
      schedule.window(containing: TestClock.at("2026-11-21 02:00"), calendar: calendar)
        == window("2026-11-20 22:00", "2026-11-21 06:00"))
    #expect(
      schedule.window(containing: TestClock.at("2026-11-21 08:00"), calendar: calendar) == nil)
    #expect(
      schedule.window(containing: TestClock.at("2026-11-21 10:30"), calendar: calendar)
        == window("2026-11-21 10:00", "2026-11-21 12:00"))
  }

  @Test("a day switched off keeps its hours")
  func offDayKeepsHours() {
    let saturday = DayHours(start: t(10), end: t(12))
    let schedule = workdays.with(hours: saturday, for: .saturday)
      .toggling(.saturday).toggling(.saturday).toggling(.saturday)

    #expect(schedule.days.contains(.saturday))
    #expect(schedule.hours(for: .saturday) == saturday)
  }

  @Test("shared hours: only the days that are on count, unless none is on")
  func sharedHours() {
    let odd = DayHours(start: t(10), end: t(12))

    #expect(workdays.sharedHours == .workday)
    #expect(
      workdays.with(hours: DayHours(start: t(9), end: t(14)), for: .friday).sharedHours == nil)
    #expect(workdays.with(hours: odd, for: .saturday).sharedHours == .workday)
    #expect(Schedule(days: [], start: t(10), end: t(12)).sharedHours == odd)
    #expect(Schedule(days: [], hours: [.monday: odd]).sharedHours == nil)
  }

  @Test("withAllHours sets every day, including days that are off")
  func withAllHours() {
    let hours = DayHours(start: t(8), end: t(16, 30))
    let schedule = workdays.with(hours: DayHours(start: t(9), end: t(14)), for: .friday)
      .withAllHours(hours)

    for day in Weekday.allCases { #expect(schedule.hours(for: day) == hours) }
    #expect(schedule.days == workdays.days)
  }
}
