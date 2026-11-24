import AppIntents
import LisdexCore

/// Shortcuts actions (spec shortcuts-focus). Listed only in certificate-signed builds, where
/// `scripts/build-app.sh` adds the App Intents metadata; each is a user action, like a link.
struct TurnOnKeepAwakeIntent: AppIntent {
  static let title: LocalizedStringResource = "Turn Keep Awake On"
  static let description = IntentDescription(
    "Keeps your Mac awake, for some minutes or until you turn it off.")
  static let openAppWhenRun = false

  @Parameter(
    title: "Minutes", description: "Leave empty to keep it on until you turn it off.",
    inclusiveRange: (1, 1440))  // KeepAwakeCommand.maxMinutes; must be a literal
  var minutes: Int?

  static var parameterSummary: some ParameterSummary {
    Summary("Turn Keep Awake on for \(\.$minutes) minutes")
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    try IntentBridge.requireModel().run(.turnOn(minutes.map { .minutes($0) } ?? .untilStopped))
    return .result()
  }
}

struct TurnOffKeepAwakeIntent: AppIntent {
  static let title: LocalizedStringResource = "Turn Keep Awake Off"
  static let description = IntentDescription("Lets your Mac sleep normally again.")
  static let openAppWhenRun = false

  @MainActor
  func perform() async throws -> some IntentResult {
    try IntentBridge.requireModel().run(.turnOff)
    return .result()
  }
}

struct IsKeepAwakeOnIntent: AppIntent {
  static let title: LocalizedStringResource = "Is Keep Awake On?"
  static let description = IntentDescription("Whether Lisdex's Keep Awake switch is on.")
  static let openAppWhenRun = false

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
    .result(value: try IntentBridge.requireModel().isOn)
  }
}
