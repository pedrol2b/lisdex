import Testing

@testable import LisdexCore

/// Records what a fake engine holds, in order, so tests can check there is never a gap.
@MainActor
private final class Ledger {
  var events: [String] = []
  var failNext = false
}

@MainActor
private final class FakeHold: PowerHold {
  let ledger: Ledger
  let name: String

  init(_ request: PowerRequest, ledger: Ledger) throws {
    if ledger.failNext {
      ledger.failNext = false
      throw FakeError.refused
    }
    self.ledger = ledger
    self.name = "\(request.engine.rawValue)/\(request.keepsDisplayAwake ? "display" : "system")"
    ledger.events.append("hold \(name)")
  }

  func release() {
    ledger.events.append("release \(name)")
  }
}

private enum FakeError: Error { case refused }

@MainActor
@Suite("PowerCoordinator")
struct PowerCoordinatorTests {
  private let ledger = Ledger()
  private let iokit = PowerRequest(engine: .iokit, keepsDisplayAwake: true, reason: "r")

  private func makeCoordinator() -> PowerCoordinator {
    let ledger = ledger
    return PowerCoordinator { try FakeHold($0, ledger: ledger) }
  }

  @Test("holds a request once; applying the same request again does nothing")
  func holdsOnce() throws {
    let coordinator = makeCoordinator()

    try coordinator.apply(iokit)
    try coordinator.apply(iokit)

    #expect(ledger.events == ["hold iokit/display"])
    #expect(coordinator.current == iokit)
  }

  @Test("nil releases the hold")
  func nilReleases() throws {
    let coordinator = makeCoordinator()

    try coordinator.apply(iokit)
    try coordinator.apply(nil)

    #expect(ledger.events == ["hold iokit/display", "release iokit/display"])
    #expect(coordinator.current == nil)
  }

  @Test("changing engine starts the new hold before releasing the old one (no sleep gap)")
  func switchWithoutGap() throws {
    let coordinator = makeCoordinator()
    let caffeinate = PowerRequest(engine: .caffeinate, keepsDisplayAwake: false, reason: "r")

    try coordinator.apply(iokit)
    try coordinator.apply(caffeinate)

    #expect(
      ledger.events == ["hold iokit/display", "hold caffeinate/system", "release iokit/display"])
    #expect(coordinator.current == caffeinate)
  }

  @Test("a failed hold throws and keeps the previous hold")
  func failureKeepsPrevious() throws {
    let coordinator = makeCoordinator()
    try coordinator.apply(iokit)
    ledger.failNext = true

    #expect(throws: FakeError.self) {
      try coordinator.apply(PowerRequest(engine: .caffeinate, keepsDisplayAwake: true, reason: "r"))
    }
    #expect(ledger.events == ["hold iokit/display"])
    #expect(coordinator.current == iokit)
  }
}
