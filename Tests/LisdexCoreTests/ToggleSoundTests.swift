import Foundation
import Testing

@testable import LisdexCore

@Suite("ToggleSound")
struct ToggleSoundTests {
  @Test("feedback is on by default and uses Pop")
  func defaults() {
    #expect(AppSettings.default.playsToggleSound)
    #expect(AppSettings.default.feedbackSound == .pop)
  }

  @Test("turning feedback off means no sound, but the chosen sound is remembered")
  func disabled() {
    let settings = AppSettings.default.with(playsToggleSound: false, toggleSound: .glass)

    #expect(settings.feedbackSound == nil)
    #expect(settings.with(playsToggleSound: true).feedbackSound == .glass)
  }

  @Test("every variant names a macOS system sound", arguments: ToggleSound.allCases)
  func systemSoundExists(sound: ToggleSound) {
    let path = "/System/Library/Sounds/\(sound.systemName).aiff"
    #expect(FileManager.default.fileExists(atPath: path))
  }

  @Test("older settings without sound keys load with the defaults; unknown sounds fall back")
  func decoding() throws {
    let old = try JSONDecoder().decode(AppSettings.self, from: Data(#"{"accent":"mint"}"#.utf8))
    let unknown = try JSONDecoder().decode(
      AppSettings.self,
      from: Data(#"{"playsToggleSound":false,"toggleSound":"kazoo"}"#.utf8))

    #expect(old.playsToggleSound && old.toggleSound == .pop && old.accent == .preset(.mint))
    #expect(unknown.playsToggleSound == false && unknown.toggleSound == .pop)
  }
}
