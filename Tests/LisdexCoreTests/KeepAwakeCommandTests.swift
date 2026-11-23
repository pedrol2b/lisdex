import Foundation
import Testing

@testable import LisdexCore

@Suite("lisdex:// links")
struct KeepAwakeCommandTests {
  private func command(_ text: String) -> KeepAwakeCommand? {
    URL(string: text).flatMap(KeepAwakeCommand.init(url:))
  }

  @Test("on, off and toggle")
  func basics() {
    #expect(command("lisdex://on") == .turnOn(.currentMode))
    #expect(command("lisdex://off") == .turnOff)
    #expect(command("lisdex://toggle") == .toggle)
    #expect(command("LISDEX://ON") == .turnOn(.currentMode))
  }

  @Test("on for some minutes, or until stopped")
  func lengths() {
    #expect(command("lisdex://on?minutes=90") == .turnOn(.minutes(90)))
    #expect(command("lisdex://on?minutes=1440") == .turnOn(.minutes(1440)))
    #expect(command("lisdex://on?until=stopped") == .turnOn(.untilStopped))
  }

  @Test(
    "anything else is ignored",
    arguments: [
      "lisdex://on?minutes=0", "lisdex://on?minutes=1441", "lisdex://on?minutes=abc",
      "lisdex://on?until=later", "lisdex://sleep", "https://on", "lisdex:",
    ])
  func ignored(_ text: String) {
    #expect(command(text) == nil)
  }
}
