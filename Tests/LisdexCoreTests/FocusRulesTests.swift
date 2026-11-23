import Foundation
import Testing

@testable import LisdexCore

@Suite("FocusRules")
struct FocusRulesTests {
  private let now = TestClock.at("2026-11-16 10:00")
  private var user: Session { .start(mode: .indefinitely, duration: 3600, now: now) }

  @Test("a Focus that keeps the Mac awake turns Keep Awake on when it is off")
  func starts() {
    #expect(FocusRules.decide(keepsAwake: true, session: nil) == .startFocusSession)
    #expect(FocusRules.decide(keepsAwake: true, session: nil, batteryCutoff: true) == .none)
  }

  @Test("a Focus never replaces a session that is already running")
  func leavesRunningSessions() {
    for session in [user, .startedByApp(now: now), .startedByFocus(now: now)] {
      #expect(FocusRules.decide(keepsAwake: true, session: session) == .none)
    }
  }

  @Test("the Focus ending turns off only a session the Focus started")
  func ends() {
    #expect(FocusRules.decide(keepsAwake: false, session: .startedByFocus(now: now)) == .endSession)
    #expect(FocusRules.decide(keepsAwake: false, session: user) == .none)
    #expect(FocusRules.decide(keepsAwake: false, session: .startedByApp(now: now)) == .none)
    #expect(FocusRules.decide(keepsAwake: false, session: nil) == .none)
  }

  @Test("only a session the user started is the user's")
  func isUsers() {
    #expect(user.isUsers)
    #expect(Session.startedByApp(now: now).isUsers == false)
    #expect(Session.startedByFocus(now: now).isUsers == false)
    #expect(Session.startedByFocus(now: now).deadline == nil)
  }

  @Test("the Focus ending hands its session to a listed app that is still open")
  func handsOverToApp() {
    #expect(
      FocusRules.decide(keepsAwake: false, session: .startedByFocus(now: now), appKeepsAwake: true)
        == .becomeAppSession)
  }
}
