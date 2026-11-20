/// Start on Login is registered for the app's bundle path. A Homebrew upgrade installs the app
/// at a new path, which leaves the registration pointing at a deleted bundle (ADR 0017).
public enum LoginItemRepair {
  /// Re-register at launch only when the user enabled Start on Login from Lisdex, the app has
  /// moved since, and macOS no longer reports it enabled. A user who switched it off in System
  /// Settings without the app moving is left alone.
  public static func shouldReRegister(
    savedPath: String?, currentPath: String, isEnabled: Bool
  ) -> Bool {
    guard let savedPath, !isEnabled else { return false }
    return savedPath != currentPath
  }
}
