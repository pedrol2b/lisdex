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

@Suite("Schedule days summary")
struct ScheduleDaysSummaryTests {
  private let calendar = TestClock.calendar

  private func days(_ days: Set<Weekday>) -> String {
    Schedule(days: days, start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 18, minute: 0))
      .daysSummary(calendar: calendar)
  }

  @Test("consecutive days that are on form a range, Monday first")
  func ranges() {
    #expect(days([.monday, .tuesday, .wednesday, .thursday, .friday]) == "Mon–Fri")
    #expect(days([.monday, .wednesday, .friday]) == "Mon, Wed, Fri")
    #expect(days([.monday, .tuesday, .thursday, .friday, .sunday]) == "Mon–Tue, Thu–Fri, Sun")
    #expect(days([.saturday, .sunday]) == "Sat–Sun")
  }

  @Test("hours don't split a range; every day and no day have their own words")
  func special() {
    let friday = Schedule.default.with(
      hours: DayHours(start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 15, minute: 0)),
      for: .friday)
    #expect(friday.daysSummary(calendar: calendar) == "Mon–Fri")
    #expect(days(Set(Weekday.allCases)) == "Every day")
    #expect(days([]) == "No days")
  }
}
