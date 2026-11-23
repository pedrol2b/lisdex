import AppKit
import SwiftUI

/// The Settings window (⌘, in the popover). Created once, re-shown on demand. Lisdex is an
/// accessory app, so it activates itself to bring the window to the front.
@MainActor
final class SettingsWindowController {
  private let model: AppModel
  private let navigation = SettingsNavigation()
  private lazy var window: NSWindow = makeWindow()

  init(model: AppModel) {
    self.model = model
  }

  func show() { show(tab: .general) }

  /// Shows the window on `tab`, switching tab if it is already open.
  func show(tab: SettingsTab) {
    navigation.tab = tab
    model.refreshLoginItem()
    NSApp.activate()
    if !window.isVisible { window.center() }
    window.makeKeyAndOrderFront(nil)
  }

  private func makeWindow() -> NSWindow {
    let host = NSHostingController(rootView: SettingsView(model: model, navigation: navigation))
    host.sizingOptions = .preferredContentSize
    let window = NSWindow(contentViewController: host)
    window.title = "Lisdex Settings"
    window.styleMask = [.titled, .closable]
    window.isReleasedWhenClosed = false
    return window
  }
}
