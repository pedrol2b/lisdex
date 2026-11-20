import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var model: AppModel?
  private var statusItem: StatusItemController?
  private var settingsWindow: SettingsWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    let model = AppModel()
    self.model = model
    let settingsWindow = SettingsWindowController(model: model)
    self.settingsWindow = settingsWindow
    self.statusItem = StatusItemController(model: model, openSettings: settingsWindow.show)
    model.start()
    Log.app.notice("Lisdex launched")
  }

  func applicationWillTerminate(_ notification: Notification) {
    model?.shutdown()
  }
}
