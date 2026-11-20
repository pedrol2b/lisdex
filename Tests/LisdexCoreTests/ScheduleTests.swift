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
    #expect(workdays.start == TimeOfDay(hour: 9, minute: 0))
    #expect(workdays.end == TimeOfDay(hour: 18, minute: 0))
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
    let noDays = Schedule(days: [], start: workdays.start, end: workdays.end)
    let empty = Schedule(days: workdays.days, start: workdays.start, end: workdays.start)
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
}
