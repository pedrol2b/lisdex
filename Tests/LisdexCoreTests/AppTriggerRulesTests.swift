import Foundation
import Testing

@testable import LisdexCore

@Suite("AppTriggerRules")
struct AppTriggerRulesTests {
  private let xcode = "com.apple.dt.Xcode"
  private let code = "com.microsoft.VSCode"
  private let now = TestClock.at("2026-11-16 10:00")

  private var listed: AppTriggers {
    AppTriggers([
      AppTrigger(bundleID: xcode, name: "Xcode"),
      AppTrigger(bundleID: code, name: "Visual Studio Code"),
    ])
  }
  private var appSession: Session { .startedByApp(now: now) }
  private var userSession: Session { .start(mode: .indefinitely, duration: 3600, now: now) }

  private func decide(
    _ event: AppTriggerEvent, _ session: Session?, _ triggers: AppTriggers? = nil
  ) -> AppTriggerAction {
    AppTriggerRules.decide(event, session: session, triggers: triggers ?? listed)
  }

  @Test("a listed app opening turns Keep Awake on")
  func listedLaunch() {
    #expect(decide(.launched(bundleID: xcode), nil) == .startAppSession)
  }

  @Test("an unlisted app opening does nothing")
  func unlistedLaunch() {
    #expect(decide(.launched(bundleID: "com.apple.Safari"), nil) == .none)
  }

  @Test("opening while already on does nothing")
  func alreadyOn() {
    #expect(decide(.launched(bundleID: xcode), userSession) == .none)
    #expect(decide(.launched(bundleID: code), appSession) == .none)
  }

  @Test("the last listed app quitting ends an app session")
  func lastQuit() {
    #expect(decide(.runningChanged(running: ["com.other"]), appSession) == .endSession)
  }

  @Test("quitting one of two listed apps keeps it on")
  func oneOfTwo() {
    #expect(decide(.runningChanged(running: [code, "com.other"]), appSession) == .none)
  }

  @Test("a user session is never ended by apps")
  func userSessionKept() {
    #expect(decide(.runningChanged(running: []), userSession) == .none)
    #expect(decide(.runningChanged(running: []), userSession, .empty) == .none)
  }

  @Test("after a manual off, quitting does nothing and the next listed launch turns it on")
  func afterManualOff() {
    #expect(decide(.runningChanged(running: []), nil) == .none)
    #expect(decide(.launched(bundleID: xcode), nil) == .startAppSession)
  }

  @Test("removing the running app from the list ends the app session")
  func removedFromList() {
    let withoutXcode = listed.removing(bundleID: xcode)
    #expect(decide(.runningChanged(running: [xcode]), appSession, withoutXcode) == .endSession)
  }
}
