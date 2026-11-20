import AppKit
import LisdexCore

/// Plays the Keep Awake toggle sound (ADR 0016) using the macOS system sounds.
@MainActor
enum SoundPlayer {
  static func play(_ sound: ToggleSound) {
    guard let player = NSSound(named: NSSound.Name(sound.systemName)) else {
      Log.app.error("System sound \(sound.systemName, privacy: .public) not found")
      return
    }
    player.stop()  // a quick double toggle restarts the sound instead of being ignored
    player.play()
  }
}
