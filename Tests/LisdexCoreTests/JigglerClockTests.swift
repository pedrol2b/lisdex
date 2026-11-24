import Foundation
import Testing

@testable import LisdexCore

@Suite("JigglerClock")
struct JigglerClockTests {
  let clock = JigglerClock(
    settings: JigglerSettings(isEnabled: true, idleThreshold: 60, interval: 20))
  let t0 = Date(timeIntervalSinceReferenceDate: 0)

  private func afterFirstJiggle() -> JigglerClock.State {
    clock.step(now: t0, idleSeconds: 60, inputHeld: false, state: .initial).state
  }

  @Test("waits until the user has been idle for the threshold")
  func waitsUntilThreshold() {
    let step = clock.step(now: t0, idleSeconds: 10, inputHeld: false, state: .initial)
    #expect(step.jiggle == false)
    #expect(step.nextCheck == t0 + 50)
  }

  @Test("jiggles once the threshold is reached and checks again after the interval")
  func jigglesAfterThreshold() {
    let step = clock.step(now: t0, idleSeconds: 60, inputHeld: false, state: .initial)
    #expect(step.jiggle == true)
    #expect(step.nextCheck == t0 + 20)
    #expect(step.state.lastJiggle == t0)
    #expect(step.state.lastRealInput == t0 - 60)
  }

  @Test("Lisdex's own jiggle is not mistaken for the user's input")
  func ownJiggleIsNotUserInput() {
    let step = clock.step(
      now: t0 + 20, idleSeconds: 20, inputHeld: false, state: afterFirstJiggle())
    #expect(step.jiggle == true)
    #expect(step.state.lastRealInput == t0 - 60)
    #expect(step.state.lastJiggle == t0 + 20)
  }

  @Test("between jiggles it waits for the interval")
  func waitsBetweenJiggles() {
    let step = clock.step(now: t0 + 5, idleSeconds: 5, inputHeld: false, state: afterFirstJiggle())
    #expect(step.jiggle == false)
    #expect(step.nextCheck == t0 + 20)
  }

  @Test("real input restarts the idle wait")
  func realInputRestartsWait() {
    let step = clock.step(now: t0 + 20, idleSeconds: 3, inputHeld: false, state: afterFirstJiggle())
    #expect(step.jiggle == false)
    #expect(step.state.lastJiggle == nil)
    #expect(step.state.lastRealInput == t0 + 17)
    #expect(step.nextCheck == t0 + 77)
  }

  @Test("a held key or mouse button counts as input now")
  func heldInputBlocksJiggle() {
    let step = clock.step(now: t0, idleSeconds: 300, inputHeld: true, state: afterFirstJiggle())
    #expect(step.jiggle == false)
    #expect(step.state.lastRealInput == t0)
    #expect(step.state.lastJiggle == nil)
    #expect(step.nextCheck == t0 + 60)
  }

  @Test("a timer that fires a little early reschedules at least a second later")
  func earlyFireReschedules() {
    let step = clock.step(now: t0, idleSeconds: 59.8, inputHeld: false, state: .initial)
    #expect(step.jiggle == false)
    #expect(step.nextCheck == t0 + 1)
  }

  @Test("paused (screen locked or display asleep): no jiggle, idle wait starts over afterwards")
  func pausedNeverJiggles() {
    let step = clock.step(
      now: t0 + 20, idleSeconds: 20, inputHeld: false, paused: true, state: afterFirstJiggle())
    #expect(step.jiggle == false)
    #expect(step.state == .initial)
    #expect(step.nextCheck == t0 + 40)
  }
}
