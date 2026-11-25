import LisdexCore
import SwiftUI

/// The three modes as radio rows (ADR 0027). Each row shows its current setting on the right;
/// only the selected mode shows its controls, right under its row.
struct ModeList<Controls: View>: View {
  @Environment(\.accent) private var accent
  let selection: KeepAwakeMode
  let summary: (KeepAwakeMode) -> String
  let select: (KeepAwakeMode) -> Void
  @ViewBuilder let controls: (KeepAwakeMode) -> Controls

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(KeepAwakeMode.allCases, id: \.self) { mode in
        row(mode)
        if mode == selection {
          controls(mode).padding(.vertical, 4)
        }
      }
    }
  }

  private func row(_ mode: KeepAwakeMode) -> some View {
    let isSelected = mode == selection
    return Button {
      select(mode)
    } label: {
      HStack(spacing: 10) {
        Circle()
          .strokeBorder(isSelected ? accent : Color.secondary, lineWidth: isSelected ? 4 : 1.5)
          .frame(width: 14, height: 14)
        Image(nsImage: ModeSymbols.image(for: mode))
          .renderingMode(.template)
          .foregroundStyle(isSelected ? accent : .secondary)
          .frame(width: 18)
          .accessibilityHidden(true)
        Text(mode.title).fontWeight(isSelected ? .semibold : .regular)
        Spacer(minLength: 8)
        Text(summary(mode))
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 6)
      .background(
        isSelected ? Color.primary.opacity(0.08) : .clear, in: .rect(cornerRadius: 7)
      )
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(mode.title)
    .accessibilityValue(summary(mode))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
