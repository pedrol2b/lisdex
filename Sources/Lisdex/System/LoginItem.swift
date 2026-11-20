import ServiceManagement

/// Start on Login via `SMAppService.mainApp`. The truth lives in macOS, not in our settings
/// (ADR 0006), so the status is always read back from the system.
enum LoginItemState: Equatable {
  case off
  case on
  /// Registered, but the user has to allow it in System Settings → General → Login Items.
  case needsApproval
}

@MainActor
enum LoginItem {
  static var state: LoginItemState {
    switch SMAppService.mainApp.status {
    case .enabled: .on
    case .requiresApproval: .needsApproval
    default: .off
    }
  }

  static func set(_ enabled: Bool) throws {
    if enabled {
      try SMAppService.mainApp.register()
    } else {
      try SMAppService.mainApp.unregister()
    }
  }

  static func openSystemSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }
}
