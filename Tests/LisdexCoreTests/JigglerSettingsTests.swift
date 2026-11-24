import Foundation
import Testing

@testable import LisdexCore

@Suite("JigglerSettings")
struct JigglerSettingsTests {
  @Test("defaults: off, 60 s idle threshold, 20 s interval")
  func defaults() {
    #expect(JigglerSettings.default.isEnabled == false)
    #expect(JigglerSettings.default.idleThreshold == 60)
    #expect(JigglerSettings.default.interval == 20)
  }

  @Test("values are clamped to the slider ranges; non-finite values use the defaults")
  func clamps() {
    let high = JigglerSettings(idleThreshold: 9999, interval: 1)
    #expect(high.idleThreshold == 240)
    #expect(high.interval == 10)

    let nan = JigglerSettings(idleThreshold: .nan, interval: .infinity)
    #expect(nan.idleThreshold == 60)
    #expect(nan.interval == 20)
  }

  @Test("decoding keeps good keys and falls back per key")
  func tolerantDecoding() throws {
    let json = #"{"isEnabled":true,"interval":"x","idleThreshold":9999}"#
    let decoded = try JSONDecoder().decode(JigglerSettings.self, from: Data(json.utf8))
    #expect(decoded == JigglerSettings(isEnabled: true, idleThreshold: 240, interval: 20))

    let empty = try JSONDecoder().decode(JigglerSettings.self, from: Data("{}".utf8))
    #expect(empty == .default)
  }

  @Test("with(...) changes only the given fields")
  func withCopy() {
    let changed = JigglerSettings.default.with(isEnabled: true, interval: 30)
    #expect(changed == JigglerSettings(isEnabled: true, idleThreshold: 60, interval: 30))
  }

  @Test("labels read as seconds and minutes")
  func labels() {
    #expect(JigglerSettings.label(seconds: 30) == "30 s")
    #expect(JigglerSettings.label(seconds: 60) == "1 min")
    #expect(JigglerSettings.label(seconds: 90) == "1 min 30 s")
    #expect(JigglerSettings.label(seconds: 240) == "4 min")
  }
}
