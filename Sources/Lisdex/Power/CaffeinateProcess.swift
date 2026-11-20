import Foundation
import LisdexCore

/// Opt-in engine (ADR 0002): `/usr/bin/caffeinate -i [-d] -w <pid>`. `-w` ties it to Lisdex's
/// lifetime, so it exits even if Lisdex crashes. If it dies while still wanted (e.g. killed by
/// a management tool) it is restarted a few times, then `onGiveUp` reports the failure.
@MainActor
final class CaffeinateProcess: PowerHold {
  static let executable = URL(fileURLWithPath: "/usr/bin/caffeinate")
  static let maxRestarts = 3
  /// A run at least this long counts as healthy and resets the restart budget, so unrelated
  /// kills spread over a multi-day session don't add up to giving up.
  static let healthyRun: TimeInterval = 60

  private let arguments: [String]
  private let onGiveUp: @MainActor () -> Void
  private var process: Process?
  private var restarts = 0
  private var launchedAt = Date.distantPast
  private var isReleased = false

  init(_ request: PowerRequest, onGiveUp: @escaping @MainActor () -> Void) throws {
    self.arguments = request.caffeinateArguments(
      watching: ProcessInfo.processInfo.processIdentifier)
    self.onGiveUp = onGiveUp
    try launch()
  }

  func release() {
    isReleased = true
    process?.terminate()
    process = nil
    Log.power.notice("caffeinate released")
  }

  private func launch() throws {
    let process = Process()
    process.executableURL = Self.executable
    process.arguments = arguments
    process.terminationHandler = { [weak self] finished in
      let status = finished.terminationStatus
      Task { @MainActor in self?.didExit(finished, status: status) }
    }
    try process.run()
    self.process = process
    launchedAt = .now
    Log.power.notice(
      "caffeinate started (pid \(process.processIdentifier, privacy: .public)): \(self.arguments.joined(separator: " "), privacy: .public)"
    )
  }

  private func didExit(_ finished: Process, status: Int32) {
    guard !isReleased, finished === process else { return }
    Log.power.error("caffeinate exited unexpectedly (status \(status, privacy: .public))")
    if Date.now.timeIntervalSince(launchedAt) >= Self.healthyRun { restarts = 0 }
    guard restarts < Self.maxRestarts else {
      process = nil
      onGiveUp()
      return
    }
    restarts += 1
    do {
      try launch()
    } catch {
      Log.power.error("caffeinate restart failed: \(error.localizedDescription, privacy: .public)")
      process = nil
      onGiveUp()
    }
  }
}
