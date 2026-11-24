import Foundation
import Testing

@testable import LisdexCore

@Suite("MenuBarBadge")
struct MenuBarBadgeTests {
  private let now = Date(timeIntervalSince1970: 1_800_000_000)

  @Test("off: the badge shows the selected mode", arguments: KeepAwakeMode.allCases)
  func offShowsSelectedMode(mode: KeepAwakeMode) {
    #expect(MenuBarBadge.resolve(session: nil, mode: mode) == MenuBarBadge(rawValue: mode.rawValue))
  }

  @Test("a user session follows the mode", arguments: KeepAwakeMode.allCases)
  func userSessionFollowsMode(mode: KeepAwakeMode) {
    let session = Session.start(mode: mode, duration: 3600, now: now)
    #expect(
      MenuBarBadge.resolve(session: session, mode: mode) == MenuBarBadge(rawValue: mode.rawValue))
  }

  @Test("a link or action with its own length beats the selected mode")
  func fixedLengthBeatsMode() {
    #expect(
      MenuBarBadge.resolve(session: .fixed(minutes: 90, now: now), mode: .indefinitely) == .duration
    )
    #expect(
      MenuBarBadge.resolve(session: .fixed(minutes: nil, now: now), mode: .schedule)
        == .indefinitely)
  }

  @Test(
    "app and Focus sessions hold until they end: ∞", arguments: [KeepAwakeMode.schedule, .duration])
  func appAndFocusAreUntilStopped(mode: KeepAwakeMode) {
    #expect(MenuBarBadge.resolve(session: .startedByApp(now: now), mode: mode) == .indefinitely)
    #expect(MenuBarBadge.resolve(session: .startedByFocus(now: now), mode: mode) == .indefinitely)
  }

  @Test("spoken names for VoiceOver")
  func spokenNames() {
    #expect(
      MenuBarBadge.allCases.map(\.spokenName) == [
        "indefinitely", "for a duration", "on a schedule",
      ])
  }
}
