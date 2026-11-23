import Foundation
import Testing

@testable import LisdexCore

@Suite("SessionPlanner")
struct SessionPlannerTests {
  private let calendar = TestClock.calendar
  private let monday10 = TestClock.at("2026-11-16 10:00")

  private func plan(_ session: Session?, _ mode: KeepAwakeMode, at now: Date) -> SessionPlan {
    SessionPlanner.plan(
      session: session, mode: mode, schedule: .default, now: now, calendar: calendar)
  }

  @Test("no session → off")
  func off() {
    #expect(plan(nil, .indefinitely, at: monday10) == .off)
    #expect(SessionPlan.off.holdsAwake == false)
    #expect(SessionPlan.off.nextCheck == nil)
  }

  @Test("starting a session: only Duration gets a deadline")
  func start() {
    let timed = Session.start(mode: .duration, duration: 1800, now: monday10)
    let open = Session.start(mode: .indefinitely, duration: 1800, now: monday10)

    #expect(timed == Session(startedAt: monday10, deadline: monday10.addingTimeInterval(1800)))
    #expect(open.deadline == nil)
  }

  @Test("indefinitely holds with no end")
  func indefinitely() {
    let result = plan(Session(startedAt: monday10, deadline: nil), .indefinitely, at: monday10)

    #expect(result == .holding(until: nil))
    #expect(result.holdsAwake)
  }

  @Test("duration holds until the wall-clock deadline, then expires")
  func duration() {
    let session = Session.start(mode: .duration, duration: 3600, now: monday10)
    let deadline = monday10.addingTimeInterval(3600)

    #expect(
      plan(session, .duration, at: monday10.addingTimeInterval(10)) == .holding(until: deadline))
    #expect(plan(session, .duration, at: deadline) == .expired)
    #expect(plan(session, .duration, at: deadline.addingTimeInterval(7200)) == .expired)
    #expect(SessionPlan.holding(until: deadline).nextCheck == deadline)
  }

  @Test("schedule holds inside a window, waits outside it")
  func schedule() {
    let session = Session(startedAt: monday10, deadline: nil)

    #expect(
      plan(session, .schedule, at: monday10) == .holding(until: TestClock.at("2026-11-16 18:00")))
    let evening = plan(session, .schedule, at: TestClock.at("2026-11-16 19:00"))
    #expect(evening == .waiting(next: TestClock.at("2026-11-17 09:00")))
    #expect(evening.holdsAwake == false)
    #expect(evening.nextCheck == TestClock.at("2026-11-17 09:00"))
  }

  @Test("an app session holds in every mode, even outside a schedule window")
  func appSession() {
    let session = Session.startedByApp(now: monday10)
    let evening = TestClock.at("2026-11-16 19:00")

    for mode in [KeepAwakeMode.indefinitely, .duration, .schedule] {
      #expect(plan(session, mode, at: evening) == .holding(until: nil))
    }
  }

  @Test("sessions remember who started them")
  func origin() {
    #expect(Session.start(mode: .duration, duration: 1800, now: monday10).origin == .user)
    #expect(Session(startedAt: monday10, deadline: nil).origin == .user)
    #expect(Session.startedByApp(now: monday10).origin == .app)
    #expect(Session.startedByApp(now: monday10).deadline == nil)
  }
}
