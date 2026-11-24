import AppIntents
import Foundation

/// How App Intents reach the running app. Set once at launch by `AppDelegate`.
@MainActor
enum IntentBridge {
  static weak var model: AppModel?
  /// A Focus filter change that arrived before the model existed (the system can launch Lisdex
  /// to deliver it).
  private static var pendingFocus: Bool?

  static func requireModel() throws -> AppModel {
    guard let model else { throw IntentBridgeError.notReady }
    return model
  }

  static func focusChanged(keepsAwake: Bool) {
    guard let model else {
      pendingFocus = keepsAwake
      return
    }
    model.focusChanged(keepsAwake: keepsAwake)
  }

  /// After launch: apply a Focus change that arrived early, else ask the system whether the
  /// current Focus has Lisdex's filter on (a Focus that started before Lisdex did).
  static func modelDidStart() {
    if let pending = pendingFocus {
      pendingFocus = nil
      model?.focusChanged(keepsAwake: pending)
      return
    }
    Task { @MainActor in
      guard let filter = try? await KeepAwakeFocusFilter.current, filter.keepAwake == true,
        pendingFocus == nil
      else { return }
      Log.app.notice("A Focus with Keep Mac awake is already on")
      model?.focusChanged(keepsAwake: true)
    }
  }
}

enum IntentBridgeError: Error, CustomLocalizedStringResourceConvertible {
  case notReady

  var localizedStringResource: LocalizedStringResource { "Lisdex isn't ready yet." }
}
