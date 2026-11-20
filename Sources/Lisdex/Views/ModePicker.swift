import LisdexCore
import SwiftUI

/// Three-way segmented control: symbol above title, selected segment raised.
struct ModePicker: View {
  @Environment(\.accent) private var accent
  let selection: KeepAwakeMode
  let select: (KeepAwakeMode) -> Void

  var body: some View {
    HStack(spacing: 2) {
      ForEach(KeepAwakeMode.allCases, id: \.self) { mode in
        segment(mode)
      }
    }
    .padding(3)
    .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
  }

  private func segment(_ mode: KeepAwakeMode) -> some View {
    let isSelected = mode == selection
    return Button {
      select(mode)
    } label: {
      VStack(spacing: 4) {
        Image(systemName: mode.symbolName)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(isSelected ? accent : .secondary)
        Text(mode.title)
          .font(.caption.weight(isSelected ? .semibold : .regular))
          .foregroundStyle(isSelected ? .primary : .secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 7)
      .background(
        isSelected ? Color.primary.opacity(0.12) : .clear, in: .rect(cornerRadius: 8)
      )
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(mode.title)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(isSelected ? "Selected" : "")
  }
}
