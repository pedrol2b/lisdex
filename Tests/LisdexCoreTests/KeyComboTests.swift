import Foundation
import Testing

@testable import LisdexCore

@Suite("KeyCombo")
struct KeyComboTests {
  // Virtual key codes (kVK_ANSI_*), physical positions on an ANSI keyboard.
  private let keyL: UInt16 = 37
  private let keyA: UInt16 = 0
  private let keyQ: UInt16 = 12
  private let key4: UInt16 = 21
  private let space: UInt16 = 49
  private let escape: UInt16 = 53
  private let f5: UInt16 = 96

  private let hyper: KeyModifiers = [.control, .option, .command]

  @Test("modifier symbols follow macOS order ⌃⌥⇧⌘")
  func symbols() {
    #expect(KeyModifiers([.command, .shift, .option, .control]).symbols == "⌃⌥⇧⌘")
    #expect(KeyModifiers([.command, .control]).symbols == "⌃⌘")
    #expect(KeyModifiers().symbols == "")
  }

  @Test("display string: modifiers then key name, special keys by symbol")
  func display() {
    #expect(KeyCombo(keyCode: keyL, modifiers: hyper).displayString(keyName: "l") == "⌃⌥⌘L")
    #expect(KeyCombo(keyCode: space, modifiers: .command).displayString(keyName: " ") == "⌘Space")
    #expect(KeyCombo(keyCode: f5, modifiers: []).displayString(keyName: "") == "F5")
  }

  @Test("needs ⌃, ⌥ or ⌘ unless it is a function key")
  func needsModifier() {
    let assigned: [ShortcutAction: KeyCombo] = [:]
    let shiftA = KeyCombo(keyCode: keyA, modifiers: .shift)
    let bareA = KeyCombo(keyCode: keyA, modifiers: [])
    let bareF5 = KeyCombo(keyCode: f5, modifiers: [])

    #expect(shiftA.problem(keyName: "a", action: .toggle, assigned: assigned) == .needsModifier)
    #expect(bareA.problem(keyName: "a", action: .toggle, assigned: assigned) == .needsModifier)
    #expect(bareF5.isFunctionKey)
    #expect(bareF5.problem(keyName: "", action: .toggle, assigned: assigned) == nil)
  }

  @Test(
    "macOS-reserved combos are refused",
    arguments: [
      (UInt16(12), KeyModifiers.command, "q"),
      (UInt16(13), KeyModifiers.command, "w"),
      (UInt16(48), KeyModifiers.command, "\t"),
      (UInt16(49), KeyModifiers.command, " "),
      (UInt16(49), KeyModifiers.control, " "),
      (UInt16(20), KeyModifiers([.command, .shift]), "3"),
      (UInt16(21), KeyModifiers([.command, .shift]), "4"),
      (UInt16(23), KeyModifiers([.command, .shift]), "5"),
      (UInt16(53), KeyModifiers([.command, .option]), ""),
    ])
  func reserved(keyCode: UInt16, modifiers: KeyModifiers, keyName: String) {
    let combo = KeyCombo(keyCode: keyCode, modifiers: modifiers)
    #expect(combo.problem(keyName: keyName, action: .toggle, assigned: [:]) == .reservedBySystem)
  }

  @Test("reserved letters follow the layout's key name, not the physical key")
  func reservedByName() {
    // On AZERTY the physical A key types "q": ⌘ on it is ⌘Q.
    let azertyQ = KeyCombo(keyCode: keyA, modifiers: .command)
    let qwertyQ = KeyCombo(keyCode: keyQ, modifiers: .command)

    #expect(azertyQ.problem(keyName: "q", action: .toggle, assigned: [:]) == .reservedBySystem)
    #expect(qwertyQ.problem(keyName: "a", action: .toggle, assigned: [:]) == nil)
  }

  @Test("a combo used by another Lisdex action is refused; re-recording the same row is fine")
  func duplicates() {
    let combo = KeyCombo(keyCode: keyL, modifiers: hyper)
    let assigned: [ShortcutAction: KeyCombo] = [.stop: combo]

    #expect(combo.problem(keyName: "l", action: .toggle, assigned: assigned) == .usedBy(.stop))
    #expect(combo.problem(keyName: "l", action: .stop, assigned: assigned) == nil)
    #expect(
      KeyCombo(keyCode: key4, modifiers: hyper).problem(
        keyName: "4", action: .toggle, assigned: assigned) == nil)
  }

  @Test("messages match the Settings copy")
  func messages() {
    #expect(KeyComboProblem.needsModifier.message == "Add ⌃, ⌥ or ⌘.")
    #expect(KeyComboProblem.reservedBySystem.message == "Reserved by macOS.")
    #expect(KeyComboProblem.usedBy(.stop).message == "Already used for Stop.")
  }

  @Test("action titles")
  func titles() {
    #expect(
      ShortcutAction.allCases.map(\.title) == [
        "Toggle Keep Awake", "Start Indefinitely", "Start for a Duration", "Stop",
      ])
  }

  @Test("round-trips through JSON")
  func codable() throws {
    let combo = KeyCombo(keyCode: escape, modifiers: [.control, .shift])
    let back = try JSONDecoder().decode(KeyCombo.self, from: JSONEncoder().encode(combo))
    #expect(back == combo)
  }
}
