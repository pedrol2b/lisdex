import AppKit

/// Watches apps opening and quitting for the app trigger (spec app-trigger). Needs no
/// permission: `NSWorkspace` posts these to every app.
@MainActor
final class AppWatcher {
  private let onLaunch: @MainActor (String) -> Void
  private let onRunningChange: @MainActor (Set<String>) -> Void
  private var tokens: [NSObjectProtocol] = []

  init(
    onLaunch: @escaping @MainActor (String) -> Void,
    onRunningChange: @escaping @MainActor (Set<String>) -> Void
  ) {
    self.onLaunch = onLaunch
    self.onRunningChange = onRunningChange
    let center = NSWorkspace.shared.notificationCenter
    tokens = [
      center.addObserver(
        forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
      ) { [weak self] note in
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        let bundleID = app?.bundleIdentifier
        MainActor.assumeIsolated {
          guard let self, let bundleID else { return }
          self.onLaunch(bundleID)
        }
      },
      center.addObserver(
        forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
      ) { [weak self] note in
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        let pid = app?.processIdentifier
        MainActor.assumeIsolated {
          guard let self else { return }
          self.onRunningChange(Self.runningBundleIDs(excluding: pid))
        }
      },
    ]
  }

  isolated deinit {
    tokens.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
  }

  /// Bundle IDs of the apps running now. `excluding` drops the process that just quit, in case
  /// the workspace list hasn't caught up yet.
  static func runningBundleIDs(excluding pid: pid_t? = nil) -> Set<String> {
    Set(
      NSWorkspace.shared.runningApplications
        .filter { !$0.isTerminated && $0.processIdentifier != pid }
        .compactMap(\.bundleIdentifier))
  }
}
