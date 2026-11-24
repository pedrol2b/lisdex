import AppKit
import CoreGraphics

/// The Accessibility ("post events") permission the mouse jiggler needs (ADR 0024). After an
/// ad-hoc rebuild or `brew upgrade` macOS can keep showing Lisdex as allowed while the grant no
/// longer applies; `isGranted` reports the truth, and Settings explains the fix.
enum PostEventPermission {
  static let settingsURL = URL(
    string:
      "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
  )!

  static var isGranted: Bool { CGPreflightPostEventAccess() }

  /// Adds Lisdex to the Accessibility list (macOS may show its own prompt).
  static func request() { _ = CGRequestPostEventAccess() }

  static func openSettings() { NSWorkspace.shared.open(settingsURL) }
}
