import Foundation
import Testing

@testable import LisdexCore

@Suite("AppTriggers")
struct AppTriggersTests {
  private let xcode = AppTrigger(bundleID: "com.apple.dt.Xcode", name: "Xcode")
  private let code = AppTrigger(bundleID: "com.microsoft.VSCode", name: "Visual Studio Code")

  private func decode(_ json: String) throws -> AppSettings {
    try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
  }

  @Test("the list starts empty")
  func empty() {
    #expect(AppSettings.default.appTriggers.apps.isEmpty)
    #expect(AppSettings.default.appTriggers == .empty)
  }

  @Test("adding and removing return new lists; duplicates are ignored")
  func addRemove() {
    let original = AppTriggers.empty
    let added = original.adding(xcode).adding(code).adding(xcode)
    let removed = added.removing(bundleID: xcode.bundleID)

    #expect(original.apps.isEmpty)
    #expect(added.apps == [xcode, code])
    #expect(added.contains(bundleID: "com.apple.dt.Xcode"))
    #expect(added.bundleIDs == ["com.apple.dt.Xcode", "com.microsoft.VSCode"])
    #expect(removed.apps == [code])
  }

  @Test("round-trips inside AppSettings")
  func roundTrip() throws {
    let settings = AppSettings.default.with(appTriggers: AppTriggers([xcode, code]))
    let back = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
    #expect(back == settings)
  }

  @Test("settings from v1.1 or with garbage load with no apps, keeping the rest")
  func tolerant() throws {
    let old = try decode(#"{"accent":"mint"}"#)
    let garbage = try decode(#"{"appTriggers":"x","accent":"mint"}"#)

    #expect(old.appTriggers == .empty && old.accent == .mint)
    #expect(garbage.appTriggers == .empty && garbage.accent == .mint)
  }

  @Test("bad, blank and duplicate entries are dropped")
  func badEntries() throws {
    let settings = try decode(
      #"""
      {"appTriggers":[{"bundleID":"a","name":"A"},{"bundleID":5},
      {"bundleID":"","name":"B"},{"bundleID":"a","name":"A2"}]}
      """#)

    #expect(settings.appTriggers.apps == [AppTrigger(bundleID: "a", name: "A")])
  }
}
