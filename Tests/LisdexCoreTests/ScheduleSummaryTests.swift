import Foundation
import Testing

@testable import LisdexCore

@Suite("Schedule summary")
struct ScheduleSummaryTests {
  private let calendar = TestClock.calendar
  private func t(_ hour: Int) -> TimeOfDay { TimeOfDay(hour: hour, minute: 0) }

  @Test("same hours on consecutive days form one group")
  func defaultSchedule() {
    #expect(Schedule.default.summary(calendar: calendar) == "Mon–Fri 09:00–18:00")
  }

  @Test("a day with other hours starts a new group")
  func shortFriday() {
    let schedule = Schedule.default.with(hours: DayHours(start: t(9), end: t(14)), for: .friday)

    #expect(
      schedule.summary(calendar: calendar) == "Mon–Thu 09:00–18:00 · Fri 09:00–14:00")
  }

  @Test("a day that's off breaks a group")
  func gap() {
    let schedule = Schedule(days: [.monday, .wednesday], start: t(9), end: t(18))

    #expect(schedule.summary(calendar: calendar) == "Mon 09:00–18:00 · Wed 09:00–18:00")
  }

  @Test("the weekend groups Saturday and Sunday")
  func weekend() {
    let schedule = Schedule(days: [.saturday, .sunday], start: t(9), end: t(18))

    #expect(schedule.summary(calendar: calendar) == "Sat–Sun 09:00–18:00")
  }

  @Test("no days")
  func noDays() {
    #expect(Schedule(days: [], start: t(9), end: t(18)).summary(calendar: calendar) == "No days")
  }
}
