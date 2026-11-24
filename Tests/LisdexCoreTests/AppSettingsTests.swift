import Foundation
import Testing

@testable import LisdexCore

@Suite("AppSettings")
struct AppSettingsTests {
  @Test("defaults: indefinite mode, IOKit engine, display kept awake, pill icon")
  func defaults() {
    let settings = AppSettings.default

    #expect(settings.mode == .indefinitely)
    #expect(settings.engine == .iokit)
    #expect(settings.keepDisplayAwake == true)
    #expect(settings.iconVariant == .pill)
    #expect(settings.duration == 3600)
    #expect(settings.schedule == .default)
    #expect(settings.activateOnLaunch == false)
    #expect(settings.notifyOnSessionEnd == true)
    #expect(settings.allowDisplaySleepOnBattery == false)
    #expect(settings.batteryStopThreshold == .off)
    #expect(settings.accent == .gold)
  }

  @Test("with(...) returns a changed copy and leaves the original untouched")
  func withReturnsCopy() {
    let original = AppSettings.default

    let changed = original.with(mode: .schedule, engine: .caffeinate)

    #expect(changed.mode == .schedule)
    #expect(changed.engine == .caffeinate)
    #expect(changed.keepDisplayAwake == original.keepDisplayAwake)
    #expect(original == .default)
  }

  @Test("decoding an empty object falls back to defaults")
  func missingKeys() throws {
    let decoded = try JSONDecoder().decode(AppSettings.self, from: Data("{}".utf8))

    #expect(decoded == .default)
  }

  @Test("unknown enum values fall back per field instead of failing")
  func unknownEnumValues() throws {
    let json = #"{"mode":"forever","engine":"warp","keepDisplayAwake":false,"iconVariant":"neon"}"#

    let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

    #expect(decoded == AppSettings.default.with(keepDisplayAwake: false))
  }

  @Test("an invalid schedule or duration falls back to the defaults")
  func invalidScheduleAndDuration() throws {
    let json = #"{"schedule":{"days":[2],"start":-5,"end":600},"duration":-30}"#

    let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

    #expect(decoded.schedule == .default)
    #expect(decoded.duration == AppSettings.default.duration)
  }

  @Test("Phase 4 fields round-trip and tolerate unknown values")
  func phase4Fields() throws {
    let saved = AppSettings.default.with(
      activateOnLaunch: true, notifyOnSessionEnd: false, allowDisplaySleepOnBattery: true,
      batteryStopThreshold: .below10, accent: .mint)

    let decoded = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(saved))
    let unknown = try JSONDecoder().decode(
      AppSettings.self, from: Data(#"{"batteryStopThreshold":"below5","accent":"chartreuse"}"#.utf8)
    )

    #expect(decoded == saved)
    #expect(unknown.batteryStopThreshold == .off)
    #expect(unknown.accent == .gold)
  }

  @Test("jiggler settings round-trip; a bad value falls back without losing the rest")
  func jigglerRoundTrip() throws {
    #expect(AppSettings.default.jiggler == .default)
    let settings = AppSettings.default.with(
      jiggler: JigglerSettings(isEnabled: true, idleThreshold: 120, interval: 30))
    let data = try JSONEncoder().encode(settings)
    #expect(try JSONDecoder().decode(AppSettings.self, from: data) == settings)

    let bad = #"{"jiggler": 5, "mode": "schedule"}"#
    let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(bad.utf8))
    #expect(decoded.jiggler == .default)
    #expect(decoded.mode == .schedule)
  }

  @Test("the mode badge is off by default and round-trips")
  func modeBadgeDefaultsOffAndRoundTrips() throws {
    #expect(AppSettings.default.showsModeBadge == false)
    let settings = AppSettings.default.with(showsModeBadge: true)
    let data = try JSONEncoder().encode(settings)
    #expect(try JSONDecoder().decode(AppSettings.self, from: data).showsModeBadge == true)
  }

  @Test("settings from 1.2 (no key) or a bad value leave the mode badge off")
  func modeBadgeMissingKeyIsOff() throws {
    let old = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"mode":"duration"}"#.utf8))
    #expect(old.showsModeBadge == false)
    let bad = try JSONDecoder().decode(
      AppSettings.self, from: Data(#"{"mode":"duration","showsModeBadge":"yes"}"#.utf8))
    #expect(bad.showsModeBadge == false)
    #expect(bad.mode == .duration)
  }
}
