import AppKit
import LisdexCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var model: AppModel?
  private var statusItem: StatusItemController?
  private var settingsWindow: SettingsWindowController?
  private var hotKeys: HotKeyCenter?
  /// Links that arrived before the model existed: a link that launches Lisdex is delivered
  /// before `applicationDidFinishLaunching`.
  private var pendingCommands: [KeepAwakeCommand] = []

  func applicationDidFinishLaunching(_ notification: Notification) {
    let model = AppModel()
    self.model = model
    IntentBridge.model = model
    let settingsWindow = SettingsWindowController(model: model)
    self.settingsWindow = settingsWindow
    self.statusItem = StatusItemController(model: model, openSettings: settingsWindow.show(tab:))
    model.start()
    pendingCommands.forEach(model.run)
    pendingCommands = []
    IntentBridge.modelDidStart()
    hotKeys = HotKeyCenter(model: model)
    Log.app.notice("Lisdex launched")
    openForScreenshot()
  }

  /// `open Lisdex.app --args -LisdexScreenshot popover|general|power|schedule|appearance|shortcuts|apps` opens that UI
  /// right after launch, so `scripts/screenshots.sh` can capture README images without clicks.
  private func openForScreenshot() {
    guard let target = UserDefaults.standard.string(forKey: "LisdexScreenshot") else { return }
    Task { @MainActor [weak self] in
      try? await Task.sleep(for: .milliseconds(600))
      if target == "popover" {
        self?.statusItem?.showPopover()
      } else if let tab = SettingsTab(rawValue: target) {
        self?.settingsWindow?.show(tab: tab)
      }
    }
  }

  /// `lisdex://` links (spec shortcuts-focus). A link only switches Keep Awake; anything Lisdex
  /// doesn't understand is logged and ignored.
  func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls {
      guard let command = KeepAwakeCommand(url: url) else {
        Log.app.notice("Ignored link \(url.absoluteString, privacy: .public)")
        continue
      }
      if let model { model.run(command) } else { pendingCommands.append(command) }
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    hotKeys?.stop()
    model?.shutdown()
  }
}
