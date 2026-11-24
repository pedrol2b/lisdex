import Foundation
import Testing

@testable import LisdexCore

@Suite("SessionStatus")
struct SessionStatusTests {
  private let calendar = TestClock.calendar
  private let noon = TestClock.at("2026-11-16 12:00")

  private func describe(
    _ plan: SessionPlan, _ mode: KeepAwakeMode, _ session: Session?, at now: Date
  )
    -> SessionStatus
  {
    SessionStatus(
      plan: plan, mode: mode, session: session, schedule: .default, now: now, calendar: calendar)
  }

  @Test("off")
  func off() {
    let status = describe(.off, .indefinitely, nil, at: noon)

    #expect(
      status
        == SessionStatus(pill: .inactive, detail: "Your Mac can sleep normally.", progress: nil))
  }

  @Test("indefinitely shows the elapsed time")
  func elapsed() {
    let session = Session(startedAt: noon.addingTimeInterval(-72 * 60), deadline: nil)

    #expect(
      describe(.holding(until: nil), .indefinitely, session, at: noon).detail
        == "Awake for 1 h 12 min.")
    let fresh = Session(startedAt: noon.addingTimeInterval(-20), deadline: nil)
    #expect(
      describe(.holding(until: nil), .indefinitely, fresh, at: noon).detail
        == "Awake for less than a minute.")
  }

  @Test("duration shows time left, end time and progress")
  func countdown() {
    let end = TestClock.at("2026-11-16 12:30")
    let session = Session(startedAt: TestClock.at("2026-11-16 11:30"), deadline: end)

    let status = describe(
      .holding(until: end), .duration, session, at: TestClock.at("2026-11-16 11:48"))

    #expect(status.pill == .active)
    #expect(status.detail == "42 min left · until 12:30")
    #expect(status.progress == 0.3)
    let lastSeconds = describe(
      .holding(until: end), .duration, session, at: end.addingTimeInterval(-45))
    #expect(lastSeconds.detail == "45 s left · until 12:30")
  }

  @Test("remaining minutes round up, so it never says 0 min")
  func roundsUp() {
    let end = TestClock.at("2026-11-16 12:30")
    let session = Session(startedAt: TestClock.at("2026-11-16 11:30"), deadline: end)

    let status = describe(.holding(until: end), .duration, session, at: end.addingTimeInterval(-61))

    #expect(status.detail == "2 min left · until 12:30")
  }

  @Test("schedule: inside shows the end and the next start; outside waits")
  func schedule() {
    let session = Session(startedAt: noon, deadline: nil)
    let end = TestClock.at("2026-11-16 18:00")

    #expect(
      describe(.holding(until: end), .schedule, session, at: noon).detail
        == "Until 18:00 · next: Tue 09:00")
    let waiting = describe(
      .waiting(next: TestClock.at("2026-11-17 09:00")), .schedule, session, at: noon)
    #expect(
      waiting == SessionStatus(pill: .waiting, detail: "Waiting · next: Tue 09:00", progress: nil))
    #expect(
      describe(.waiting(next: nil), .schedule, session, at: noon).detail == "Pick at least one day."
    )
  }

  @Test("duration labels")
  func durationLabels() {
    #expect(DurationText.short(15 * 60) == "15 min")
    #expect(DurationText.short(3600) == "1 h")
    #expect(DurationText.short(65 * 60) == "1 h 5 min")
    #expect(DurationPreset.all.map(\.seconds) == [900, 1800, 3600, 7200])
  }

  @Test("spoken duration labels spell out units for VoiceOver")
  func spokenDurationLabels() {
    #expect(DurationText.spoken(60) == "1 minute")
    #expect(DurationText.spoken(45 * 60) == "45 minutes")
    #expect(DurationText.spoken(3600) == "1 hour")
    #expect(DurationText.spoken(90 * 60) == "1 hour 30 minutes")
    #expect(DurationText.spoken(7200) == "2 hours")
    #expect(DurationText.spoken(0) == "0 minutes")
  }

  @Test("an app session names the app that keeps the Mac awake")
  func appSession() {
    let session = Session.startedByApp(now: noon.addingTimeInterval(-600))
    func detail(_ apps: [String]) -> SessionStatus {
      SessionStatus(
        plan: .holding(until: nil), mode: .duration, session: session, schedule: .default,
        now: noon, calendar: calendar, openApps: apps)
    }

    #expect(
      detail(["Xcode"])
        == SessionStatus(pill: .active, detail: "While Xcode is open.", progress: nil))
    #expect(detail(["Xcode", "Visual Studio Code"]).detail == "While 2 apps are open.")
    #expect(detail([]).detail == "While an app is open.")
  }

  @Test("a focus session says a Focus keeps the Mac awake")
  func focusSession() {
    let status = SessionStatus(
      plan: .holding(until: nil), mode: .schedule, session: .startedByFocus(now: noon),
      schedule: .default, now: noon, calendar: calendar)

    #expect(status == SessionStatus(pill: .active, detail: "While a Focus is on.", progress: nil))
  }

  @Test("a link's own length shows its countdown in any mode")
  func fixedLengthCountdown() {
    let session = Session.fixed(minutes: 60, now: noon)
    let status = SessionStatus(
      plan: .holding(until: noon.addingTimeInterval(3600)), mode: .schedule, session: session,
      schedule: .default, now: noon, calendar: calendar)

    #expect(status.detail.hasPrefix("1 h left"))
    #expect(status.progress == 0)
  }
}
