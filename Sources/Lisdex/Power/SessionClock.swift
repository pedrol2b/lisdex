import AppKit

/// Wakes `AppModel` when its plan has to be recomputed: at the plan's next check time, and
/// whenever wall-clock time may have jumped (wake from sleep, clock or time-zone change, new
/// day). Timers don't fire during sleep, so the wake observer is what keeps deadlines exact.
@MainActor
final class SessionClock {
  /// Small tolerance keeps expiry within the spec's 1 s while letting macOS coalesce wakeups.
  static let tolerance: TimeInterval = 0.2

  private let onTick: @MainActor () -> Void
  private var timer: Timer?
  private var observers: [(NotificationCenter, NSObjectProtocol)] = []

  init(onTick: @escaping @MainActor () -> Void) {
    self.onTick = onTick
    observe(NSWorkspace.shared.notificationCenter, NSWorkspace.didWakeNotification)
    for name in [
      Notification.Name.NSSystemClockDidChange, .NSSystemTimeZoneDidChange, .NSCalendarDayChanged,
    ] {
      observe(.default, name)
    }
  }

  /// Fire once at `date` (replacing any earlier request); `nil` cancels.
  func schedule(at date: Date?) {
    timer?.invalidate()
    timer = nil
    guard let date else { return }
    let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.onTick() }
    }
    timer.tolerance = Self.tolerance
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func observe(_ center: NotificationCenter, _ name: Notification.Name) {
    let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
      MainActor.assumeIsolated { self?.onTick() }
    }
    observers.append((center, token))
  }

  isolated deinit {
    timer?.invalidate()
    for (center, token) in observers { center.removeObserver(token) }
  }
}
