import Foundation
import Testing

@testable import LisdexCore

@Suite("ShortcutSettings")
struct ShortcutSettingsTests {
  private let hyperL = KeyCombo(keyCode: 37, modifiers: [.control, .option, .command])

  private func decode(_ json: String) throws -> AppSettings {
    try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
  }

  @Test("no shortcuts by default; Start for a Duration runs 1 hour")
  func defaults() {
    #expect(AppSettings.default.shortcuts.combos.isEmpty)
    #expect(AppSettings.default.shortcuts.durationSeconds == 3600)
  }

  @Test("with(...) sets and clears, returning new values")
  func with() {
    let original = ShortcutSettings.default
    let set = original.with(hyperL, for: .toggle)
    let cleared = set.with(nil, for: .toggle)

    #expect(original.combos.isEmpty)
    #expect(set.combos == [.toggle: hyperL])
    #expect(cleared.combos.isEmpty)
    #expect(original.with(durationSeconds: 1800).durationSeconds == 1800)
  }

  @Test("round-trips inside AppSettings")
  func roundTrip() throws {
    let settings = AppSettings.default.with(
      shortcuts: ShortcutSettings.default.with(hyperL, for: .stop).with(durationSeconds: 900))
    let back = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
    #expect(back == settings)
  }

  @Test("settings from v1.0 or with garbage shortcuts load with none, keeping the rest")
  func tolerantDecoding() throws {
    let old = try decode(#"{"accent":"mint"}"#)
    let garbage = try decode(#"{"shortcuts":"garbage","accent":"mint"}"#)

    #expect(old.shortcuts == .default && old.accent == .preset(.mint))
    #expect(garbage.shortcuts == .default && garbage.accent == .preset(.mint))
  }

  @Test("one bad entry is dropped, the others kept; a bad duration falls back")
  func badEntry() throws {
    let settings = try decode(
      #"""
      {"shortcuts":{"combos":{"toggle":{"keyCode":37,"modifiers":11},
      "stop":{"keyCode":"x"},"someday":{"keyCode":1,"modifiers":1}},"durationSeconds":-5}}
      """#)

    #expect(settings.shortcuts.combos == [.toggle: hyperL])
    #expect(settings.shortcuts.durationSeconds == 3600)
  }
}
