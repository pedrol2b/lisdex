import AppKit

// Menu bar–only app: no Dock icon, no main window (LSUIElement is also set in Info.plist).
let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.accessory)
application.run()
