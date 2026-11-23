/// Something that happened to the apps on this Mac, as the app trigger sees it.
public enum AppTriggerEvent: Equatable, Sendable {
  /// An app opened while Lisdex was running.
  case launched(bundleID: String)
  /// The running apps changed (an app quit, or the list was edited): every running bundle ID.
  case runningChanged(running: Set<String>)
}

public enum AppTriggerAction: Equatable, Sendable {
  case none
  case startAppSession
  case endSession
}

/// The app trigger's rules (spec app-trigger, ADR 0020): a listed app opening turns Keep Awake
/// on if it is off; the last listed app quitting turns it off only if an app turned it on.
/// A user's session is never touched, and a manual "off" holds until a listed app opens again.
/// `batteryCutoff`: the battery is below the stop threshold, so a launch must not start a
/// session the cutoff would end at once (with a "Keep Awake stopped" notification).
public enum AppTriggerRules {
  public static func decide(
    _ event: AppTriggerEvent, session: Session?, triggers: AppTriggers, batteryCutoff: Bool = false
  ) -> AppTriggerAction {
    switch event {
    case .launched(let bundleID):
      guard session == nil, !batteryCutoff, triggers.contains(bundleID: bundleID) else {
        return .none
      }
      return .startAppSession
    case .runningChanged(let running):
      guard session?.origin == .app else { return .none }
      return running.isDisjoint(with: triggers.bundleIDs) ? .endSession : .none
    }
  }
}
