import AppKit
import LisdexCore
import SwiftUI

/// A click-to-record shortcut field (Settings → Shortcuts). While recording it owns the
/// keyboard: Esc cancels, Delete clears, any other key + modifiers is offered to `onRecord`,
/// which returns `nil` to accept or a problem to keep recording.
struct ShortcutRecorder: NSViewRepresentable {
  let title: String
  let onRecordingChange: (Bool) -> Void
  let onRecord: (KeyCombo) -> KeyComboProblem?
  let onClear: () -> Void

  func makeNSView(context: Context) -> RecorderView {
    let view = RecorderView()
    update(view)
    return view
  }

  func updateNSView(_ view: RecorderView, context: Context) { update(view) }

  static func dismantleNSView(_ view: RecorderView, coordinator: ()) { view.endRecording() }

  private func update(_ view: RecorderView) {
    view.title = title
    view.onRecordingChange = onRecordingChange
    view.onRecord = onRecord
    view.onClear = onClear
  }
}

final class RecorderView: NSView {
  private static let escape: UInt16 = 53
  private static let deleteKeys: Set<UInt16> = [51, 117]

  var title = "" { didSet { refresh() } }
  var onRecordingChange: (Bool) -> Void = { _ in }
  var onRecord: (KeyCombo) -> KeyComboProblem? = { _ in nil }
  var onClear: () -> Void = {}

  private let label = NSTextField(labelWithString: "")
  private var isRecording = false { didSet { refresh() } }
  private var liveModifiers = KeyModifiers()
  /// Only a click starts recording: never the window's initial focus or Tab.
  private var wasClicked = false
  /// While recording, sees every key in Lisdex's windows before SwiftUI or the menu do (so Esc,
  /// ⌘Q or ⌘W are recorded, not acted on). Local monitors need no permission.
  private var monitor: Any?

  override init(frame: NSRect) {
    super.init(frame: frame)
    wantsLayer = true
    layer?.cornerRadius = 6
    layer?.borderWidth = 1
    label.alignment = .center
    label.lineBreakMode = .byTruncatingTail
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
    ])
    setAccessibilityRole(.button)
    refresh()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  static let size = NSSize(width: 150, height: 22)

  override var intrinsicContentSize: NSSize { Self.size }

  override var acceptsFirstResponder: Bool { wasClicked }

  override func mouseDown(with event: NSEvent) {
    if isRecording {
      window?.makeFirstResponder(nil)
    } else {
      wasClicked = true
      window?.makeFirstResponder(self)
    }
  }

  /// Leaving the window (closing it, switching apps) must end recording, or the global
  /// shortcuts would stay paused (`AppModel.isRecordingShortcut`).
  override func viewWillMove(toWindow newWindow: NSWindow?) {
    let center = NotificationCenter.default
    if let window {
      center.removeObserver(self, name: NSWindow.didResignKeyNotification, object: window)
      center.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
    }
    if let newWindow {
      center.addObserver(
        self, selector: #selector(windowLostFocus), name: NSWindow.didResignKeyNotification,
        object: newWindow)
      center.addObserver(
        self, selector: #selector(windowLostFocus), name: NSWindow.willCloseNotification,
        object: newWindow)
    } else {
      endRecording()
    }
    super.viewWillMove(toWindow: newWindow)
  }

  @objc private func windowLostFocus(_ notification: Notification) { endRecording() }

  /// Stops recording without saving anything.
  func endRecording() {
    guard isRecording else { return }
    if window?.firstResponder === self { window?.makeFirstResponder(nil) }
    wasClicked = false
    setRecording(false)
  }

  override func becomeFirstResponder() -> Bool {
    setRecording(true)
    return true
  }

  override func resignFirstResponder() -> Bool {
    wasClicked = false
    setRecording(false)
    return true
  }

  private func handle(_ event: NSEvent) {
    let modifiers = KeyModifiers(event.modifierFlags)
    if modifiers.isEmpty, event.keyCode == Self.escape {
      window?.makeFirstResponder(nil)
    } else if modifiers.isEmpty, Self.deleteKeys.contains(event.keyCode) {
      onClear()
      window?.makeFirstResponder(nil)
    } else if onRecord(KeyCombo(keyCode: event.keyCode, modifiers: modifiers)) == nil {
      window?.makeFirstResponder(nil)
    } else {
      NSSound.beep()
    }
  }

  private func setRecording(_ recording: Bool) {
    guard recording != isRecording else { return }
    liveModifiers = []
    isRecording = recording
    recording ? startMonitoring() : stopMonitoring()
    onRecordingChange(recording)
  }

  private func startMonitoring() {
    monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) {
      [weak self] event in
      let consumed = MainActor.assumeIsolated { self?.consume(event) ?? false }
      return consumed ? nil : event
    }
  }

  /// Handles a key while recording; `true` swallows it.
  private func consume(_ event: NSEvent) -> Bool {
    guard isRecording else { return false }
    if event.type == .flagsChanged {
      liveModifiers = KeyModifiers(event.modifierFlags)
      refresh()
    } else {
      handle(event)
    }
    return true
  }

  private func stopMonitoring() {
    if let monitor { NSEvent.removeMonitor(monitor) }
    monitor = nil
  }

  private func refresh() {
    let text = isRecording ? liveModifiers.symbols + "Type shortcut…" : title
    label.stringValue = text
    label.textColor = isRecording ? .controlAccentColor : .labelColor
    layer?.borderColor = (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
    layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    setAccessibilityLabel(isRecording ? "Recording shortcut" : "Shortcut: \(title)")
  }
}

extension KeyModifiers {
  /// The modifiers Lisdex stores, from an AppKit event (fn / caps lock are ignored).
  init(_ flags: NSEvent.ModifierFlags) {
    var modifiers = KeyModifiers()
    if flags.contains(.control) { modifiers.insert(.control) }
    if flags.contains(.option) { modifiers.insert(.option) }
    if flags.contains(.shift) { modifiers.insert(.shift) }
    if flags.contains(.command) { modifiers.insert(.command) }
    self = modifiers
  }
}
