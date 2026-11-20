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
    ])
  func resourceNames(variant: MenuBarIconVariant, isActive: Bool, expected: String) {
    #expect(MenuBarIcon(variant: variant, isActive: isActive).resourceName == expected)
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
    #expect(MenuBarIconVariant(rawValue: "unknown") == nil)
  }

  @Test(
    "settings saved with a retired molecule variant load with the pill",
    arguments: ["minimal", "faithful"])
  func retiredVariantsFallBack(raw: String) throws {
    let json = #"{"iconVariant":"\#(raw)","accent":"pink"}"#

    let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

    #expect(settings.iconVariant == .pill)
    #expect(settings.accent == .pink)
  }
}
