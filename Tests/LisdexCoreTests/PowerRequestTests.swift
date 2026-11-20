import Testing

@testable import LisdexCore

@Suite("PowerRequest")
struct PowerRequestTests {
  @Test(
    "plans that don't hold → no request",
    arguments: [SessionPlan.off, .expired, .waiting(next: nil)])
  func notHolding(plan: SessionPlan) {
    #expect(PowerRequest(plan: plan, settings: .default) == nil)
  }

  @Test("holding → engine and display flag from settings, reason names the mode")
  func holdingBuildsRequest() {
    let settings = AppSettings.default.with(
      mode: .duration, engine: .caffeinate, keepDisplayAwake: false)

    let request = PowerRequest(plan: .holding(until: nil), settings: settings)

    #expect(
      request
        == PowerRequest(
          engine: .caffeinate, keepsDisplayAwake: false, reason: "Lisdex: For a Duration"))
  }

  @Test("caffeinate arguments: idle sleep, optional display, tied to our pid")
  func caffeinateArguments() {
    let withDisplay = PowerRequest(engine: .caffeinate, keepsDisplayAwake: true, reason: "r")
    let withoutDisplay = PowerRequest(engine: .caffeinate, keepsDisplayAwake: false, reason: "r")

    #expect(withDisplay.caffeinateArguments(watching: 42) == ["-i", "-d", "-w", "42"])
    #expect(withoutDisplay.caffeinateArguments(watching: 42) == ["-i", "-w", "42"])
  }
}
