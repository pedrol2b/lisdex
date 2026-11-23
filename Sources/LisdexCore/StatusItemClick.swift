/// Which mouse button clicked the status item. Control-click counts as `secondary`; any click
/// with Option held is `option`.
public enum StatusItemClick: Sendable {
  case primary
  case secondary
  case option
}

/// What a status-item click does.
public enum StatusItemAction: Equatable, Sendable {
  case toggle
  case openPopover
  case quickMenu
}

/// Settings → General → Quick-Start a Session: which click toggles Keep Awake. The other
/// click opens the popover.
public enum StatusItemClickBehavior: String, Codable, CaseIterable, Sendable {
  case rightClickToggles
  case leftClickToggles

  /// v1.0 behaviour: right-click toggles.
  public static let `default` = StatusItemClickBehavior.rightClickToggles

  public var title: String {
    switch self {
    case .rightClickToggles: "Right click (left click shows menu)"
    case .leftClickToggles: "Left click (right click shows menu)"
    }
  }

  /// VoiceOver help for the status item.
  public var accessibilityHelp: String {
    switch self {
    case .rightClickToggles:
      "Opens Lisdex. Right-click toggles Keep Awake. Option-click for quick durations."
    case .leftClickToggles:
      "Toggles Keep Awake. Right-click opens Lisdex. Option-click for quick durations."
    }
  }

  public func action(for click: StatusItemClick) -> StatusItemAction {
    switch (self, click) {
    case (_, .option): .quickMenu
    case (.rightClickToggles, .secondary), (.leftClickToggles, .primary): .toggle
    case (.rightClickToggles, .primary), (.leftClickToggles, .secondary): .openPopover
    }
  }
}
