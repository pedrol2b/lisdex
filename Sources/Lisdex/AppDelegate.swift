import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var model: AppModel?
  private var statusItem: StatusItemController?
  private var settingsWindow: SettingsWindowController?
  private var hotKeys: HotKeyCenter?

  func applicationDidFinishLaunching(_ notification: Notification) {
    let model = AppModel()
    self.model = model
    let settingsWindow = SettingsWindowController(model: model)
    self.settingsWindow = settingsWindow
    self.statusItem = StatusItemController(model: model, openSettings: settingsWindow.show)
    model.start()
    hotKeys = HotKeyCenter(model: model)
    Log.app.notice("Lisdex launched")
    openForScreenshot()
  }

  /// `open Lisdex.app --args -LisdexScreenshot popover|general|power|appearance` opens that UI
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

  func applicationWillTerminate(_ notification: Notification) {
    hotKeys?.stop()
    model?.shutdown()
  }
}
