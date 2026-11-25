/// Which glyph the status item uses (ADR 0029). The app icon is always the capsule.
public enum MenuBarIconVariant: String, CaseIterable, Sendable {
  /// Diagonal capsule, outlined when off, filled when on. The default; matches the app icon.
  case capsule
  /// Lisdexamfetamine's ring and side chain, 32 pt wide.
  case molecule
  /// Coffee cup with steam.
  case coffee

  public static let `default`: MenuBarIconVariant = .capsule

  /// Names saved by earlier versions (ADR 0015): the pill and the retired light bulb become the
  /// capsule, the mug becomes the coffee cup.
  private static let aliases: [String: MenuBarIconVariant] = [
    "pill": .capsule, "bulb": .capsule, "mug": .coffee,
  ]

  /// A saved name, current or from an earlier version; `nil` when unknown.
  public init?(storedName: String) {
    guard let variant = MenuBarIconVariant(rawValue: storedName) ?? Self.aliases[storedName]
    else { return nil }
    self = variant
  }

  public var title: String {
    switch self {
    case .capsule: "Capsule"
    case .molecule: "Molecule"
    case .coffee: "Coffee"
    }
  }
}

/// Stored by its new name; reads earlier names through `init(storedName:)`. Unknown names fail,
/// and `AppSettings` falls back to the default (ADR 0006).
extension MenuBarIconVariant: Codable {
  public init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    guard let variant = MenuBarIconVariant(storedName: raw) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "unknown icon variant: \(raw)"))
    }
    self = variant
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

/// Resolves the status item image for a variant and state.
public struct MenuBarIcon: Equatable, Sendable {
  public let variant: MenuBarIconVariant
  public let isActive: Bool
  /// The mode badge, when Settings → Appearance shows it (ADR 0025); `nil` = plain icon.
  public let badge: MenuBarBadge?

  public init(variant: MenuBarIconVariant, isActive: Bool, badge: MenuBarBadge? = nil) {
    self.variant = variant
    self.isActive = isActive
    self.badge = badge
  }

  /// Base name of the template PDF bundled in `Contents/Resources` (from `assets/menubar/`).
  public var resourceName: String {
    let state = isActive ? "active" : "inactive"
    guard let badge else { return "\(variant.rawValue)-\(state)" }
    return "\(variant.rawValue)-\(badge.rawValue)-\(state)"
  }

  public var accessibilityLabel: String {
    let base = "Lisdex — Keep Awake \(isActive ? "on" : "off")"
    guard let badge else { return base }
    return "\(base), \(badge.spokenName)"
  }
}
