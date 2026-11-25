import Foundation
import Testing

@testable import LisdexCore

@Suite("Accent")
struct AccentTests {
  private struct Box: Codable, Equatable { let accent: Accent }

  private func decode(_ json: String) throws -> Accent {
    try JSONDecoder().decode(Box.self, from: Data(json.utf8)).accent
  }

  @Test("default is the gold preset")
  func defaultAccent() {
    #expect(Accent.default == .preset(.gold))
    #expect(Accent.default.rgb == 0xF4C85B)
  }

  @Test("a preset is stored by name, as before custom colours existed")
  func presetByName() throws {
    let data = try JSONEncoder().encode(Box(accent: .preset(.mint)))

    #expect(String(decoding: data, as: UTF8.self) == #"{"accent":"mint"}"#)
    #expect(try decode(#"{"accent":"mint"}"#) == .preset(.mint))
  }

  @Test("a custom colour is stored as #RRGGBB and round-trips")
  func customHex() throws {
    let custom = Accent.custom(rgb: 0x12AB3C)
    let data = try JSONEncoder().encode(Box(accent: custom))

    #expect(String(decoding: data, as: UTF8.self) == ##"{"accent":"#12AB3C"}"##)
    #expect(try decode(##"{"accent":"#12ab3c"}"##) == custom)
    #expect(custom.rgb == 0x12AB3C)
  }

  @Test(
    "unknown names and malformed hex fail to decode",
    arguments: ["chartreuse", "#12AB3", "#GG0000", "#1234567", "#"])
  func malformed(_ raw: String) {
    #expect(throws: DecodingError.self) { try decode("{\"accent\":\"\(raw)\"}") }
  }

  @Test("a custom colour is masked to 24 bits")
  func masked() {
    #expect(Accent.custom(rgb: 0xFF12_3456).rgb == 0x123456)
  }

  @Test("custom is nil for presets and the colour for a custom accent")
  func customAccessor() {
    #expect(Accent.preset(.blue).customRGB == nil)
    #expect(Accent.custom(rgb: 0x010203).customRGB == 0x010203)
  }
}

@Suite("Accent hex input")
struct AccentHexTests {
  @Test(
    "valid hex parses, with or without #, any case, short form expanded, spaces trimmed",
    arguments: [
      ("#12AB3C", 0x12AB3C), ("12ab3c", 0x12AB3C), ("  #12Ab3c ", 0x12AB3C),
      ("#FA0", 0xFFAA00), ("fa0", 0xFFAA00),
    ] as [(String, UInt32)])
  func valid(_ input: String, _ rgb: UInt32) {
    #expect(Accent.rgb(fromHex: input) == rgb)
  }

  @Test(
    "invalid hex is rejected",
    arguments: [
      "", "#", "#12AB3", "#12AB3CD", "#GG0000", "red", "##12AB3C", "#12 AB3C", "0x12AB3C",
    ])
  func invalid(_ input: String) {
    #expect(Accent.rgb(fromHex: input) == nil)
  }

  @Test("hex is #RRGGBB, upper case")
  func hexString() {
    #expect(Accent.preset(.gold).hex == "#F4C85B")
    #expect(Accent.custom(rgb: 0x0A0B0C).hex == "#0A0B0C")
  }

  @Test("a colour equal to a preset becomes that preset; anything else is custom")
  func fromRGB() {
    #expect(Accent(rgb: 0xF4C85B) == .preset(.gold))
    #expect(Accent(rgb: 0x4FD1A5) == .preset(.mint))
    #expect(Accent(rgb: 0x123456) == .custom(rgb: 0x123456))
  }
}
