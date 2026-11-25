import Foundation

/// Accent colour presets (Settings → Appearance). Stored by name; `rgb` is 0xRRGGBB.
public enum AccentChoice: String, Codable, CaseIterable, Sendable {
  case gold, orange, pink, purple, blue, mint

  public static let `default` = AccentChoice.gold

  public var rgb: UInt32 {
    switch self {
    case .gold: 0xF4C85B
    case .orange: 0xFF9F43
    case .pink: 0xFF6B9D
    case .purple: 0xA78BFA
    case .blue: 0x5AA9FF
    case .mint: 0x4FD1A5
    }
  }

  public var title: String { rawValue.capitalized }
}

/// The accent the user picked: a preset, or any colour from the system colour panel.
///
/// JSON is a single string: a preset's name (as stored before custom colours existed) or
/// `#RRGGBB`. An older Lisdex can't read `#RRGGBB` and falls back to gold (ADR 0006).
public enum Accent: Equatable, Hashable, Sendable {
  case preset(AccentChoice)
  case custom(rgb: UInt32)

  public static let `default` = Accent.preset(.default)

  private static let rgbMask: UInt32 = 0xFF_FFFF
  private static let hexDigits = 6
  private static let shortHexDigits = 3
  private static let hexPrefix = "#"

  /// A preset when `rgb` is exactly a preset's colour, else custom (Settings hex field).
  public init(rgb: UInt32) {
    let masked = rgb & Self.rgbMask
    self =
      AccentChoice.allCases.first { $0.rgb == masked }.map(Accent.preset) ?? .custom(rgb: masked)
  }

  /// `#RRGGBB` or `RRGGBB`, any case, surrounding spaces ignored; `#RGB` is short for `#RRGGBB`.
  /// Anything else → `nil`.
  public static func rgb(fromHex input: String) -> UInt32? {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    let digits =
      trimmed.hasPrefix(hexPrefix) ? trimmed.dropFirst(hexPrefix.count) : Substring(trimmed)
    guard digits.allSatisfy(\.isHexDigit) else { return nil }
    switch digits.count {
    case hexDigits: return UInt32(digits, radix: 16)
    case shortHexDigits: return UInt32(String(digits.flatMap { [$0, $0] }), radix: 16)
    default: return nil
    }
  }

  /// `#RRGGBB`, upper case.
  public var hex: String { Self.hexPrefix + String(format: "%06X", rgb) }

  /// 0xRRGGBB.
  public var rgb: UInt32 {
    switch self {
    case .preset(let choice): choice.rgb
    case .custom(let rgb): rgb & Self.rgbMask
    }
  }

  /// The custom colour, or `nil` for a preset.
  public var customRGB: UInt32? {
    if case .custom = self { rgb } else { nil }
  }
}

extension Accent: Codable {
  public init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    if let choice = AccentChoice(rawValue: raw) {
      self = .preset(choice)
      return
    }
    guard raw.hasPrefix(Self.hexPrefix) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "unknown accent: \(raw)"))
    }
    let hex = raw.dropFirst(Self.hexPrefix.count)
    guard hex.count == Self.hexDigits, hex.allSatisfy(\.isHexDigit),
      let rgb = UInt32(hex, radix: 16)
    else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "malformed colour: \(raw)"))
    }
    self = .custom(rgb: rgb)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .preset(let choice):
      try container.encode(choice.rawValue)
    case .custom:
      try container.encode(hex)
    }
  }
}
