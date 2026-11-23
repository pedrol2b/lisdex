/// Modifier keys of a shortcut. Stored as a small bit set in `settings.v1`.
public struct KeyModifiers: OptionSet, Codable, Hashable, Sendable {
  public let rawValue: UInt8
  public init(rawValue: UInt8) { self.rawValue = rawValue }

  public static let control = KeyModifiers(rawValue: 1 << 0)
  public static let option = KeyModifiers(rawValue: 1 << 1)
  public static let shift = KeyModifiers(rawValue: 1 << 2)
  public static let command = KeyModifiers(rawValue: 1 << 3)

  /// Glyphs in the order macOS menus use: ⌃⌥⇧⌘.
  public var symbols: String {
    let ordered: [(KeyModifiers, String)] = [
      (.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘"),
    ]
    return ordered.filter { contains($0.0) }.map(\.1).joined()
  }
}

/// A global shortcut: a virtual key code (physical key, `kVK_*`) plus modifiers.
public struct KeyCombo: Codable, Hashable, Sendable {
  public let keyCode: UInt16
  public let modifiers: KeyModifiers

  public init(keyCode: UInt16, modifiers: KeyModifiers) {
    self.keyCode = keyCode
    self.modifiers = modifiers
  }

  /// Names for keys whose label doesn't come from the keyboard layout (`kVK_*` codes).
  public static func specialKeyName(_ keyCode: UInt16) -> String? {
    specialKeyNames[keyCode] ?? functionKeyCodes.firstIndex(of: keyCode).map { "F\($0 + 1)" }
  }

  public var isFunctionKey: Bool { Self.functionKeyCodes.contains(keyCode) }

  /// e.g. "⌃⌥⌘L". `keyName` is what the current layout types for `keyCode`.
  public func displayString(keyName: String) -> String {
    modifiers.symbols + (Self.specialKeyName(keyCode) ?? keyName.uppercased())
  }

  /// Why this combo can't be assigned to `action`, or `nil` when it can.
  public func problem(
    keyName: String, action: ShortcutAction, assigned: [ShortcutAction: KeyCombo]
  ) -> KeyComboProblem? {
    if !isFunctionKey && modifiers.isDisjoint(with: [.control, .option, .command]) {
      return .needsModifier
    }
    if Self.reserved.contains(where: { $0.matches(self, keyName: keyName) }) {
      return .reservedBySystem
    }
    if let other = assigned.first(where: { $0.key != action && $0.value == self }) {
      return .usedBy(other.key)
    }
    return nil
  }

  // MARK: Tables

  private static let specialKeyNames: [UInt16: String] = [
    36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 117: "⌦",
    115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
    123: "←", 124: "→", 125: "↓", 126: "↑",
  ]

  /// kVK_F1 … kVK_F20, in order.
  private static let functionKeyCodes: [UInt16] = [
    122, 120, 99, 118, 96, 97, 98, 100, 101, 109,
    103, 111, 105, 107, 113, 106, 64, 79, 80, 90,
  ]

  /// Combos macOS keeps for itself. Letters and digits match by the layout's key name (so ⌘Q
  /// is ⌘Q on AZERTY too); other keys by key code.
  private static let reserved: [ReservedCombo] = [
    .init(.command, .name("q")), .init(.command, .name("w")),
    .init(.command, .code(48)), .init(.command, .code(49)), .init(.control, .code(49)),
    .init([.command, .shift], .name("3")), .init([.command, .shift], .name("4")),
    .init([.command, .shift], .name("5")), .init([.command, .option], .code(53)),
  ]
}

private struct ReservedCombo {
  enum Key {
    case name(String)
    case code(UInt16)
  }

  let modifiers: KeyModifiers
  let key: Key

  init(_ modifiers: KeyModifiers, _ key: Key) {
    self.modifiers = modifiers
    self.key = key
  }

  func matches(_ combo: KeyCombo, keyName: String) -> Bool {
    guard combo.modifiers == modifiers else { return false }
    switch key {
    case .name(let name): return keyName.lowercased() == name
    case .code(let code): return combo.keyCode == code
    }
  }
}
