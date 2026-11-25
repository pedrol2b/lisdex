import LisdexCore
import SwiftUI

/// Settings → Appearance: menu bar icon, mode badge (ADR 0025), accent colour.
struct AppearanceSettingsView: View {
  let model: AppModel

  var body: some View {
    Form {
      Section("Menu bar icon") {
        HStack(spacing: 12) {
          ForEach(MenuBarIconVariant.allCases, id: \.self) { variant in
            IconVariantCard(
              variant: variant, isSelected: model.settings.iconVariant == variant,
              select: { model.setIconVariant(variant) })
          }
        }
        Toggle(isOn: Bindable(model).showsModeBadgeSetting) {
          Text("Show the session mode on the icon")
          Text("Adds a small badge for indefinite, timed or scheduled sessions.")
        }
      }
      Section("Accent colour") {
        AccentPicker(accent: model.settings.accent, select: model.setAccent)
      }
    }
    .formStyle(.grouped)
  }
}

/// The preset swatches, then a colour-wheel swatch that opens the system colour panel and shows
/// the picked colour in its middle once one is chosen.
private struct AccentPicker: View {
  let accent: Accent
  let select: (Accent) -> Void

  var body: some View {
    HStack(spacing: 10) {
      ForEach(AccentChoice.allCases, id: \.self) { choice in
        AccentSwatch(name: choice.title, isSelected: accent == .preset(choice)) {
          Circle().fill(choice.color)
        } select: {
          select(.preset(choice))
        }
      }
      AccentSwatch(name: "Custom colour…", isSelected: accent.customRGB != nil) {
        ZStack {
          Circle().fill(Color.colorWheel)
          if let rgb = accent.customRGB {
            Circle().fill(RGB.color(rgb)).padding(5)
          }
        }
      } select: {
        ColorPanelPresenter.shared.show(initial: accent.rgb) { select(.custom(rgb: $0)) }
      }
    }
  }
}

private struct AccentSwatch<Face: View>: View {
  private static var diameter: CGFloat { 22 }

  let name: String
  let isSelected: Bool
  @ViewBuilder let face: () -> Face
  let select: () -> Void

  var body: some View {
    Button(action: select) {
      face()
        .frame(width: Self.diameter, height: Self.diameter)
        .overlay(
          Circle().stroke(Color.primary.opacity(isSelected ? 0.9 : 0), lineWidth: 2).padding(-3)
        )
        .contentShape(.circle)
    }
    .buttonStyle(.plain)
    .help(name)
    .accessibilityLabel(name)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(isSelected ? "Selected" : "")
  }
}

/// Both states of one icon variant, as they appear in the menu bar.
private struct IconVariantCard: View {
  @Environment(\.accent) private var accent
  let variant: MenuBarIconVariant
  let isSelected: Bool
  let select: () -> Void

  var body: some View {
    Button(action: select) {
      VStack(spacing: 8) {
        HStack(spacing: 14) {
          ForEach([false, true], id: \.self) { active in
            Image(
              nsImage: MenuBarImages.image(for: MenuBarIcon(variant: variant, isActive: active))
            )
            .renderingMode(.template)
          }
        }
        .frame(height: 28)
        Text(variant.title).font(.caption)
      }
      .frame(maxWidth: .infinity)
      .padding(10)
      .background(Color.primary.opacity(0.05), in: .rect(cornerRadius: 8))
      .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? accent : .clear, lineWidth: 2))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(variant.title) icon")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(isSelected ? "Selected" : "")
  }
}
