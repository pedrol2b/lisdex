import AppIntents
import Foundation

/// How App Intents reach the running app. Set once at launch by `AppDelegate`.
@MainActor
enum IntentBridge {
  static weak var model: AppModel?

  static func requireModel() throws -> AppModel {
    guard let model else { throw IntentBridgeError.notReady }
    return model
  }
}

enum IntentBridgeError: Error, CustomLocalizedStringResourceConvertible {
  case notReady

  var localizedStringResource: LocalizedStringResource { "Lisdex isn't ready yet." }
}
