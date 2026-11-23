import AppKit
import LisdexCore
import Observation
import SwiftUI

/// Owns the menu bar icon (pill or coffee mug).
/// - Left-click: open/close the popover menu.
/// - Right-click (or ⌃-click): toggle Keep Awake without opening the menu; the mode is kept.
@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
  private let model: AppModel
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private let popover = NSPopover()
  private let openSettings: () -> Void
  private var renderedIcon: MenuBarIcon?

  init(model: AppModel, openSettings: @escaping () -> Void) {
    self.model = model
    self.openSettings = openSettings
    super.init()
    configureButton()
    configurePopover()
    observeModel()
  }

  // MARK: Setup

  private func configureButton() {
    guard let button = statusItem.button else { return }
    button.target = self
    button.action = #selector(handleClick(_:))
    button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    button.imagePosition = .imageOnly
    button.setAccessibilityHelp("Opens Lisdex. Right-click toggles Keep Awake.")
  }

  private func configurePopover() {
    popover.behavior = .transient  // clicking outside dismisses
    popover.animates = true
    popover.delegate = self
  }

  /// The SwiftUI content (and its once-a-second timelines) exists only while the popover is
  /// open; it is created on show and dropped on close.
  private func makeContent() -> NSViewController {
    let root = MenuView(
      model: model,
      dismiss: { [weak self] in self?.popover.performClose(nil) },
      openSettings: { [weak self] in
        self?.popover.performClose(nil)
        self?.openSettings()
      })
    let host = NSHostingController(rootView: root)
    host.sizingOptions = .preferredContentSize
    return host
  }

  func popoverDidClose(_ notification: Notification) {
    popover.contentViewController = nil
  }

  @objc private func handleClick(_ sender: NSStatusBarButton) {
    let event = NSApp.currentEvent
    let click: StatusItemClick =
      event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
      ? .secondary : .primary
    switch model.settings.clickBehavior.action(for: click) {
    case .toggle: model.toggle()
    case .openPopover: togglePopover(relativeTo: sender)
    }
  }

  /// Opens the popover without a click (screenshot mode).
  func showPopover() {
    guard let button = statusItem.button, !popover.isShown else { return }
    togglePopover(relativeTo: button)
  }

  private func togglePopover(relativeTo button: NSStatusBarButton) {
    if popover.isShown {
      popover.performClose(nil)
    } else {
      model.refreshLoginItem()
      popover.contentViewController = makeContent()
      NSApp.activate()
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      let window = popover.contentViewController?.view.window
      window?.makeKey()
      // Don't start with a field focused: in Schedule mode the first time picker would
      // otherwise open with its hour selected.
      window?.makeFirstResponder(nil)
    }
  }

  // MARK: Rendering

  /// Re-renders whenever any model property read in `render()` changes.
  private func observeModel() {
    withObservationTracking {
      render()
    } onChange: { [weak self] in
      Task { @MainActor in self?.observeModel() }
    }
  }

  private func render() {
    let icon = model.menuBarIcon
    guard icon != renderedIcon else { return }
    renderedIcon = icon
    statusItem.button?.image = MenuBarImages.image(for: icon)
    // System-dimmed glyph while inactive, like other keep-awake menu bar apps.
    statusItem.button?.appearsDisabled = !icon.isActive
    statusItem.button?.setAccessibilityLabel(icon.accessibilityLabel)
  }
}
