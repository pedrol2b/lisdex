import AppKit
import LisdexCore

/// Loads the pill / coffee-mug template images bundled by `scripts/build-app.sh`.
enum MenuBarImages {
  /// Glyphs are 18 pt tall (the menu bar maximum); the width follows each artwork's aspect ratio (ADR 0015).
  static let height: CGFloat = 18

  static func image(for icon: MenuBarIcon) -> NSImage {
    let image = bundled(icon.resourceName) ?? fallback(for: icon)
    let natural = image.size
    let aspect = natural.height > 0 ? natural.width / natural.height : 1
    image.size = NSSize(width: (height * aspect).rounded(), height: height)
    image.isTemplate = true
    image.accessibilityDescription = icon.accessibilityLabel
    return image
  }

  private static func bundled(_ name: String) -> NSImage? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "pdf") else {
      Log.app.error("Missing menu bar resource \(name, privacy: .public).pdf — using fallback")
      return nil
    }
    return NSImage(contentsOf: url)
  }

  /// Used when running the bare binary (`swift run`) outside the .app bundle.
  private static func fallback(for icon: MenuBarIcon) -> NSImage {
    let base = icon.variant == .mug ? "mug" : "capsule"
    let symbol = icon.isActive ? "\(base).fill" : base
    return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage()
  }
}
