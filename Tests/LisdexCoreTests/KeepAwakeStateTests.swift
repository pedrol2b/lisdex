import Testing

@testable import LisdexCore

@Suite("KeepAwakeState")
struct KeepAwakeStateTests {
  @Test("starts inactive in indefinite mode")
  func defaultState() {
    let state = KeepAwakeState()

    #expect(state.isOn == false)
    #expect(state.mode == .indefinitely)
  }

  @Test(
    "toggling returns a new value and never changes the selected mode",
    arguments: KeepAwakeMode.allCases)
  func togglePreservesMode(mode: KeepAwakeMode) {
    let original = KeepAwakeState(isOn: false, mode: mode)

    let toggledOn = original.toggled()
    let toggledOff = toggledOn.toggled()

    #expect(original.isOn == false)
    #expect(toggledOn == KeepAwakeState(isOn: true, mode: mode))
    #expect(toggledOff == original)
  }

  @Test("changing mode keeps the on/off state")
  func changingModeKeepsPower() {
    let state = KeepAwakeState(isOn: true, mode: .indefinitely)

    let changed = state.with(mode: .schedule)

    #expect(changed == KeepAwakeState(isOn: true, mode: .schedule))
    #expect(state.mode == .indefinitely)
  }

  @Test("setting on/off keeps the mode")
  func settingPowerKeepsMode() {
    let state = KeepAwakeState(isOn: false, mode: .duration)

    #expect(state.with(isOn: true) == KeepAwakeState(isOn: true, mode: .duration))
  }

  @Test("each mode has a menu title and SF Symbol")
  func modeLabels() {
    #expect(KeepAwakeMode.indefinitely.title == "Indefinitely")
    #expect(KeepAwakeMode.duration.title == "For a Duration")
    #expect(KeepAwakeMode.schedule.title == "On a Schedule")
    #expect(Set(KeepAwakeMode.allCases.map(\.symbolName)).count == KeepAwakeMode.allCases.count)
  }
}
