import Foundation

public enum FocusAction: Equatable, Sendable {
  case none
  case startFocusSession
  case endSession
}

/// Lisdex's Focus filter (spec shortcuts-focus): a Focus with "Keep Mac awake" turns Keep Awake on
/// if it is off; the Focus ending turns it off only if the Focus turned it on. Sessions started
/// by the user or an app are never touched, and a manual "off" holds until a Focus starts again.
/// `batteryCutoff`: below the stop threshold, so starting would only be stopped again at once.
public enum FocusRules {
  public static func decide(keepsAwake: Bool, session: Session?, batteryCutoff: Bool = false)
    -> FocusAction
  {
    if keepsAwake {
      return session == nil && !batteryCutoff ? .startFocusSession : .none
    }
    return session?.origin == .focus ? .endSession : .none
  }
}
