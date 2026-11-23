import Foundation

/// An app from Settings → Apps: while it is open, Keep Awake stays on (spec app-trigger).
public struct AppTrigger: Codable, Hashable, Sendable {
  public let bundleID: String
  public let name: String

  public init(bundleID: String, name: String) {
    self.bundleID = bundleID
    self.name = name
  }
}

/// The user's trigger apps, in the order they were added. Empty by default; blank and
/// duplicate bundle IDs are dropped (the first one wins). Stored as a plain JSON array whose
/// bad entries are skipped on load instead of losing the rest.
public struct AppTriggers: Codable, Equatable, Sendable {
  public static let empty = AppTriggers([])

  public let apps: [AppTrigger]

  public init(_ apps: [AppTrigger]) {
    var seen = Set<String>()
    self.apps = apps.filter { !$0.bundleID.isEmpty && seen.insert($0.bundleID).inserted }
  }

  public var bundleIDs: Set<String> { Set(apps.map(\.bundleID)) }

  public func contains(bundleID: String) -> Bool { apps.contains { $0.bundleID == bundleID } }

  public func adding(_ app: AppTrigger) -> AppTriggers { AppTriggers(apps + [app]) }

  public func removing(bundleID: String) -> AppTriggers {
    AppTriggers(apps.filter { $0.bundleID != bundleID })
  }

  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    var apps: [AppTrigger] = []
    while !container.isAtEnd {
      if let app = try? container.decode(AppTrigger.self) {
        apps.append(app)
      } else {
        _ = try? container.decode(Skipped.self)
      }
    }
    self.init(apps)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(apps)
  }

  /// Consumes one undecodable array element so decoding can move past it.
  private struct Skipped: Decodable {
    init(from decoder: Decoder) throws {}
  }
}
