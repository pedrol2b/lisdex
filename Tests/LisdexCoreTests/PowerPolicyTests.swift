import Testing

@testable import LisdexCore

@Suite("Power source policies")
struct PowerPolicyTests {
  private let mains = PowerSource(isOnBattery: false, batteryPercent: 15)

  @Test("display sleep on battery: only when allowed and actually on battery")
  func displaySleepOnBattery() {
    let allowing = AppSettings.default.with(allowDisplaySleepOnBattery: true)
    let onBattery = PowerSource(isOnBattery: true, batteryPercent: 80)

    #expect(
      PowerRequest(plan: .holding(until: nil), settings: allowing, power: onBattery)?
        .keepsDisplayAwake == false)
    #expect(
      PowerRequest(plan: .holding(until: nil), settings: allowing, power: mains)?.keepsDisplayAwake
        == true)
    #expect(
      PowerRequest(plan: .holding(until: nil), settings: .default, power: onBattery)?
        .keepsDisplayAwake == true)
  }

  @Test("battery cutoff: stops at or below the threshold, only on battery")
  func batteryCutoff() {
    let settings = AppSettings.default.with(batteryStopThreshold: .below20)

    #expect(
      BatteryCutoff.shouldStop(
        settings: settings, power: PowerSource(isOnBattery: true, batteryPercent: 20)))
    #expect(
      !BatteryCutoff.shouldStop(
        settings: settings, power: PowerSource(isOnBattery: true, batteryPercent: 21)))
    #expect(!BatteryCutoff.shouldStop(settings: settings, power: mains))
    #expect(
      !BatteryCutoff.shouldStop(
        settings: .default, power: PowerSource(isOnBattery: true, batteryPercent: 1)))
    #expect(
      !BatteryCutoff.shouldStop(
        settings: settings, power: PowerSource(isOnBattery: true, batteryPercent: nil)))
  }

  @Test("thresholds and their labels")
  func thresholds() {
    #expect(BatteryThreshold.allCases.map(\.percent) == [nil, 10, 20])
    #expect(BatteryThreshold.allCases.map(\.title) == ["Off", "10 %", "20 %"])
  }

  @Test("accent presets: gold first, distinct colours")
  func accents() {
    #expect(AccentChoice.default == .gold)
    #expect(AccentChoice.gold.rgb == 0xF4C85B)
    #expect(Set(AccentChoice.allCases.map(\.rgb)).count == AccentChoice.allCases.count)
  }
}
