import LisdexCore
import SwiftUI

enum Theme {
  static let popoverWidth: CGFloat = 340
  static let tileCornerRadius: CGFloat = 8
}

extension AccentChoice {
  var color: Color {
    Color(
      red: Double((rgb >> 16) & 0xFF) / 255,
      green: Double((rgb >> 8) & 0xFF) / 255,
      blue: Double(rgb & 0xFF) / 255)
  }
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
  func accent(_ choice: AccentChoice) -> some View {
    environment(\.accent, choice.color).tint(choice.color)
  }
}
