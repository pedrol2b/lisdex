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

extension EnvironmentValues {
  /// The user's accent colour (Settings → Appearance); set at the root of each window.
  @Entry var accent: Color = AccentChoice.default.color
}

extension View {
  /// Applies the accent to custom views (`\.accent`) and to system controls (`tint`).
  func accent(_ choice: AccentChoice) -> some View {
    environment(\.accent, choice.color).tint(choice.color)
  }
}
