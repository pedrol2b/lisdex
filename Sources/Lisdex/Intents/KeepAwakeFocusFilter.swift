import AppIntents

/// System Settings → Focus → (a Focus) → Focus Filters → Lisdex (spec shortcuts-focus).
/// The system runs `perform()` when the Focus starts and again when it ends; on the end the
/// parameter arrives unset, so an unset value means "let the Mac sleep".
struct KeepAwakeFocusFilter: SetFocusFilterIntent {
  static let title: LocalizedStringResource = "Keep Mac Awake"
  static let description: IntentDescription? = IntentDescription(
    "Turns Keep Awake on while this Focus is on, and off when it ends.")

  @Parameter(title: "Keep Mac awake")
  var keepAwake: Bool?

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: keepAwake == true ? "Keep Mac awake" : "Let Mac sleep")
  }

  func perform() async throws -> some IntentResult {
    let keepsAwake = keepAwake == true
    await MainActor.run { IntentBridge.model?.focusChanged(keepsAwake: keepsAwake) }
    return .result()
  }
}
