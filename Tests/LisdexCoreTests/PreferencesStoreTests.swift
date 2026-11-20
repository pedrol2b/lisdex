import Foundation
import Testing

@testable import LisdexCore

@Suite("PreferencesStore")
struct PreferencesStoreTests {
  private func makeDefaults() -> UserDefaults {
    let suite = "lisdex.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return defaults
  }

  @Test("nothing stored → defaults, no error")
  func emptyStore() {
    let store = PreferencesStore(defaults: makeDefaults())

    let (settings, error) = store.loadSettings()

    #expect(settings == .default)
    #expect(error == nil)
  }

  @Test("saved settings round-trip under settings.v1")
  func roundTrip() throws {
    let defaults = makeDefaults()
    let store = PreferencesStore(defaults: defaults)
    let saved = AppSettings.default.with(
      mode: .duration, engine: .caffeinate, keepDisplayAwake: false, iconVariant: .mug)

    try store.save(saved)
    let (loaded, error) = store.loadSettings()

    #expect(loaded == saved)
    #expect(error == nil)
    #expect(defaults.data(forKey: "settings.v1") != nil)
  }

  @Test("corrupt data → defaults plus the decoding error")
  func corruptData() {
    let defaults = makeDefaults()
    defaults.set(Data("not json".utf8), forKey: "settings.v1")

    let (settings, error) = PreferencesStore(defaults: defaults).loadSettings()

    #expect(settings == .default)
    #expect(error != nil)
  }

  @Test("corrupt data is kept under settings.v1.corrupt before defaults replace it")
  func corruptDataIsKept() {
    let defaults = makeDefaults()
    let corrupt = Data("not json".utf8)
    defaults.set(corrupt, forKey: "settings.v1")

    _ = PreferencesStore(defaults: defaults).loadSettings()

    #expect(defaults.data(forKey: "settings.v1.corrupt") == corrupt)
  }
}
