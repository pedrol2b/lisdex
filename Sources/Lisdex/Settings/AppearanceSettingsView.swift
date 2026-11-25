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
/// the picked colour in its middle once one is chosen; the hex field at the end shows the current
/// colour and takes a typed or pasted one.
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
        ColorPanelPresenter.shared.show(initial: accent.rgb) { select(Accent(rgb: $0)) }
      }
      Spacer(minLength: 8)
      AccentHexField(accent: accent, select: select)
    }
  }
}

/// `#RRGGBB` of the current accent. A full six-digit hex applies as it's typed or pasted; `#RGB`
/// applies on Return. Invalid text turns red and changes nothing. A colour picked anywhere else
/// (swatch, colour panel) replaces the text and ends editing, so a half-typed value never comes
/// back; leaving the field just shows the current colour again.
private struct AccentHexField: View {
  private static let width: CGFloat = 86
  private static let fullDigits = 6

  let accent: Accent
  let select: (Accent) -> Void
  @State private var text = ""
  @FocusState private var isFocused: Bool

  private var parsed: UInt32? { Accent.rgb(fromHex: text) }

  var body: some View {
    TextField("Hex colour", text: $text)
      .labelsHidden()
      .textFieldStyle(.roundedBorder)
      .font(.body.monospaced())
      .foregroundStyle(parsed == nil ? Color.red : .primary)
      .frame(width: Self.width)
      .focused($isFocused)
      .onAppear { text = accent.hex }
      .onSubmit(commit)
      .onChange(of: text) { _, _ in applyIfComplete() }
      .onChange(of: isFocused) { _, focused in
        if !focused { text = accent.hex }
      }
      .onChange(of: accent) { _, new in
        guard new.rgb != parsed else { return }  // the field's own edit
        text = new.hex
        isFocused = false
      }
      .help("Type or paste a hex colour, like #F4C85B, then press Return.")
      .accessibilityLabel("Accent colour hex")
  }

  /// Applies while typing only once all six digits are in, so "#F4C" doesn't flash a colour.
  private func applyIfComplete() {
    guard let rgb = parsed, text.filter(\.isHexDigit).count == Self.fullDigits,
      rgb != accent.rgb
    else { return }
    select(Accent(rgb: rgb))
  }

  /// Return: applies a valid entry and shows it normalised; an invalid one is replaced by the
  /// current colour.
  private func commit() {
    guard let rgb = parsed else {
      text = accent.hex
      return
    }
    let picked = Accent(rgb: rgb)
    if picked != accent { select(picked) }
    text = picked.hex
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
