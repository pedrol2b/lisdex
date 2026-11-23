import AppKit
import LisdexCore
import Observation
import SwiftUI

/// Owns the menu bar icon (pill, coffee mug or light bulb).
/// - The toggle click (right-click / ⌃-click by default, or left-click when swapped in
///   Settings → General) toggles Keep Awake, keeping the mode; the other click opens the popover.
/// - Option + either click: the quick durations menu.
@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
  private let model: AppModel
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private let popover = NSPopover()
  /// The items of the quick menu currently shown, indexed by `NSMenuItem.tag`.
  private var quickMenuItems: [QuickMenu.Item] = []
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
    switch model.settings.clickBehavior.action(for: Self.click(from: NSApp.currentEvent)) {
    case .toggle: model.toggle()
    case .openPopover: togglePopover(relativeTo: sender)
    case .quickMenu: showQuickMenu(from: sender)
    }
  }

  private static func click(from event: NSEvent?) -> StatusItemClick {
    let type = event?.type
    let isMouseClick = type == .leftMouseUp || type == .rightMouseUp
    // The status item's click event may arrive without modifiers; for real clicks also read the
    // keys held now. Never for other activations (VoiceOver holds ⌃⌥ while pressing).
    let flags = isMouseClick ? (event?.modifierFlags ?? []).union(NSEvent.modifierFlags) : []
    return StatusItemClick(
      isMouseClick: isMouseClick, isRightButton: type == .rightMouseUp,
      modifiers: KeyModifiers(flags))
  }

  // MARK: Quick menu (Option-click)

  private func showQuickMenu(from button: NSStatusBarButton) {
    if popover.isShown { popover.performClose(nil) }
    quickMenuItems = QuickMenu.items(isOn: model.isOn)
    let menu = NSMenu(title: QuickMenu.title)
    let header = NSMenuItem(title: QuickMenu.title, action: nil, keyEquivalent: "")
    header.isEnabled = false
    menu.addItem(header)
    for (index, item) in quickMenuItems.enumerated() {
      if index == 0 || item == .indefinitely || item == .stop { menu.addItem(.separator()) }
      let menuItem = NSMenuItem(
        title: item.title, action: #selector(quickMenuChose(_:)), keyEquivalent: "")
      menuItem.target = self
      menuItem.tag = index
      menu.addItem(menuItem)
    }
    menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
  }

  @objc private func quickMenuChose(_ sender: NSMenuItem) {
    guard quickMenuItems.indices.contains(sender.tag) else { return }
    switch quickMenuItems[sender.tag] {
    case .duration(let seconds): model.startDuration(seconds)
    case .indefinitely: model.startIndefinitely()
    case .stop: model.switchOn(false)
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
    // Read on every pass so a Settings change re-runs the observation.
    statusItem.button?.setAccessibilityHelp(model.settings.clickBehavior.accessibilityHelp)
    let icon = model.menuBarIcon
    guard icon != renderedIcon else { return }
    renderedIcon = icon
    statusItem.button?.image = MenuBarImages.image(for: icon)
    // System-dimmed glyph while inactive, like other keep-awake menu bar apps.
    statusItem.button?.appearsDisabled = !icon.isActive
    statusItem.button?.setAccessibilityLabel(icon.accessibilityLabel)
  }
}
