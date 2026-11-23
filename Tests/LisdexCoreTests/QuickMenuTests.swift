import Foundation
import Testing

@testable import LisdexCore

@Suite("QuickMenu")
struct QuickMenuTests {
  @Test("off: the four presets, then Until I Stop; no Stop item")
  func whenOff() {
    #expect(
      QuickMenu.items(isOn: false) == [
        .duration(900), .duration(1800), .duration(3600), .duration(7200), .indefinitely,
      ])
  }

  @Test("on: Stop is added at the end")
  func whenOn() {
    #expect(QuickMenu.items(isOn: true).last == .stop)
    #expect(QuickMenu.items(isOn: true).count == 6)
  }

  @Test("titles use macOS menu title case")
  func titles() {
    #expect(QuickMenu.title == "Keep Awake for…")
    #expect(
      QuickMenu.items(isOn: true).map(\.title) == [
        "15 Minutes", "30 Minutes", "1 Hour", "2 Hours", "Until I Stop", "Stop",
      ])
  }
}
