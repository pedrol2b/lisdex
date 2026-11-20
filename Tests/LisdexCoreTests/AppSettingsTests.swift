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
}
