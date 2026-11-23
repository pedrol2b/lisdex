/// What a global keyboard shortcut does (Settings → Shortcuts, ADR 0019).
/// `CodingKey` so `ShortcutSettings` can store one entry per action by name.
public enum ShortcutAction: String, CaseIterable, Codable, CodingKey, Sendable {
  case toggle
  case startIndefinitely
  case startDuration
  case stop

  public var title: String {
    switch self {
    case .toggle: "Toggle Keep Awake"
    case .startIndefinitely: "Start Indefinitely"
    case .startDuration: "Start for a Duration"
    case .stop: "Stop"
    }
  }
}

/// Why a recorded combination can't be used.
public enum KeyComboProblem: Equatable, Sendable {
  case needsModifier
  case reservedBySystem
  case usedBy(ShortcutAction)

  public var message: String {
    switch self {
    case .needsModifier: "Add ⌃, ⌥ or ⌘."
    case .reservedBySystem: "Reserved by macOS."
    case .usedBy(let action): "Already used for \(action.title)."
    }
  }
}
