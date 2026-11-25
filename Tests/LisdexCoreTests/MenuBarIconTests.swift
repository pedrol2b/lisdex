import Foundation
import Testing

@testable import LisdexCore

@Suite("MenuBarIcon")
struct MenuBarIconTests {
  @Test("the capsule is the default variant")
  func defaultVariant() {
    #expect(MenuBarIconVariant.default == .capsule)
  }

  @Test(
    "resource names match the exported assets",
    arguments: [
      (MenuBarIconVariant.capsule, false, "capsule-inactive"),
      (MenuBarIconVariant.capsule, true, "capsule-active"),
      (MenuBarIconVariant.molecule, false, "molecule-inactive"),
      (MenuBarIconVariant.molecule, true, "molecule-active"),
      (MenuBarIconVariant.coffee, false, "coffee-inactive"),
      (MenuBarIconVariant.coffee, true, "coffee-active"),
    ])
  func resourceNames(variant: MenuBarIconVariant, isActive: Bool, expected: String) {
    #expect(MenuBarIcon(variant: variant, isActive: isActive).resourceName == expected)
  }

  @Test(
    "badged resource names are <variant>-<badge>-<state>",
    arguments: [
      (MenuBarIconVariant.capsule, true, MenuBarBadge.duration, "capsule-duration-active"),
      (MenuBarIconVariant.coffee, false, MenuBarBadge.schedule, "coffee-schedule-inactive"),
      (
        MenuBarIconVariant.molecule, true, MenuBarBadge.indefinitely,
        "molecule-indefinitely-active"
      ),
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
      MenuBarIcon(variant: .capsule, isActive: true, badge: .duration).accessibilityLabel
        == "Lisdex — Keep Awake on, for a duration")
    #expect(
      MenuBarIcon(variant: .molecule, isActive: false, badge: .schedule).accessibilityLabel
        == "Lisdex — Keep Awake off, on a schedule")
  }

  @Test("Settings → Appearance offers capsule, molecule and coffee, in that order")
  func choices() {
    #expect(MenuBarIconVariant.allCases == [.capsule, .molecule, .coffee])
    #expect(MenuBarIconVariant.allCases.map(\.title) == ["Capsule", "Molecule", "Coffee"])
  }

  @Test("accessibility label states whether Keep Awake is on")
  func accessibilityLabel() {
    #expect(
      MenuBarIcon(variant: .capsule, isActive: true).accessibilityLabel
        == "Lisdex — Keep Awake on")
    #expect(
      MenuBarIcon(variant: .coffee, isActive: false).accessibilityLabel
        == "Lisdex — Keep Awake off")
  }

  @Test("variants are stored by their new names")
  func storedNames() throws {
    let data = try JSONEncoder().encode(AppSettings.default.with(iconVariant: .molecule))
    #expect(String(decoding: data, as: UTF8.self).contains(#""iconVariant":"molecule""#))
  }

  @Test(
    "older saved variants carry over: pill and bulb → capsule, mug → coffee",
    arguments: [
      ("capsule", MenuBarIconVariant.capsule), ("molecule", .molecule), ("coffee", .coffee),
      ("pill", .capsule), ("bulb", .capsule), ("mug", .coffee),
    ])
  func aliases(raw: String, expected: MenuBarIconVariant) throws {
    let json = #"{"iconVariant":"\#(raw)","accent":"pink"}"#

    let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

    #expect(settings.iconVariant == expected)
    #expect(settings.accent == .preset(.pink))
  }

  @Test(
    "retired molecule variants and unknown values load with the capsule, not the new molecule",
    arguments: ["minimal", "faithful", "unknown"])
  func retiredVariantsFallBack(raw: String) throws {
    let json = #"{"iconVariant":"\#(raw)","accent":"pink"}"#

    let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

    #expect(settings.iconVariant == .capsule)
    #expect(settings.accent == .preset(.pink))
  }
}
