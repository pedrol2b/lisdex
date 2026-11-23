import Foundation
import Testing

@testable import LisdexCore

@Suite("StatusItemClick")
struct StatusItemClickTests {
  @Test("default keeps v1.0: right-click toggles, left-click opens the popover")
  func defaults() {
    let behavior = AppSettings.default.clickBehavior

    #expect(behavior == .rightClickToggles)
    #expect(behavior.action(for: .secondary) == .toggle)
    #expect(behavior.action(for: .primary) == .openPopover)
  }

  @Test("swapped: left-click toggles, right/control-click opens the popover")
  func swapped() {
    #expect(StatusItemClickBehavior.leftClickToggles.action(for: .primary) == .toggle)
    #expect(StatusItemClickBehavior.leftClickToggles.action(for: .secondary) == .openPopover)
  }

  @Test(
    "Option + either click opens the quick menu, whatever the setting",
    arguments: StatusItemClickBehavior.allCases)
  func optionClick(behavior: StatusItemClickBehavior) {
    #expect(behavior.action(for: .option) == .quickMenu)
  }

  @Test("titles match the Settings copy")
  func titles() {
    #expect(
      StatusItemClickBehavior.rightClickToggles.title == "Right click (left click shows menu)")
    #expect(StatusItemClickBehavior.leftClickToggles.title == "Left click (right click shows menu)")
  }

  @Test("VoiceOver help describes the chosen clicks")
  func accessibilityHelp() {
    #expect(
      StatusItemClickBehavior.rightClickToggles.accessibilityHelp
        == "Opens Lisdex. Right-click toggles Keep Awake. Option-click for quick durations.")
    #expect(
      StatusItemClickBehavior.leftClickToggles.accessibilityHelp
        == "Toggles Keep Awake. Right-click opens Lisdex. Option-click for quick durations.")
  }

  @Test("older settings load with the default; unknown values fall back; the choice round-trips")
  func decoding() throws {
    let old = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"accent":"mint"}"#.utf8))
    let bad = try JSONDecoder().decode(
      AppSettings.self, from: Data(#"{"clickBehavior":"middle","accent":"mint"}"#.utf8))
    let swapped = AppSettings.default.with(clickBehavior: .leftClickToggles)
    let back = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(swapped))

    #expect(old.clickBehavior == .rightClickToggles && old.accent == .mint)
    #expect(bad.clickBehavior == .rightClickToggles && bad.accent == .mint)
    #expect(back == swapped)
  }
}
