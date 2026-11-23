import AppKit
import Carbon.HIToolbox
import LisdexCore
import Observation

/// Registers the user's global shortcuts with Carbon hot keys (ADR 0019): no Accessibility
/// permission needed. Re-registers whenever the shortcuts change, and pauses while Settings is
/// recording a combo so pressing an existing one records it instead of firing it.
@MainActor
final class HotKeyCenter {
  /// The one live center, for the C event handler to reach.
  fileprivate static weak var active: HotKeyCenter?
  /// Hot-key signature "LSDX".
  nonisolated static let signature: OSType = 0x4C53_4458

  private let model: AppModel
  private var handler: EventHandlerRef?
  private var registered: [EventHotKeyRef] = []
  private var applied: (combos: [ShortcutAction: KeyCombo], paused: Bool)?

  init(model: AppModel) {
    self.model = model
    Self.active = self
    installHandler()
    observeModel()
    NotificationCenter.default.addObserver(
      self, selector: #selector(retryUnavailable), name: NSApplication.didBecomeActiveNotification,
      object: nil)
  }

  /// A combo another app held may be free now: try again whenever Lisdex is brought forward
  /// (popover or Settings opened).
  @objc private func retryUnavailable(_ notification: Notification) {
    guard !model.shortcutsInUseElsewhere.isEmpty, let applied else { return }
    self.applied = nil
    apply(combos: applied.combos, paused: applied.paused)
  }

  /// Unregisters everything; called on quit.
  func stop() {
    unregisterAll()
    if let handler { RemoveEventHandler(handler) }
    handler = nil
  }

  fileprivate func fire(id: UInt32) {
    let actions = ShortcutAction.allCases
    let index = Int(id) - 1
    guard actions.indices.contains(index) else { return }
    model.perform(actions[index])
  }

  // MARK: Registration

  private func installHandler() {
    var spec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let status = InstallEventHandler(
      GetApplicationEventTarget(), hotKeyPressed, 1, &spec, nil, &handler)
    if status != noErr {
      Log.app.error("Hot-key handler not installed: \(status, privacy: .public)")
    }
  }

  private func observeModel() {
    withObservationTracking {
      apply(combos: model.settings.shortcuts.combos, paused: model.isRecordingShortcut)
    } onChange: { [weak self] in
      Task { @MainActor in self?.observeModel() }
    }
  }

  private func apply(combos: [ShortcutAction: KeyCombo], paused: Bool) {
    if let applied, applied.combos == combos, applied.paused == paused { return }
    applied = (combos, paused)
    unregisterAll()
    Log.app.notice(
      "Shortcuts: \(combos.count, privacy: .public) set, paused \(paused, privacy: .public)")
    guard !paused else { return }

    var unavailable = Set<ShortcutAction>()
    for (index, action) in ShortcutAction.allCases.enumerated() {
      guard let combo = combos[action] else { continue }
      var ref: EventHotKeyRef?
      let status = RegisterEventHotKey(
        UInt32(combo.keyCode), combo.modifiers.carbonFlags,
        EventHotKeyID(signature: Self.signature, id: UInt32(index + 1)),
        GetApplicationEventTarget(), OptionBits(kEventHotKeyExclusive), &ref)
      if status == noErr, let ref {
        registered.append(ref)
      } else {
        unavailable.insert(action)
        Log.app.notice(
          "Shortcut \(action.rawValue, privacy: .public) unavailable: \(status, privacy: .public)")
      }
    }
    model.reportUnavailableShortcuts(unavailable)
  }

  private func unregisterAll() {
    for ref in registered { UnregisterEventHotKey(ref) }
    registered = []
  }
}

/// Carbon calls this on the main thread for every registered hot key.
private func hotKeyPressed(
  _: EventHandlerCallRef?, event: EventRef?, _: UnsafeMutableRawPointer?
) -> OSStatus {
  var id = EventHotKeyID()
  let status = GetEventParameter(
    event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
    MemoryLayout<EventHotKeyID>.size, nil, &id)
  guard status == noErr, id.signature == HotKeyCenter.signature else {
    return OSStatus(eventNotHandledErr)
  }
  let hotKeyID = id.id
  MainActor.assumeIsolated { HotKeyCenter.active?.fire(id: hotKeyID) }
  return noErr
}

extension KeyModifiers {
  /// Carbon modifier mask for `RegisterEventHotKey`.
  var carbonFlags: UInt32 {
    var flags = 0
    if contains(.control) { flags |= controlKey }
    if contains(.option) { flags |= optionKey }
    if contains(.shift) { flags |= shiftKey }
    if contains(.command) { flags |= cmdKey }
    return UInt32(flags)
  }
}
