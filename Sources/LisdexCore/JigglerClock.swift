import Foundation

/// Decides when the mouse jiggler acts (spec mouse-jiggler). Pure: the app layer feeds it the
/// system idle time and whether a key or mouse button is held, then posts the event and arms
/// one timer for `nextCheck`.
///
/// The system idle time also resets on Lisdex's own events, so the clock remembers its last
/// jiggle: a latest event within `ownEventTolerance` of it is Lisdex's, anything else is the
/// user's and restarts the idle wait.
public struct JigglerClock: Sendable {
  public static let ownEventTolerance: TimeInterval = 1
  /// Never check again sooner than this, so an early timer can't spin.
  public static let minimumDelay: TimeInterval = 1

  public struct State: Equatable, Sendable {
    public static let initial = State(lastRealInput: nil, lastJiggle: nil)
    /// The user's last input as far as the clock knows.
    public let lastRealInput: Date?
    public let lastJiggle: Date?

    public init(lastRealInput: Date?, lastJiggle: Date?) {
      self.lastRealInput = lastRealInput
      self.lastJiggle = lastJiggle
    }
  }

  public struct Step: Equatable, Sendable {
    public let jiggle: Bool
    public let nextCheck: Date
    public let state: State
  }

  public let settings: JigglerSettings

  public init(settings: JigglerSettings) {
    self.settings = settings
  }

  public func step(now: Date, idleSeconds: TimeInterval, inputHeld: Bool, state: State) -> Step {
    let observed = observe(now: now, idleSeconds: idleSeconds, inputHeld: inputHeld, state: state)
    let realInput = observed.lastRealInput ?? now
    let idleStart = realInput + settings.idleThreshold
    if now < idleStart {
      return finish(jiggle: false, nextCheck: idleStart, state: observed, now: now)
    }
    if let lastJiggle = observed.lastJiggle, now < lastJiggle + settings.interval {
      return finish(
        jiggle: false, nextCheck: lastJiggle + settings.interval, state: observed, now: now)
    }
    return finish(
      jiggle: true, nextCheck: now + settings.interval,
      state: State(lastRealInput: realInput, lastJiggle: now), now: now)
  }

  /// Who caused the latest input event: the user (restart the wait) or Lisdex (keep it).
  private func observe(
    now: Date, idleSeconds: TimeInterval, inputHeld: Bool, state: State
  ) -> State {
    if inputHeld { return State(lastRealInput: now, lastJiggle: nil) }
    let latest = now - max(0, idleSeconds)
    if let lastJiggle = state.lastJiggle,
      abs(latest.timeIntervalSince(lastJiggle)) <= Self.ownEventTolerance
    {
      return State(lastRealInput: state.lastRealInput ?? lastJiggle, lastJiggle: lastJiggle)
    }
    return State(lastRealInput: latest, lastJiggle: nil)
  }

  private func finish(jiggle: Bool, nextCheck: Date, state: State, now: Date) -> Step {
    Step(jiggle: jiggle, nextCheck: max(nextCheck, now + Self.minimumDelay), state: state)
  }
}
