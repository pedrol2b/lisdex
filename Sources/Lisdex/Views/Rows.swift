import SwiftUI

/// Rounded tile at the start of a row (Low Cortisol style).
struct IconTile<Content: View>: View {
  static var size: CGFloat { 30 }

  @ViewBuilder let content: Content

  var body: some View {
    content
      .frame(width: Self.size, height: Self.size)
      .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: Theme.tileCornerRadius))
  }
}

/// Tile · title + detail · trailing switch.
struct ToggleRow<Tile: View>: View {
  let title: String
  let detail: String
  let isOn: Binding<Bool>
  @ViewBuilder let tile: Tile

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      IconTile { tile }
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.body.weight(.semibold))
        Text(detail).font(.subheadline).foregroundStyle(.secondary)
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      Toggle(title, isOn: isOn)
        .toggleStyle(.switch)
        .controlSize(.small)
        .labelsHidden()
        .accessibilityHint(detail)
    }
  }
}

/// Footer row: symbol · title · shortcut or chevron, with a hover highlight.
struct MenuActionRow: View {
  let symbol: String
  let title: String
  var shortcut: String?
  var showsChevron = false
  let action: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: symbol).frame(width: 24)
        Text(title)
        Spacer()
        if let shortcut { Text(shortcut).foregroundStyle(.secondary) }
        if showsChevron { Image(systemName: "chevron.right").foregroundStyle(.secondary) }
      }
      .padding(.vertical, 6)
      .padding(.horizontal, 6)
      .background(isHovered ? Color.primary.opacity(0.08) : .clear, in: .rect(cornerRadius: 6))
      .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}
