import Testing

@testable import LisdexCore

@Suite("LoginItemRepair")
struct LoginItemRepairTests {
  private let old = "/opt/homebrew/Cellar/lisdex/1.0.0/Lisdex.app"
  private let new = "/opt/homebrew/Cellar/lisdex/1.1.0/Lisdex.app"

  @Test("app moved after an upgrade and macOS lost it → re-register")
  func movedAndLost() {
    #expect(LoginItemRepair.shouldReRegister(savedPath: old, currentPath: new, isEnabled: false))
  }

  @Test("never enabled from Lisdex → leave it")
  func neverEnabled() {
    #expect(!LoginItemRepair.shouldReRegister(savedPath: nil, currentPath: new, isEnabled: false))
  }

  @Test("same path but off → the user turned it off in System Settings, leave it")
  func userDisabled() {
    #expect(!LoginItemRepair.shouldReRegister(savedPath: new, currentPath: new, isEnabled: false))
  }

  @Test("still enabled → nothing to repair")
  func stillEnabled() {
    #expect(!LoginItemRepair.shouldReRegister(savedPath: old, currentPath: new, isEnabled: true))
  }
}

@Suite("AppSettings.startOnLoginPath")
struct StartOnLoginPathTests {
  @Test("with(startOnLoginPath:) can set and clear the path")
  func setAndClear() {
    let set = AppSettings.default.with(startOnLoginPath: .some("/Applications/Lisdex.app"))

    #expect(set.startOnLoginPath == "/Applications/Lisdex.app")
    #expect(set.with(startOnLoginPath: .some(nil)).startOnLoginPath == nil)
    #expect(set.with(accent: .blue).startOnLoginPath == "/Applications/Lisdex.app")
  }
}
