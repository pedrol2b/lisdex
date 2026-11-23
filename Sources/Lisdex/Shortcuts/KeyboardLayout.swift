import Carbon.HIToolbox
import Foundation

/// What the current keyboard layout types for a physical key, so a shortcut on AZERTY shows
/// "A" where QWERTY shows "Q". Special keys (arrows, F-keys…) are named by `KeyCombo` instead.
enum KeyboardLayout {
  private static let maxLength = 4

  static func keyName(for keyCode: UInt16) -> String {
    let sources = [
      TISCopyCurrentKeyboardLayoutInputSource(),
      TISCopyCurrentASCIICapableKeyboardLayoutInputSource(),
    ]
    for source in sources.compactMap({ $0?.takeRetainedValue() }) {
      if let name = translate(keyCode, with: source) { return name }
    }
    return "#\(keyCode)"
  }

  private static func translate(_ keyCode: UInt16, with source: TISInputSource) -> String? {
    guard let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
      return nil
    }
    let layoutData = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
    var deadKeyState: UInt32 = 0
    var length = 0
    var characters = [UniChar](repeating: 0, count: maxLength)
    let status = layoutData.withUnsafeBytes { buffer -> OSStatus in
      guard let layout = buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else {
        return OSStatus(paramErr)
      }
      return UCKeyTranslate(
        layout, keyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
        OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeyState, maxLength, &length, &characters)
    }
    guard status == noErr, length > 0 else { return nil }
    let name = String(utf16CodeUnits: characters, count: length)
    return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name
  }
}
