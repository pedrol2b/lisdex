import UserNotifications

/// Local notifications ("session ended", "stopped on low battery"). Permission is requested the
/// first time one is needed; if the user declines, posting is a logged no-op.
@MainActor
enum Notifier {
  static func post(title: String, body: String) {
    Task {
      let center = UNUserNotificationCenter.current()
      do {
        guard try await center.requestAuthorization(options: [.alert, .sound]) else {
          Log.app.notice("Notification skipped: permission not granted")
          return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        try await center.add(
          UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
      } catch {
        Log.app.error("Notification failed: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
