import Foundation
import Testing

@testable import LisdexCore

/// Every icon the app can ask for has an SVG source and a PDF export in `assets/menubar/`
/// (ADR 0003, ADR 0025).
@Suite("Menu bar assets")
struct MenuBarAssetTests {
  private static let folder = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("assets/menubar")

  private static var badgedIcons: [MenuBarIcon] {
    MenuBarIconVariant.allCases.flatMap { variant in
      [false, true].flatMap { active in
        MenuBarBadge.allCases.map { MenuBarIcon(variant: variant, isActive: active, badge: $0) }
      }
    }
  }

  private static var allIcons: [MenuBarIcon] {
    let plain = MenuBarIconVariant.allCases.flatMap { variant in
      [false, true].map { MenuBarIcon(variant: variant, isActive: $0) }
    }
    return plain + badgedIcons
  }

  private static func svg(_ name: String) throws -> String {
    try String(contentsOf: folder.appendingPathComponent("\(name).svg"), encoding: .utf8)
  }

  /// The root element's `width` and `height` attributes.
  private static func canvas(_ svg: String) -> String {
    let root = svg.components(separatedBy: ">").first ?? ""
    let attributes = ["width", "height"].map { key in
      root.range(of: #"\#(key)="[^"]*""#, options: .regularExpression).map { String(root[$0]) }
        ?? ""
    }
    return attributes.joined(separator: " ")
  }

  @Test("every icon has an SVG source and a PDF export")
  func everyIconHasAnSVG() {
    for icon in Self.allIcons {
      for ext in ["svg", "pdf"] {
        let path = Self.folder.appendingPathComponent("\(icon.resourceName).\(ext)").path
        #expect(FileManager.default.fileExists(atPath: path), "missing \(icon.resourceName).\(ext)")
      }
    }
  }

  @Test("badged canvases match the plain icon, so the menu bar width never changes")
  func badgedCanvasesMatchUnbadged() throws {
    for icon in Self.badgedIcons {
      let plain = MenuBarIcon(variant: icon.variant, isActive: icon.isActive)
      #expect(
        Self.canvas(try Self.svg(icon.resourceName))
          == Self.canvas(try Self.svg(plain.resourceName)),
        "\(icon.resourceName)")
    }
  }

  @Test("badged artwork is black and alpha only (template image)")
  func badgedArtIsBlackAndAlpha() throws {
    let allowed: Set<String> = ["black", "#000", "#000000", "none"]
    for icon in Self.badgedIcons {
      let source = try Self.svg(icon.resourceName)
      let fills = source.matches(of: /fill="([^"]*)"/).map { String($0.1) }
      for fill in fills {
        #expect(allowed.contains(fill), "\(icon.resourceName) has fill \(fill)")
      }
    }
  }
}
