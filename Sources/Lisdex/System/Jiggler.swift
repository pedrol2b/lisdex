import CoreGraphics
import Foundation
import LisdexCore

/// Keeps chat apps from marking the user Away (spec mouse-jiggler, ADR 0024): while running it
/// posts a 0 px mouse move at the cursor whenever `JigglerClock` says so. One timer, armed for
/// the clock's next check; no fixed polling.
@MainActor
final class Jiggler {
  private var settings: JigglerSettings?
  private var state = JigglerClock.State.initial
  private var timer: Timer?
  /// Keeps App Nap from delaying the timer while the jiggler runs (e.g. with the caffeinate
  /// engine Lisdex itself holds no power assertion).
  private var activity: NSObjectProtocol?

  /// `nil` stops it. The same settings again keep the current timer and state.
  func run(_ settings: JigglerSettings?) {
    guard settings != self.settings else { return }
    self.settings = settings
    timer?.invalidate()
    timer = nil
    state = .initial
    if settings == nil {
      activity.map(ProcessInfo.processInfo.endActivity)
      activity = nil
      Log.jiggler.notice("Jiggler stopped")
    } else {
      if activity == nil {
        activity = ProcessInfo.processInfo.beginActivity(
          options: .userInitiatedAllowingIdleSystemSleep,
          reason: "Mouse jiggler keeps chat apps from going Away")
      }
      Log.jiggler.notice("Jiggler running")
      tick()
    }
  }

  private func tick() {
    guard let settings else { return }
    let step = JigglerClock(settings: settings).step(
      now: .now, idleSeconds: Self.idleSeconds, inputHeld: Self.isInputHeld,
      paused: Self.isScreenLocked || CGDisplayIsAsleep(CGMainDisplayID()) != 0, state: state)
    state = step.state
    if step.jiggle { Self.postMouseMove() }
    schedule(at: step.nextCheck)
  }

  private func schedule(at date: Date) {
    let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
      MainActor.assumeIsolated { self?.tick() }
    }
    timer.tolerance = 0.5
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  // MARK: - CoreGraphics

  /// Seconds since the last keyboard or mouse event of any kind, ours included.
  private static var idleSeconds: TimeInterval {
    guard let anyInput = CGEventType(rawValue: ~0) else { return 0 }
    return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
  }

  /// A key or mouse button held down: the user is busy (dragging, holding a key) even though
  /// no new event arrives.
  private static var isInputHeld: Bool {
    let buttons: [CGMouseButton] = [.left, .right, .center]
    if buttons.contains(where: { CGEventSource.buttonState(.combinedSessionState, button: $0) }) {
      return true
    }
    return (0..<128).contains {
      !toggleKeys.contains($0) && CGEventSource.keyState(.combinedSessionState, key: CGKeyCode($0))
    }
  }

  /// Caps Lock and fn can report their toggle state rather than a physical press.
  private static let toggleKeys: Set<Int> = [57, 63]

  private static var isScreenLocked: Bool {
    let session = CGSessionCopyCurrentDictionary() as? [String: Any]
    return session?["CGSSessionScreenIsLocked"] as? Bool ?? false
  }

  private static func postMouseMove() {
    let location = CGEvent(source: nil)?.location ?? .zero
    guard
      let event = CGEvent(
        mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: location,
        mouseButton: .left)
    else {
      Log.jiggler.error("Couldn't create the mouse event")
      return
    }
    event.post(tap: .cghidEventTap)
    Log.jiggler.debug("Jiggled")
  }
}
