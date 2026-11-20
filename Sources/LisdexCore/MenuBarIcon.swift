/// Which glyph the status item uses (ADR 0015). The app icon is always the pill.
public enum MenuBarIconVariant: String, Codable, CaseIterable, Sendable {
  /// Round capsule pill, outlined when off, filled when on. The default; matches the app icon.
  case pill
  /// Coffee mug, the familiar alternative.
  case mug

  public static let `default`: MenuBarIconVariant = .pill

  public var title: String {
    switch self {
    case .pill: "Pill"
    case .mug: "Coffee mug"
    }
  }
}

/// Resolves the status item image for a variant and state.
public struct MenuBarIcon: Equatable, Sendable {
  public let variant: MenuBarIconVariant
  public let isActive: Bool

  public init(variant: MenuBarIconVariant, isActive: Bool) {
    self.variant = variant
    self.isActive = isActive
  }

  /// Base name of the template PDF bundled in `Contents/Resources` (from `assets/menubar/`).
  public var resourceName: String {
    "\(variant.rawValue)-\(isActive ? "active" : "inactive")"
  }

  public var accessibilityLabel: String {
    "Lisdex — Keep Awake \(isActive ? "on" : "off")"
  }
}
