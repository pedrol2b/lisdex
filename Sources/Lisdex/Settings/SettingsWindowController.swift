import AppKit
import SwiftUI

/// The Settings window (⌘, in the popover). Created once, re-shown on demand. Lisdex is an
/// accessory app, so it activates itself to bring the window to the front.
@MainActor
final class SettingsWindowController {
  private let model: AppModel
  private lazy var window: NSWindow = makeWindow(tab: initialTab)
  private var initialTab = SettingsTab.general

  init(model: AppModel) {
    self.model = model
  }

  func show() { show(tab: .general) }

  /// `tab` applies when the window is first created (used by screenshot mode).
  func show(tab: SettingsTab) {
    initialTab = tab
    model.refreshLoginItem()
    NSApp.activate()
    if !window.isVisible { window.center() }
    window.makeKeyAndOrderFront(nil)
  }

  private func makeWindow(tab: SettingsTab) -> NSWindow {
    let host = NSHostingController(rootView: SettingsView(model: model, tab: tab))
    host.sizingOptions = .preferredContentSize
    let window = NSWindow(contentViewController: host)
    window.title = "Lisdex Settings"
    window.styleMask = [.titled, .closable]
    window.isReleasedWhenClosed = false
    return window
  }
}
