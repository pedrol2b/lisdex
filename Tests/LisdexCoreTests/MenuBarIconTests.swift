import Foundation
import Testing

@testable import LisdexCore

@Suite("MenuBarIcon")
struct MenuBarIconTests {
  @Test("the pill is the default variant")
  func defaultVariant() {
    #expect(MenuBarIconVariant.default == .pill)
  }

  @Test(
    "resource names match the exported assets",
    arguments: [
      (MenuBarIconVariant.pill, false, "pill-inactive"),
      (MenuBarIconVariant.pill, true, "pill-active"),
      (MenuBarIconVariant.mug, false, "mug-inactive"),
      (MenuBarIconVariant.mug, true, "mug-active"),
      (MenuBarIconVariant.bulb, false, "bulb-inactive"),
      (MenuBarIconVariant.bulb, true, "bulb-active"),
    ])
  func resourceNames(variant: MenuBarIconVariant, isActive: Bool, expected: String) {
    #expect(MenuBarIcon(variant: variant, isActive: isActive).resourceName == expected)
  }

  @Test(
    "badged resource names are <variant>-<badge>-<state>",
    arguments: [
      (MenuBarIconVariant.pill, true, MenuBarBadge.duration, "pill-duration-active"),
      (MenuBarIconVariant.mug, false, MenuBarBadge.schedule, "mug-schedule-inactive"),
      (MenuBarIconVariant.bulb, true, MenuBarBadge.indefinitely, "bulb-indefinitely-active"),
    ])
  func badgedResourceNames(
    variant: MenuBarIconVariant, isActive: Bool, badge: MenuBarBadge, expected: String
  ) {
    #expect(
      MenuBarIcon(variant: variant, isActive: isActive, badge: badge).resourceName == expected)
  }

  @Test("a badged icon's accessibility label adds the mode")
  func badgedAccessibilityLabel() {
    #expect(
      MenuBarIcon(variant: .pill, isActive: true, badge: .duration).accessibilityLabel
        == "Lisdex — Keep Awake on, for a duration")
    #expect(
      MenuBarIcon(variant: .bulb, isActive: false, badge: .schedule).accessibilityLabel
        == "Lisdex — Keep Awake off, on a schedule")
  }

  @Test("Settings → Appearance offers pill, coffee mug and light bulb, in that order")
  func choices() {
    #expect(MenuBarIconVariant.allCases == [.pill, .mug, .bulb])
    #expect(MenuBarIconVariant.allCases.map(\.title) == ["Pill", "Coffee mug", "Light bulb"])
  }

  @Test("accessibility label states whether Keep Awake is on")
  func accessibilityLabel() {
    #expect(
      MenuBarIcon(variant: .pill, isActive: true).accessibilityLabel == "Lisdex — Keep Awake on")
    #expect(
      MenuBarIcon(variant: .mug, isActive: false).accessibilityLabel == "Lisdex — Keep Awake off")
  }

  @Test("variants round-trip through their raw value for persistence")
  func rawValues() {
    #expect(MenuBarIconVariant(rawValue: "pill") == .pill)
    #expect(MenuBarIconVariant(rawValue: "mug") == .mug)
    #expect(MenuBarIconVariant(rawValue: "bulb") == .bulb)
    #expect(MenuBarIconVariant(rawValue: "unknown") == nil)
  }

  @Test(
    "settings saved with a retired molecule variant load with the pill",
    arguments: ["minimal", "faithful"])
  func retiredVariantsFallBack(raw: String) throws {
    let json = #"{"iconVariant":"\#(raw)","accent":"pink"}"#

    let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

    #expect(settings.iconVariant == .pill)
    #expect(settings.accent == .preset(.pink))
  }
}
