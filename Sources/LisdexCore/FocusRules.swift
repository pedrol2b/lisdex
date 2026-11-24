import Foundation

public enum FocusAction: Equatable, Sendable {
  case none
  case startFocusSession
  case endSession
  /// The Focus ended but a listed app is still open: the app keeps the Mac awake now.
  case becomeAppSession
}

/// Lisdex's Focus filter (spec shortcuts-focus): a Focus with "Keep Mac awake" turns Keep Awake on
/// if it is off; the Focus ending turns it off only if the Focus turned it on. Sessions started
/// by the user or an app are never touched, and a manual "off" holds until a Focus starts again.
/// `batteryCutoff`: below the stop threshold, so starting would only be stopped again at once.
public enum FocusRules {
  /// `appKeepsAwake`: a listed app (Settings → Apps) is open, so it takes over when the Focus ends.
  public static func decide(
    keepsAwake: Bool, session: Session?, batteryCutoff: Bool = false, appKeepsAwake: Bool = false
  ) -> FocusAction {
    if keepsAwake {
      return session == nil && !batteryCutoff ? .startFocusSession : .none
    }
    guard session?.origin == .focus else { return .none }
    return appKeepsAwake ? .becomeAppSession : .endSession
  }
}
