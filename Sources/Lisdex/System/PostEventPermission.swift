import AppKit
import ApplicationServices
import CoreGraphics

/// The Accessibility ("post events") permission the mouse jiggler needs (ADR 0024). After an
/// ad-hoc rebuild or `brew upgrade` macOS can keep showing Lisdex as allowed while the grant no
/// longer applies; `isGranted` reports the truth, and Settings explains the fix.
enum PostEventPermission {
  static let settingsURL = URL(
    string:
      "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
  )!

  /// `AXIsProcessTrusted` asks TCC each time, so a grant made while Lisdex runs shows up on the
  /// next check. `CGPreflightPostEventAccess` alone keeps its first answer for the life of the
  /// process (seen 2026-11-25: denied until relaunch, while TCC already allowed it).
  static var isGranted: Bool { AXIsProcessTrusted() || CGPreflightPostEventAccess() }

  /// Adds Lisdex to the Accessibility list (macOS may show its own prompt).
  static func request() { _ = CGRequestPostEventAccess() }

  static func openSettings() { NSWorkspace.shared.open(settingsURL) }
}
