import Foundation

/// Persists `AppSettings` as JSON in `UserDefaults` under `settings.v1` (ADR 0006).
public struct PreferencesStore: @unchecked Sendable {
  static let settingsKey = "settings.v1"
  /// Unreadable settings are copied here before defaults replace them, so they can be recovered.
  static let corruptKey = "settings.v1.corrupt"

  private let defaults: UserDefaults

  public init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  /// Stored settings, or defaults if absent or corrupt (the error is returned for logging and the
  /// unreadable data is kept under `settings.v1.corrupt`).
  public func loadSettings() -> (settings: AppSettings, error: Error?) {
    guard let data = defaults.data(forKey: Self.settingsKey) else { return (.default, nil) }
    do {
      return (try JSONDecoder().decode(AppSettings.self, from: data), nil)
    } catch {
      defaults.set(data, forKey: Self.corruptKey)
      return (.default, error)
    }
  }

  public func save(_ settings: AppSettings) throws {
    defaults.set(try JSONEncoder().encode(settings), forKey: Self.settingsKey)
  }
}
