import AppKit
import LisdexCore
import SwiftUI

enum Theme {
  static let popoverWidth: CGFloat = 340
  static let tileCornerRadius: CGFloat = 8
}

/// 0xRRGGBB ↔ colours.
enum RGB {
  private static let channelMax = 255.0

  static func color(_ rgb: UInt32) -> Color { Color(nsColor: nsColor(rgb)) }

  static func nsColor(_ rgb: UInt32) -> NSColor {
    NSColor(
      srgbRed: Double((rgb >> 16) & 0xFF) / channelMax,
      green: Double((rgb >> 8) & 0xFF) / channelMax,
      blue: Double(rgb & 0xFF) / channelMax, alpha: 1)
  }

  /// The colour as 0xRRGGBB in sRGB; colours outside sRGB are clamped.
  static func value(of color: NSColor) -> UInt32 {
    let srgb = color.usingColorSpace(.sRGB) ?? .white
    func channel(_ component: CGFloat) -> UInt32 {
      UInt32((min(max(component, 0), 1) * channelMax).rounded())
    }
    return channel(srgb.redComponent) << 16 | channel(srgb.greenComponent) << 8
      | channel(srgb.blueComponent)
  }
}

extension AccentChoice {
  var color: Color { RGB.color(rgb) }
}

extension Accent {
  var color: Color { RGB.color(rgb) }
}

extension Color {
  /// Conic ring for the "custom colour" swatch, like the system colour well.
  static let colorWheel = AngularGradient(
    colors: [.red, .orange, .yellow, .green, .mint, .blue, .purple, .pink, .red],
    center: .center)
}

/// The user's accent colour (Settings → Appearance); set at the root of each window.
/// A hand-written key rather than `@Entry`: that macro's plugin ships only with Xcode, and Lisdex
/// must build with just the Command Line Tools (Homebrew, ADR 0005).
private struct AccentKey: EnvironmentKey {
  static let defaultValue: Color = AccentChoice.default.color
}

extension EnvironmentValues {
  var accent: Color {
    get { self[AccentKey.self] }
    set { self[AccentKey.self] = newValue }
  }
}

extension View {
  /// Applies the accent to custom views (`\.accent`) and to system controls (`tint`).
  func accent(_ accent: Accent) -> some View {
    environment(\.accent, accent.color).tint(accent.color)
  }
}
